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


(* ======================================================================== *)
(* Обмен данными с датчиками давления - расширенный                         *)
(* ======================================================================== *)

(* Датчики давления - дополнительные данные *)
GVL_out_SCADA_PressureKIE2_Status := GVL_stPressureKIE2.eStatus;
GVL_out_SCADA_PressureKIE2_ErrorCode := GVL_stPressureKIE2.wErrorCode;
GVL_out_SCADA_PressurePipe_Status := GVL_stPressurePipe.eStatus;
GVL_out_SCADA_PressurePipe_ErrorCode := GVL_stPressurePipe.wErrorCode;
GVL_out_SCADA_PressurePumpIn1_Status := GVL_stPressurePumpIn1.eStatus;
GVL_out_SCADA_PressurePumpIn1_ErrorCode := GVL_stPressurePumpIn1.wErrorCode;
GVL_out_SCADA_PressurePumpOut1_Status := GVL_stPressurePumpOut1.eStatus;
GVL_out_SCADA_PressurePumpOut1_ErrorCode := GVL_stPressurePumpOut1.wErrorCode;
GVL_out_SCADA_PressurePumpIn2_Status := GVL_stPressurePumpIn2.eStatus;
GVL_out_SCADA_PressurePumpIn2_ErrorCode := GVL_stPressurePumpIn2.wErrorCode;
GVL_out_SCADA_PressurePumpOut2_Status := GVL_stPressurePumpOut2.eStatus;
GVL_out_SCADA_PressurePumpOut2_ErrorCode := GVL_stPressurePumpOut2.wErrorCode;

(* Гидростатический датчик уровня - дополнительные данные *)
GVL_out_SCADA_LevelKIE1_Status := GVL_stHydroLevel_KIE1.eStatus;
GVL_out_SCADA_LevelKIE1_ErrorCode := GVL_stHydroLevel_KIE1.wErrorCode;
GVL_out_SCADA_LevelKIE1_RawPressure := GVL_stHydroLevel_KIE1.rRawPressurePa;

(* Поплавковые датчики - дополнительные данные *)
GVL_out_SCADA_FloatLevel_Status := GVL_stFloatLevelSensors.eStatus;
GVL_out_SCADA_FloatLevel_ErrorCode := GVL_stFloatLevelSensors.wErrorCode;
GVL_out_SCADA_FloatLevel_Valid := GVL_stFloatLevelSensors.bValid;

(* Расходомеры - дополнительные данные *)
GVL_out_SCADA_FlowPumpOut1_TotalLiters := GVL_stFlowSensor_PumpOut1.rTotalLiters;
GVL_out_SCADA_FlowPumpOut1_FrequencyHz := GVL_stFlowSensor_PumpOut1.rFrequencyHz;
GVL_out_SCADA_FlowPumpOut1_Status := GVL_stFlowSensor_PumpOut1.eStatus;
GVL_out_SCADA_FlowPumpOut1_ErrorCode := GVL_stFlowSensor_PumpOut1.wErrorCode;
GVL_out_SCADA_FlowPumpOut1_Valid := GVL_stFlowSensor_PumpOut1.bValid;

GVL_out_SCADA_FlowPumpOut2_TotalLiters := GVL_stFlowSensor_PumpOut2.rTotalLiters;
GVL_out_SCADA_FlowPumpOut2_FrequencyHz := GVL_stFlowSensor_PumpOut2.rFrequencyHz;
GVL_out_SCADA_FlowPumpOut2_Status := GVL_stFlowSensor_PumpOut2.eStatus;
GVL_out_SCADA_FlowPumpOut2_ErrorCode := GVL_stFlowSensor_PumpOut2.wErrorCode;
GVL_out_SCADA_FlowPumpOut2_Valid := GVL_stFlowSensor_PumpOut2.bValid;

GVL_out_SCADA_FlowPipe_TotalLiters := GVL_stFlowSensor_Pipe.rTotalLiters;
GVL_out_SCADA_FlowPipe_FrequencyHz := GVL_stFlowSensor_Pipe.rFrequencyHz;
GVL_out_SCADA_FlowPipe_Status := GVL_stFlowSensor_Pipe.eStatus;
GVL_out_SCADA_FlowPipe_ErrorCode := GVL_stFlowSensor_Pipe.wErrorCode;
GVL_out_SCADA_FlowPipe_Valid := GVL_stFlowSensor_Pipe.bValid;

(* Пропорциональный клапан - дополнительные данные *)
GVL_out_SCADA_PropValve_Valid := stPropValve.bValid;
GVL_out_SCADA_PropValve_Settings_CloseThreshold := stPropValve.stSettings.rCloseThreshold;
GVL_out_SCADA_PropValve_Settings_OpenThreshold := stPropValve.stSettings.rOpenThreshold;

(* Электромагнитный клапан - дополнительные данные *)
GVL_out_SCADA_EMValve_WarningThreshold := stEMValve.tWarningThreshold;

(* Сброс команд после обработки *)
stEMValve.bReset := FALSE;