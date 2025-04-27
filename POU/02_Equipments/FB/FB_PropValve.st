(*==============================================================================
    Название:    FB_PropValve
    Автор:       Редько А.
    Дата:        2025-04-27
    Версия:      1.1
    
    Описание:    Функциональный блок для управления пропорциональным шаровым
                 краном с аналоговым управлением (4-20мА) и обратной связью
                 по положению (4-20мА).
==============================================================================*)
FUNCTION_BLOCK FB_PropValve
VAR_IN_OUT
    stValve: ST_PropValve;         (* Структура данных крана *)
END_VAR

VAR_INPUT
    rFeedbackSignal: REAL;         (* Сигнал обратной связи (уже масштабирован 0-100%) *)
    bEnable: BOOL := TRUE;         (* Разрешение работы *)
END_VAR

VAR_OUTPUT
    rControlSignal: REAL;          (* Управляющий сигнал на клапан (0-100%) *)
END_VAR

VAR
    (* Переменные диагностики движения *)
    rPrevPosition: REAL;          (* Предыдущее положение *)
    rEffectiveSetpoint: REAL;     (* Эффективная уставка с учетом режима работы *)
    rPrevSetpoint: REAL;          (* Предыдущая уставка для обнаружения изменений *)
    
    (* Таймеры *)
    tonPositionTimeout: TON;      (* Таймер достижения позиции *)
    tonStuckDetection: TON;       (* Таймер обнаружения заклинивания *)
    
    (* Внутренние переменные *)
    rLastValidPosition: REAL;     (* Последнее действительное положение *)
    bIsInitialized: BOOL := FALSE;(* Флаг инициализации *)
    bPositionReached: BOOL;       (* Флаг достижения позиции *)
    
    (* Предыдущие значения для обнаружения изменений *)
    eLastMode: E_EquipmentMode;   (* Предыдущий режим работы *)
    bDirectionOpening: BOOL;      (* Направление движения (TRUE - открытие) *)
    bPrevDirectionOpening: BOOL;  (* Предыдущее направление движения *)
    iDirectionChanges: INT;       (* Счетчик изменений направления для REGULATING *)
    rPositionDelta: REAL;         (* Изменение положения за цикл *)
    bStableRegulation: BOOL;      (* Флаг стабильного регулирования *)
    tStableRegulationTime: TON;   (* Таймер стабильного регулирования *)
    byAIStatus: BYTE;             (* Статус аналогового входа *)
END_VAR

VAR CONSTANT
    (* Константы для кодов ошибок *)
    ERR_NONE: WORD := 16#0000;                (* Нет ошибок *)
    ERR_CONFIG: WORD := 16#0001;              (* Ошибка конфигурации *)
    ERR_NO_FEEDBACK: WORD := 16#0002;         (* Отсутствие сигнала обратной связи *)
    ERR_FEEDBACK_RANGE: WORD := 16#0004;      (* Сигнал обратной связи вне диапазона *)
    ERR_TIMEOUT: WORD := 16#0010;             (* Таймаут достижения позиции *)
    ERR_STUCK: WORD := 16#0020;               (* Клапан заклинило/поломка *)
    ERR_WIRE_BREAK: WORD := 16#0040;          (* Обрыв линии *)
    
    (* Константы статусов аналогового входа (старший байт) *)
    AI_STATUS_OK: BYTE := 16#00;              (* Ошибок нет *)
    AI_STATUS_INVALID: BYTE := 16#F1;         (* Результаты измерения заведомо неверны *)
    AI_STATUS_NOT_READY: BYTE := 16#F6;       (* Результаты измерения не готовы *)
    AI_STATUS_ABOVE_RANGE: BYTE := 16#FA;     (* Сигнал на входе больше возможного *)
    AI_STATUS_BELOW_RANGE: BYTE := 16#FB;     (* Сигнал на входе меньше возможного *)
    AI_STATUS_CURRENT_OVERLOAD: BYTE := 16#FC;(* Перегрузка в канале измерения тока *)
    AI_STATUS_WIRE_BREAK: BYTE := 16#FD;      (* Обрыв датчика в канале измерения напряжения *)
END_VAR

(* ======================================================================== *)
(* Основная логика функционального блока                                    *)
(* ======================================================================== *)

