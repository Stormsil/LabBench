(*==============================================================================
    Название:    PRG_SCADA_Exchange
    Автор:       Редько А.
    Дата:        2025-04-27
    Версия:      1.0
    
    Описание:    Программа обмена данными между SCADA и объектами
==============================================================================*)
PROGRAM PRG_SCADA_Exchange
VAR
    (* Локальные переменные для обработки команд *)
    bOldPropValveReset: BOOL := FALSE;  (* Предыдущее значение команды сброса *)
    bOldEMValveReset: BOOL := FALSE;  (* Предыдущее значение команды сброса *)
END_VAR

(* ======================================================================== *)
(* Обмен данными с пропорциональным краном                                  *)
(* ======================================================================== *)

(* ВХОДНЫЕ переменные - чтение команд и настроек со SCADA (in_SCADA -> ПЛК) *)
(* Чтение режима работы *)
stPropValve.stCommands.eMode := GVL_in_SCADA_PropValve_Mode;

(* Чтение уставки положения *)
stPropValve.stCommands.rPositionSetpoint := GVL_in_SCADA_PropValve_SetPosition;

(* Чтение безопасного положения *)
stPropValve.stSettings.rSafePosition := GVL_in_SCADA_PropValve_SafePosition;

(* Обработка команды сброса - по фронту сигнала *)
IF GVL_in_SCADA_PropValve_Reset AND NOT bOldPropValveReset THEN
    stPropValve.stCommands.bReset := TRUE;
END_IF;
bOldPropValveReset := GVL_in_SCADA_PropValve_Reset;

(* ВЫХОДНЫЕ переменные - запись данных в SCADA (ПЛК -> out_SCADA) *)
(* Запись текущего и целевого положения *)
GVL_out_SCADA_PropValve_ActualPosition := stPropValve.rActualPosition;
GVL_out_SCADA_PropValve_TargetPosition := stPropValve.rTargetPosition;

(* Запись режима и состояния *)
GVL_out_SCADA_PropValve_Mode := stPropValve.eMode;
GVL_out_SCADA_PropValve_State := stPropValve.eState;

(* Запись кода ошибки *)
GVL_out_SCADA_PropValve_ErrorCode := stPropValve.wErrorCode;

(* Запись флага движения *)
GVL_out_SCADA_PropValve_Moving := stPropValve.bMoving;

(* Сброс команд после обработки *)
stPropValve.stCommands.bReset := FALSE;

(* ======================================================================== *)
(* Обмен данными с электромагнитным клапаном                                *)
(* ======================================================================== *)

(* ВХОДНЫЕ переменные - чтение команд и настроек со SCADA (in_SCADA -> ПЛК) *)
 
(* Чтение порога предупреждения *)
stEMValve.tWarningThreshold := GVL_in_SCADA_EMValve_WarningTime;

(* Чтение режима работы *)
stEMValve.eMode := GVL_in_SCADA_EMValve_Mode;


(* Обработка команды сброса - по фронту сигнала *)
IF GVL_in_SCADA_EMValve_Reset AND NOT bOldEMValveReset THEN
    stEMValve.bReset := TRUE;
END_IF;
bOldEMValveReset := GVL_in_SCADA_EMValve_Reset;

(* ВЫХОДНЫЕ переменные - запись данных в SCADA (ПЛК -> out_SCADA) *)

(* Запись текущего состояния *)
GVL_out_SCADA_EMValve_IsOpen := stEMValve.bIsOpen;
GVL_out_SCADA_EMValve_Mode := stEMValve.eMode;
GVL_out_SCADA_EMValve_State := stEMValve.eState;
GVL_out_SCADA_EMValve_ContinuousOpTime := stEMValve.tContinuousOpTime;
GVL_out_SCADA_EMValve_TotalOpTime := stEMValve.tOperationTime;

(* Сброс команд после обработки *)
stEMValve.bReset := FALSE;