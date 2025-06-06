(*==============================================================================
    Название:    ST_PropValveCommands
    Автор:       Редько А.
    Дата:        2025-04-27
    Версия:      1.0
    
    Описание:    Структура команд управления пропорциональным краном
==============================================================================*)
TYPE ST_PropValveCommands :
STRUCT
    (* Команды управления *)
    eMode: E_EquipmentMode := MANUAL; (* Режим работы *)
    rPositionSetpoint: REAL := 0.0;    (* Задание положения (0-100%) *)
    bReset: BOOL := FALSE;             (* Сброс ошибок *)
    bExtEmergencyStop: BOOL := FALSE;  (* Внешняя команда аварийного останова *)
END_STRUCT
END_TYPE