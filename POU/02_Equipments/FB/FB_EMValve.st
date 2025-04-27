(*==============================================================================
    Название:    FB_EMValve
    Автор:       Редько А.
    Дата:        2025-04-28
    Версия:      1.1
    
    Описание:    Функциональный блок для управления электромагнитным клапаном
                 с учетом времени работы соленоида и поддержкой работы
                 в автоматическом режиме от внешнего регулятора.
                 
                 Клапан является нормально закрытым (НЗ), это означает,
                 что для открытия требуется подать напряжение на соленоид.
==============================================================================*)
FUNCTION_BLOCK FB_EMValve
VAR_IN_OUT
    stValve: ST_EMValve;         (* Структура данных клапана *)
END_VAR

VAR_INPUT
    bManualOpenCommand: BOOL;    (* Команда открытия в ручном режиме *)
    bAutoOpenCommand: BOOL;      (* Команда открытия от внешнего регулятора *)
    bEmergencyStop: BOOL;        (* Сигнал аварийного останова *)
    eMode: E_EquipmentMode;      (* Режим работы *)
    bEnable: BOOL := TRUE;       (* Разрешение работы *)
END_VAR

VAR_OUTPUT
    bOutputSignal: BOOL;         (* Выходной сигнал на соленоид *)
END_VAR

VAR
    (* Таймеры *)
    tonOperationTimer: TON;      (* Таймер работы соленоида *)
    tonInactiveTimer: TON;       (* Таймер простоя (для сброса счетчика непрерывной работы) *)

    (* Внутренние переменные *)
    bInitialized: BOOL := FALSE; (* Флаг инициализации *)
    bPrevOpenState: BOOL;        (* Предыдущее состояние открытия *)
END_VAR

(* ======================================================================== *)
(* Основная логика функционального блока                                    *)
(* ======================================================================== *)

(* Инициализация при первом запуске *)
IF NOT bInitialized THEN
    stValve.bIsOpen := FALSE;
    stValve.eMode := MANUAL;
    stValve.eState := EM_CLOSED;
    stValve.tOperationTime := T#0S;
    stValve.tContinuousOpTime := T#0S;
    IF stValve.tWarningThreshold = T#0S THEN
        stValve.tWarningThreshold := T#15M; (* Значение по умолчанию *)
    END_IF;
    bInitialized := TRUE;
END_IF;

(* Обработка команды сброса счетчика *)
IF stValve.bReset THEN
    stValve.tOperationTime := T#0S;
    stValve.tContinuousOpTime := T#0S;
    tonOperationTimer(IN := FALSE);
    stValve.bReset := FALSE;
END_IF;

(* Определение режима работы из входа *)
IF NOT bEnable THEN
    stValve.eMode := DISABLED;
ELSIF bEmergencyStop THEN
    stValve.eMode := E_STOP;
ELSE
    stValve.eMode := eMode;
END_IF;

(* Определение команды открытия на основе режима *)
CASE stValve.eMode OF
    AUTO:
        (* В автоматическом режиме команда открытия от внешнего регулятора *)
        stValve.bOpen := bAutoOpenCommand;
        
    MANUAL:
        (* В ручном режиме используем команду от оператора *)
        stValve.bOpen := bManualOpenCommand;
        
    DISABLED, E_STOP:
        (* В режиме отключения или аварийного останова - закрыто *)
        stValve.bOpen := FALSE;
END_CASE;

(* Установка выходного сигнала и статуса *)
bOutputSignal := stValve.bOpen;
stValve.bIsOpen := stValve.bOpen;

(* Определение состояния клапана *)
IF stValve.bIsOpen THEN
    IF stValve.tContinuousOpTime >= stValve.tWarningThreshold THEN
        stValve.eState := EM_LONG_OPERATION;
    ELSE
        stValve.eState := EM_OPEN;
    END_IF;
ELSE
    stValve.eState := EM_CLOSED;
END_IF;

(* ======================================================================== *)
(* Обработка таймеров и времени работы                                      *)
(* ======================================================================== *)

(* Таймер непрерывной работы *)
IF stValve.bIsOpen THEN
    (* Соленоид активен - запускаем таймер работы *)
    tonOperationTimer(IN := TRUE, PT := T#24H); (* Большое значение для непрерывного счета *)
    tonInactiveTimer(IN := FALSE);
    
    (* Обновляем время непрерывной работы *)
    stValve.tContinuousOpTime := tonOperationTimer.ET;
ELSE
    (* Соленоид не активен - останавливаем таймер работы *)
    tonOperationTimer(IN := FALSE);
    
    (* Запускаем таймер неактивности *)
    tonInactiveTimer(IN := TRUE, PT := T#1M);
    
    (* Если клапан закрыт больше минуты - сбрасываем счетчик непрерывной работы *)
    IF tonInactiveTimer.Q THEN
        stValve.tContinuousOpTime := T#0S;
    END_IF;
END_IF;

(* Обновление общего времени работы *)
IF stValve.bIsOpen AND NOT bPrevOpenState THEN
    (* Клапан только что открылся - сохраняем текущее общее время работы *)
    bPrevOpenState := TRUE;
ELSIF NOT stValve.bIsOpen AND bPrevOpenState THEN
    (* Клапан только что закрылся - добавляем время последней операции *)
    stValve.tOperationTime := stValve.tOperationTime + tonOperationTimer.ET;
    bPrevOpenState := FALSE;
END_IF;