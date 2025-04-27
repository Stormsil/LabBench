(*==============================================================================
    Название:    GVL_SCADA
    Автор:       Редько А.
    Дата:        2025-04-27
    Версия:      1.0
    
    Описание:    Глобальные переменные для интерфейса SCADA
==============================================================================*)
VAR_GLOBAL
    (* Пропорциональный кран - входные переменные (из SCADA в ПЛК) *)
    GVL_in_SCADA_PropValve_Mode: E_EquipmentMode := MANUAL;    (* Режим работы *)
    GVL_in_SCADA_PropValve_SetPosition: REAL := 0.0;           (* Задание положения (0-100%) *)
    GVL_in_SCADA_PropValve_Reset: BOOL := FALSE;               (* Сброс ошибок *)
    GVL_in_SCADA_PropValve_SafePosition: REAL := 0.0;          (* Безопасное положение (0-100%) - закрыт *)
    
    (* Пропорциональный кран - выходные переменные (из ПЛК в SCADA) *)
    GVL_out_SCADA_PropValve_ActualPosition: REAL;              (* Текущее положение (0-100%) *)
    GVL_out_SCADA_PropValve_TargetPosition: REAL;              (* Целевое положение (0-100%) *)
    GVL_out_SCADA_PropValve_Mode: E_EquipmentMode;             (* Текущий режим работы *)
    GVL_out_SCADA_PropValve_State: E_PropValveState;           (* Состояние крана *)
    GVL_out_SCADA_PropValve_ErrorCode: WORD;                   (* Код ошибки *)
    GVL_out_SCADA_PropValve_Moving: BOOL;                      (* Флаг движения крана *)
END_VAR