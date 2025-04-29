(*==============================================================================
    Название:    GVL_SCADA_DiagSystem
    Автор:       
    Дата:        2025-04-28
    Версия:      1.0
    
    Описание:    Глобальные переменные для обмена данными со SCADA
                 по диагностике и блокировкам
==============================================================================*)
VAR_GLOBAL
    (* ======== КОМАНДЫ ОТ SCADA (SCADA -> ПЛК) ======== *)
    GVL_SCADA_in_Reset_All: BOOL := FALSE;           (* Общий сброс всех ошибок *)
    GVL_SCADA_in_Reset_Measurement: BOOL := FALSE;   (* Сброс ошибок измерительной системы *)
    GVL_SCADA_in_Reset_PropValve: BOOL := FALSE;     (* Сброс ошибок пропорционального клапана *)
    GVL_SCADA_in_Reset_EMValve: BOOL := FALSE;       (* Сброс ошибок электромагнитного клапана *)
    GVL_SCADA_in_Reset_Pump1: BOOL := FALSE;         (* Сброс ошибок насоса 1 *)
    GVL_SCADA_in_Reset_Pump2: BOOL := FALSE;         (* Сброс ошибок насоса 2 *)
    
    (* ======== ИНФОРМАЦИЯ ДЛЯ SCADA (ПЛК -> SCADA) ======== *)
    GVL_SCADA_out_AnyError: BOOL;                    (* Флаг наличия любых ошибок *)
    GVL_SCADA_out_SystemBlocking: BOOL;              (* Флаг полной блокировки системы *)
    GVL_SCADA_out_LampState: BOOL;                   (* Текущее состояние лампы *)
    GVL_SCADA_out_LampMode: DINT;                    (* Режим работы лампы *)
    GVL_SCADA_out_ErrorMask: DWORD;                  (* Битовая маска активных ошибок *)
    
    (* Состояния блокировок устройств *)
    GVL_SCADA_out_PropValveBlocking: BOOL;           (* Блокировка пропорционального клапана *)
    GVL_SCADA_out_EMValveBlocking: BOOL;             (* Блокировка электромагнитного клапана *)
    GVL_SCADA_out_Pump1Blocking: BOOL;               (* Блокировка насоса 1 *)
    GVL_SCADA_out_Pump2Blocking: BOOL;               (* Блокировка насоса 2 *)
END_VAR