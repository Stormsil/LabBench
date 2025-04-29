(*==============================================================================
    Название:    GVL_DiagSystem_Extended
    Автор:       
    Дата:        2025-04-30
    Версия:      1.0
    
    Описание:    Глобальные переменные расширенной диагностической системы
==============================================================================*)
VAR_GLOBAL CONSTANT
    (* Количество ошибок и сценариев в системе *)
    MAX_ERRORS: UINT := 50;                  (* Максимальное количество ошибок *)
    MAX_SCENARIOS: UINT := 25;               (* Максимальное количество сценариев *)
    
    (* Идентификаторы систем *)
    SYSTEM_ID: WORD := 16#0100;              (* Общесистемные ошибки *)
    MEASUREMENT_ID: WORD := 16#0200;         (* Ошибки системы измерения *)
    EQUIPMENT_ID: WORD := 16#0300;           (* Ошибки оборудования *)
    COMMUNICATION_ID: WORD := 16#0400;       (* Ошибки связи *)
    
    (* Идентификаторы подсистем измерения *)
    PRESSURE_SENSORS_ID: WORD := 16#0210;    (* Датчики давления *)
    LEVEL_SENSORS_ID: WORD := 16#0220;       (* Датчики уровня *)
    FLOW_SENSORS_ID: WORD := 16#0230;        (* Расходомеры *)
    TEMP_SENSORS_ID: WORD := 16#0240;        (* Датчики температуры *)
    
    (* Идентификаторы оборудования *)
    PROP_VALVE_ID: WORD := 16#0310;          (* Пропорциональный клапан *)
    EM_VALVE_ID: WORD := 16#0320;            (* Электромагнитный клапан *)
    PUMP1_ID: WORD := 16#0330;               (* Насос 1 *)
    PUMP2_ID: WORD := 16#0340;               (* Насос 2 *)
    HEATER_ID: WORD := 16#0350;              (* Нагреватель (ТЭН) *)
    
    (* Идентификаторы связи *)
    SCADA_COMM_ID: WORD := 16#0410;          (* Связь со SCADA *)
    MODBUS_COMM_ID: WORD := 16#0420;         (* Связь по Modbus (ТРМ10) *)
END_VAR

VAR_GLOBAL
    (* Массивы ошибок и сценариев *)
    gaBlockingErrors: ARRAY[1..MAX_ERRORS] OF ST_BlockingError;     (* Массив ошибок *)
    gaDiagScenarios: ARRAY[1..MAX_SCENARIOS] OF ST_DiagScenario;    (* Массив сценариев *)
    
    (* Состояние системы *)
    geSystemState: E_SystemState;            (* Текущее состояние системы *)
    gxSystemBlockingRequired: BOOL;          (* Требуется блокировка системы *)
    gxSystemShutdownRequired: BOOL;          (* Требуется останов системы *)
    gxSystemResetRequired: BOOL;             (* Требуется сброс системы *)
    gstShutdownSequence: ST_ShutdownSequence;(* Последовательность останова *)
    
    (* Агрегированная информация о сценариях *)
    gxAnyScenarioActive: BOOL;               (* Любой сценарий активен *)
    gxAnyScenarioBlockingRequired: BOOL;     (* Любой сценарий требует блокировки *)
    gxAnyScenarioShutdownRequired: BOOL;     (* Любой сценарий требует останова *)
    gdwActiveScenariosMask: DWORD;           (* Битовая маска активных сценариев *)
    giLastActiveScenarioIndex: UINT;         (* Индекс последнего активного сценария *)
    
    (* Агрегированные состояния *)
    gxAnyError: BOOL;                        (* Флаг наличия любых ошибок *)
    gxSystemBlocking: BOOL;                  (* Флаг полной блокировки системы *)
    gdwActiveErrorMask: DWORD;               (* Битовая маска активных ошибок *)
    
    (* Блокировки устройств *)
    gxPropValveBlocking: BOOL;               (* Блокировка пропорционального клапана *)
    gxEMValveBlocking: BOOL;                 (* Блокировка электромагнитного клапана *)
    gxPump1Blocking: BOOL;                   (* Блокировка насоса 1 *)
    gxPump2Blocking: BOOL;                   (* Блокировка насоса 2 *)
    gxHeaterBlocking: BOOL;                  (* Блокировка нагревателя *)
    
    (* Управление лампой *)
    geLampMode: E_LampBlinkMode;             (* Режим работы сигнальной лампы *)
    gxLampState: BOOL;                       (* Текущее состояние лампы *)
    
    (* Команды управления *)
    gxResetAll: BOOL;                        (* Сброс всех ошибок *)
    gxResetMeasurement: BOOL;                (* Сброс ошибок измерительной системы *)
    gxResetPropValve: BOOL;                  (* Сброс ошибок пропорционального клапана *)
    gxResetEMValve: BOOL;                    (* Сброс ошибок электромагнитного клапана *)
    gxResetPump1: BOOL;                      (* Сброс ошибок насоса 1 *)
    gxResetPump2: BOOL;                      (* Сброс ошибок насоса 2 *)
    gxResetHeater: BOOL;                     (* Сброс ошибок нагревателя *)
    gxStartNormalShutdown: BOOL;             (* Запуск нормального останова *)
    gxStartEmergencyShutdown: BOOL;          (* Запуск аварийного останова *)
END_VAR