(*==============================================================================
    Название:    FB_SystemManager
    Автор:       
    Дата:        2025-04-30
    Версия:      1.0
    
    Описание:    Функциональный блок управления состоянием системы
                 Координирует работу всей диагностической системы,
                 обрабатывает ошибки и сценарии, управляет блокировками
                 и последовательностью останова
==============================================================================*)
FUNCTION_BLOCK FB_SystemManager
VAR_INPUT
    (* Состояние системы *)
    bSystemInitialized: BOOL;         (* Система инициализирована *)
    bAnyError: BOOL;                  (* Флаг наличия ошибок *)
    bAnyScenarioActive: BOOL;         (* Флаг наличия активных сценариев *)
    bAnyBlockingRequired: BOOL;       (* Требуется блокировка *)
    bAnyShutdownRequired: BOOL;       (* Требуется останов *)
    
    (* Состояние последовательности останова *)
    bShutdownInProgress: BOOL;        (* Последовательность останова активна *)
    bShutdownCompleted: BOOL;         (* Останов завершен *)
    bShutdownError: BOOL;             (* Ошибка в процессе останова *)
    
    (* Команды управления *)
    bResetSystem: BOOL;               (* Сброс системы *)
    bStartNormalShutdown: BOOL;       (* Запуск нормального останова *)
    bStartEmergencyShutdown: BOOL;    (* Запуск аварийного останова *)
END_VAR

VAR_OUTPUT
    eSystemState: E_SystemState;      (* Текущее состояние системы *)
    bSystemBlockingRequired: BOOL;    (* Требуется блокировка системы *)
    bSystemShutdownRequired: BOOL;    (* Требуется останов системы *)
    bSystemResetRequired: BOOL;       (* Требуется сброс системы *)
END_VAR

VAR
    (* Триггеры *)
    rtResetSystem: R_TRIG;            (* Триггер сброса системы *)
    rtStartNormalShutdown: R_TRIG;    (* Триггер запуска нормального останова *)
    rtStartEmergencyShutdown: R_TRIG; (* Триггер запуска аварийного останова *)
    
    (* Текущее состояние *)
    ePrevSystemState: E_SystemState;  (* Предыдущее состояние системы *)
    tStateChangeTime: TON;            (* Таймер для измерения времени в состоянии *)
END_VAR

(* ======================================================================== *)
(* Основная логика функционального блока                                    *)
(* ======================================================================== *)

(* Обработка триггеров *)
rtResetSystem(CLK := bResetSystem);
rtStartNormalShutdown(CLK := bStartNormalShutdown);
rtStartEmergencyShutdown(CLK := bStartEmergencyShutdown);

(* Сохранение предыдущего состояния *)
IF eSystemState <> ePrevSystemState THEN
    ePrevSystemState := eSystemState;
    tStateChangeTime(IN := FALSE);
END_IF;

(* Запуск таймера состояния *)
tStateChangeTime(IN := TRUE, PT := T#24H); (* 24 часа - фактически бесконечность для таймера *)

(* Определение текущего состояния системы *)
IF NOT bSystemInitialized THEN
    (* Система не инициализирована *)
    eSystemState := SYSTEM_INIT;
    bSystemBlockingRequired := FALSE;
    bSystemShutdownRequired := FALSE;
    bSystemResetRequired := FALSE;
    
ELSIF bShutdownInProgress THEN
    (* Выполняется последовательность останова *)
    IF bAnyError OR bAnyBlockingRequired OR bAnyShutdownRequired THEN
        (* Аварийный останов *)
        eSystemState := SYSTEM_ERROR_SHUTDOWN;
    ELSE
        (* Нормальный останов *)
        eSystemState := SYSTEM_SHUTDOWN;
    END_IF;
    
    bSystemBlockingRequired := TRUE;
    bSystemShutdownRequired := TRUE;
    bSystemResetRequired := FALSE;
    
ELSIF bShutdownCompleted THEN
    (* Останов завершен *)
    IF bShutdownError OR bAnyError OR bAnyBlockingRequired THEN
        (* Останов с ошибкой *)
        eSystemState := SYSTEM_ERROR;
        bSystemBlockingRequired := TRUE;
        bSystemShutdownRequired := FALSE;
        bSystemResetRequired := TRUE;
    ELSE
        (* Нормальный останов *)
        eSystemState := SYSTEM_READY;
        bSystemBlockingRequired := FALSE;
        bSystemShutdownRequired := FALSE;
        bSystemResetRequired := FALSE;
    END_IF;
    
ELSIF bAnyError OR bAnyBlockingRequired THEN
    (* Ошибка в системе *)
    eSystemState := SYSTEM_ERROR;
    bSystemBlockingRequired := TRUE;
    
    (* Требуется ли останов *)
    bSystemShutdownRequired := bAnyShutdownRequired;
    bSystemResetRequired := TRUE;
    
ELSIF bAnyScenarioActive THEN
    (* Активен сценарий, но без блокировки *)
    eSystemState := SYSTEM_RUNNING;
    bSystemBlockingRequired := FALSE;
    bSystemShutdownRequired := bAnyShutdownRequired;
    bSystemResetRequired := FALSE;
    
ELSE
    (* Нормальная работа *)
    eSystemState := SYSTEM_RUNNING;
    bSystemBlockingRequired := FALSE;
    bSystemShutdownRequired := FALSE;
    bSystemResetRequired := FALSE;
END_IF;

(* Обработка команд *)
IF rtResetSystem.Q THEN
    (* Сброс системы *)
    IF eSystemState = SYSTEM_ERROR AND NOT bShutdownInProgress THEN
        (* Можно выполнить сброс только в состоянии ошибки и не во время останова *)
        eSystemState := SYSTEM_READY;
        bSystemBlockingRequired := FALSE;
        bSystemShutdownRequired := FALSE;
        bSystemResetRequired := FALSE;
    END_IF;
END_IF;

(* Команды запуска останова имеют приоритет *)
IF rtStartEmergencyShutdown.Q OR rtStartNormalShutdown.Q THEN
    (* Запуск останова *)
    IF rtStartEmergencyShutdown.Q THEN
        eSystemState := SYSTEM_ERROR_SHUTDOWN;
    ELSE
        eSystemState := SYSTEM_SHUTDOWN;
    END_IF;
    
    bSystemBlockingRequired := TRUE;
    bSystemShutdownRequired := TRUE;
    bSystemResetRequired := FALSE;
END_IF;