(* Инициализация при первом запуске *)
IF NOT bIsInitialized THEN
    rPrevPosition := 0.0;
    rLastValidPosition := 0.0;
    rPrevSetpoint := 0.0;
    stValve.eMode := stValve.stCommands.eMode;
    stValve.eState := CLOSED;
    stValve.wErrorCode := ERR_NONE;
    stValve.bValid := FALSE;
    eLastMode := stValve.eMode;
    iDirectionChanges := 0;
    bIsInitialized := TRUE;
END_IF;

(* Проверка параметров конфигурации *)
IF stValve.stSettings.rCloseThreshold < 0.0 OR 
   stValve.stSettings.rCloseThreshold >= stValve.stSettings.rOpenThreshold OR 
   stValve.stSettings.rOpenThreshold > 100.0 OR 
   stValve.stSettings.rDeadband < 0.0 OR 
   stValve.stSettings.rDeadband > 10.0 OR
   stValve.stSettings.rSafePosition < 0.0 OR 
   stValve.stSettings.rSafePosition > 100.0 OR
   stValve.stSettings.rRegulatingThreshold <= 0.0 OR 
   stValve.stSettings.rRegulatingThreshold > 10.0 THEN
    
    stValve.wErrorCode := stValve.wErrorCode OR ERR_CONFIG;
END_IF;

(* Блок выключен - устанавливаем безопасное положение *)
IF NOT bEnable THEN
    stValve.eMode := DISABLED;
    rEffectiveSetpoint := stValve.stSettings.rSafePosition;
    stValve.rTargetPosition := stValve.stSettings.rSafePosition;
    stValve.bValid := FALSE;
ELSE
    (* Блок включен - обработка режимов работы *)
    
    (* Проверка внешней команды аварийного останова *)
    IF stValve.stCommands.bExtEmergencyStop AND stValve.stCommands.eMode <> E_STOP THEN
        stValve.stCommands.eMode := E_STOP;
    END_IF;
    
    (* Переключение в режим E_STOP при наличии ошибок *)
    IF stValve.wErrorCode <> ERR_NONE AND stValve.stSettings.bSwitchToE_StopOnError AND 
       stValve.stCommands.eMode <> E_STOP THEN
        stValve.stCommands.eMode := E_STOP;
    END_IF;
    
    (* Обработка команды сброса ошибок *)
    IF stValve.stCommands.bReset THEN
        stValve.wErrorCode := ERR_NONE;
        iDirectionChanges := 0;
        tonPositionTimeout(IN := FALSE);
        tonStuckDetection(IN := FALSE);
        stValve.stCommands.bReset := FALSE;
    END_IF;
    
    (* Обнаружение изменения режима работы *)
    IF stValve.stCommands.eMode <> eLastMode THEN
        (* При выходе из режима AUTO, сбросить счетчик изменений направления *)
        IF eLastMode = AUTO THEN
            iDirectionChanges := 0;
        END_IF;
        
        eLastMode := stValve.stCommands.eMode;
    END_IF;
    
    (* Применение режима работы *)
    stValve.eMode := stValve.stCommands.eMode;
    
    CASE stValve.eMode OF
        AUTO:
            (* В автоматическом режиме используем внешнюю уставку *)
            rEffectiveSetpoint := LIMIT(0.0, stValve.stCommands.rPositionSetpoint, 100.0);
            stValve.rTargetPosition := rEffectiveSetpoint;
            
        MANUAL:
            (* В ручном режиме используем прямое задание от оператора *)
            rEffectiveSetpoint := LIMIT(0.0, stValve.stCommands.rPositionSetpoint, 100.0);
            stValve.rTargetPosition := rEffectiveSetpoint;
            
        DISABLED:
            (* В режиме отключения переводим в безопасное положение *)
            rEffectiveSetpoint := stValve.stSettings.rSafePosition;
            stValve.rTargetPosition := stValve.stSettings.rSafePosition;
            
        E_STOP:
            (* При аварийном останове безусловно переводим в безопасное положение *)
            rEffectiveSetpoint := stValve.stSettings.rSafePosition;
            stValve.rTargetPosition := stValve.stSettings.rSafePosition;
    END_CASE;
    
    (* Обнаружение значительного изменения уставки *)
    IF ABS(rEffectiveSetpoint - rPrevSetpoint) > stValve.stSettings.rDeadband * 2.0 THEN
        (* Сброс счетчика изменений направления при значительном изменении уставки *)
        iDirectionChanges := 0;
    END_IF;
    
    (* Сохранение текущей уставки для следующего цикла *)
    rPrevSetpoint := rEffectiveSetpoint;
END_IF;

(* ======================================================================== *)
(* Обработка сигнала обратной связи                                         *)
(* ======================================================================== *)

(* Получение старшего байта для анализа статуса аналогового входа *)
byAIStatus := DWORD_TO_BYTE(SHR(REAL_TO_DWORD(rFeedbackSignal) AND 16#FF000000, 24));

(* Проверка статуса аналогового входа *)
CASE byAIStatus OF
    AI_STATUS_OK:
        (* Нормальные данные *)
        (* Учитываем, что сигнал уже масштабирован в конфигурации 0-100% *)
        stValve.rActualPosition := LIMIT(0.0, rFeedbackSignal, 100.0);
        rLastValidPosition := stValve.rActualPosition;
        stValve.bValid := TRUE;
        
    AI_STATUS_ABOVE_RANGE:
        (* Превышение диапазона *)
        stValve.wErrorCode := stValve.wErrorCode OR ERR_FEEDBACK_RANGE;
        stValve.rActualPosition := rLastValidPosition;
        stValve.bValid := FALSE;
        
    AI_STATUS_BELOW_RANGE:
        (* Значение ниже диапазона *)
        stValve.wErrorCode := stValve.wErrorCode OR ERR_FEEDBACK_RANGE;
        stValve.rActualPosition := rLastValidPosition;
        stValve.bValid := FALSE;
        
    AI_STATUS_WIRE_BREAK:
        (* Обрыв датчика *)
        stValve.wErrorCode := stValve.wErrorCode OR ERR_WIRE_BREAK;
        stValve.rActualPosition := rLastValidPosition;
        stValve.bValid := FALSE;
        
    AI_STATUS_NOT_READY:
        (* Данные аналогового входа не готовы *)
        stValve.wErrorCode := stValve.wErrorCode OR ERR_NO_FEEDBACK;
        stValve.rActualPosition := rLastValidPosition;
        stValve.bValid := FALSE;
        
    AI_STATUS_CURRENT_OVERLOAD:
        (* Перегрузка в канале измерения тока *)
        stValve.wErrorCode := stValve.wErrorCode OR ERR_NO_FEEDBACK;
        stValve.rActualPosition := rLastValidPosition;
        stValve.bValid := FALSE;
        
    AI_STATUS_INVALID:
        (* Недостоверные данные аналогового входа *)
        stValve.wErrorCode := stValve.wErrorCode OR ERR_NO_FEEDBACK;
        stValve.rActualPosition := rLastValidPosition;
        stValve.bValid := FALSE;
        
    ELSE
        (* Прочие ошибки *)
        stValve.wErrorCode := stValve.wErrorCode OR ERR_NO_FEEDBACK;
        stValve.rActualPosition := rLastValidPosition;
        stValve.bValid := FALSE;
END_CASE;

(* ======================================================================== *)
(* Определение направления движения и изменений                             *)
(* ======================================================================== *)

(* Расчет изменения положения *)
rPositionDelta := stValve.rActualPosition - rPrevPosition;

(* Определение флагов движения с учетом зоны нечувствительности *)
IF ABS(rPositionDelta) > stValve.stSettings.rDeadband / 2.0 THEN
    (* Определение направления движения *)
    bDirectionOpening := rPositionDelta > 0.0;
    stValve.bMoving := TRUE;
    
    (* Обнаружение изменения направления для состояния REGULATING *)
    IF stValve.eMode = AUTO AND bDirectionOpening <> bPrevDirectionOpening AND 
       ABS(stValve.rActualPosition - rEffectiveSetpoint) < stValve.stSettings.rRegulatingThreshold * 2.0 THEN
        iDirectionChanges := iDirectionChanges + 1;
    END_IF;
    
    (* Сохранение текущего направления *)
    bPrevDirectionOpening := bDirectionOpening;
ELSE
    (* Нет движения или изменение в пределах зоны нечувствительности *)
    stValve.bMoving := FALSE;
END_IF;

(* ======================================================================== *)
(* Определение достижения позиции                                           *)
(* ======================================================================== *)

(* Определение выполнения команды позиционирования *)
IF ABS(stValve.rActualPosition - rEffectiveSetpoint) <= stValve.stSettings.rDeadband THEN
    bPositionReached := TRUE;
    tonPositionTimeout(IN := FALSE);
    
    (* Сброс счетчика изменений направления при достижении уставки и прекращении движения *)
    IF NOT stValve.bMoving AND stValve.eMode <> AUTO THEN
        iDirectionChanges := 0;
    END_IF;
ELSE
    bPositionReached := FALSE;
    
    (* Запуск таймера контроля достижения позиции *)
    tonPositionTimeout(IN := TRUE, PT := stValve.stSettings.tPositionTimeout);
    
    (* Проверка на таймаут достижения позиции *)
    IF tonPositionTimeout.Q THEN
        stValve.wErrorCode := stValve.wErrorCode OR ERR_TIMEOUT;
    END_IF;
END_IF;

(* Проверка на заклинивание/поломку *)
IF NOT bPositionReached AND NOT stValve.bMoving AND stValve.bValid AND
   ABS(stValve.rActualPosition - rEffectiveSetpoint) > stValve.stSettings.rDeadband THEN
    tonStuckDetection(IN := TRUE, PT := stValve.stSettings.tStuckTimeout);
    
    IF tonStuckDetection.Q THEN
        stValve.wErrorCode := stValve.wErrorCode OR ERR_STUCK;
    END_IF;
ELSE
    tonStuckDetection(IN := FALSE);
END_IF;

(* ======================================================================== *)
(* Определение состояния крана                                              *)
(* ======================================================================== *)

(* Сброс состояния ошибки при устранении причин *)
IF stValve.wErrorCode = ERR_NONE AND stValve.eState = ERROR THEN
    IF stValve.rActualPosition <= stValve.stSettings.rCloseThreshold THEN
        stValve.eState := CLOSED;
    ELSIF stValve.rActualPosition >= stValve.stSettings.rOpenThreshold THEN
        stValve.eState := OPEN;
    ELSE
        stValve.eState := INTERMEDIATE;
    END_IF;
END_IF;

(* Определение состояния крана на основе текущего положения и движения *)
IF stValve.wErrorCode <> ERR_NONE THEN
    (* Наличие ошибок *)
    stValve.eState := ERROR;
    
ELSIF stValve.bMoving THEN
    (* Кран в движении *)
    IF stValve.eMode = AUTO AND 
       ABS(rPositionDelta) < stValve.stSettings.rRegulatingThreshold AND 
       ABS(stValve.rActualPosition - rEffectiveSetpoint) < stValve.stSettings.rRegulatingThreshold * 2.0 AND
       iDirectionChanges >= 3 THEN
        (* В автоматическом режиме при небольших колебаниях вокруг уставки *)
        stValve.eState := REGULATING;
        
    ELSIF bDirectionOpening THEN
        stValve.eState := OPENING;
        
    ELSE
        stValve.eState := CLOSING;
    END_IF;
    
ELSE
    (* Кран неподвижен *)
    IF stValve.rActualPosition <= stValve.stSettings.rCloseThreshold THEN
        stValve.eState := CLOSED;
        
    ELSIF stValve.rActualPosition >= stValve.stSettings.rOpenThreshold THEN
        stValve.eState := OPEN;
        
    ELSE
        stValve.eState := INTERMEDIATE;
    END_IF;
    
    (* Сброс счетчика изменений направления, если кран неподвижен *)
    IF stValve.eMode <> AUTO THEN
        iDirectionChanges := 0;
    END_IF;
END_IF;

(* ======================================================================== *)
(* Формирование управляющего сигнала                                        *)
(* ======================================================================== *)

(* При наличии ошибок переводим в безопасное положение *)
IF stValve.eState = ERROR AND (stValve.wErrorCode AND (ERR_NO_FEEDBACK OR ERR_WIRE_BREAK)) > 0 THEN
    rControlSignal := stValve.stSettings.rSafePosition;
ELSE
    (* Нормальное формирование управляющего сигнала *)
    rControlSignal := rEffectiveSetpoint;
END_IF;

(* Сохранение текущего положения для следующего цикла *)
rPrevPosition := stValve.rActualPosition;