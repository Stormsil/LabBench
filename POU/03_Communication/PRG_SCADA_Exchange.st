(*==============================================================================
    Название:    PRG_SCADA_Exchange
    Автор:       Редько А.
    Дата:        2025-05-01
    Версия:      3.0
    
    Описание:    Программа обмена данными между SCADA и объектами.
                 - Оптимизирована для работы с OPC с использованием простых типов
                 - Использует R_TRIG для обработки команд
                 - Имеет счетчик Heartbeat вместо булевой переменной
                 - Индивидуальное управление режимами устройств
==============================================================================*)
PROGRAM PRG_SCADA_Exchange
VAR
    (* Измерение времени цикла *)
    tonCycleTimer: TON;                       (* Таймер для измерения времени цикла *)
    timeLastCycle: TIME;                      (* Время последнего цикла *)
    
    (* Счетчик Heartbeat *)
    dwHeartbeatCounter: DWORD := 0;           (* Счетчик Heartbeat *)
    
    (* Триггеры фронтов сигналов *)
    rtResetAllErrors: R_TRIG;                 (* Триггер общего сброса ошибок *)
    rtPropValveReset: R_TRIG;                 (* Триггер сброса ошибок пропорционального крана *)
    rtEMValveReset: R_TRIG;                   (* Триггер сброса ошибок электромагнитного клапана *)
    rtLevelReset: R_TRIG;                     (* Триггер сброса ошибок всех датчиков уровня *)
    rtLevelKIE1Reset: R_TRIG;                 (* Триггер сброса ошибок гидростатического датчика *)
    rtFloatLevelReset: R_TRIG;                (* Триггер сброса ошибок поплавковых датчиков *)
    rtPressureReset: R_TRIG;                  (* Триггер сброса ошибок датчиков давления *)
    rtPressureKIE2Reset: R_TRIG;                (* Триггер сброса ошибок датчика давления в КИЕ2 *)
    rtPressurePumpIn1Reset: R_TRIG;           (* Триггер сброса ошибок датчика давления перед насосом 1 *)
    rtPressurePumpIn2Reset: R_TRIG;           (* Триггер сброса ошибок датчика давления перед насосом 2 *)
    rtPressurePumpOut1Reset: R_TRIG;          (* Триггер сброса ошибок датчика давления после насоса 1 *)
    rtPressurePumpOut2Reset: R_TRIG;          (* Триггер сброса ошибок датчика давления после насоса 2 *)
    rtPressurePipeReset : R_TRIG;              (* Триггер сброса ошибок датчика давления в трубопроводе *)
    rtFlowReset: R_TRIG;                      (* Триггер сброса ошибок расходомеров *)
    rtFlowPumpOut1Reset: R_TRIG;              (* Триггер сброса ошибок расходомера насоса 1 *)
    rtFlowPumpOut2Reset: R_TRIG;              (* Триггер сброса ошибок расходомера насоса 2 *)
    rtFlowPipeReset: R_TRIG;                  (* Триггер сброса ошибок расходомера в трубопроводе *)
END_VAR

(* ======================================================================== *)
(* Системные переменные                                                     *)
(* ======================================================================== *)

(* Увеличение счетчика Heartbeat *)
IF dwHeartbeatCounter < 16#FFFFFFFF THEN
    dwHeartbeatCounter := dwHeartbeatCounter + 1;
ELSE
    dwHeartbeatCounter := 0;
END_IF;
GVL_SCADA_out_System_Heartbeat := dwHeartbeatCounter;

(* Измерение времени цикла и конвертация TIME -> DINT *)
tonCycleTimer(IN := TRUE, PT := T#4H);  (* Большое значение для непрерывного отсчета *)
GVL_SCADA_out_System_CycleTime_ms := TIME_TO_DINT(tonCycleTimer.ET - timeLastCycle);
timeLastCycle := tonCycleTimer.ET;

(* Обработка команды общего сброса ошибок *)
rtResetAllErrors(CLK := GVL_SCADA_in_System_ResetAllErrors);
IF rtResetAllErrors.Q THEN
    (* По фронту сигнала общего сброса активируем все индивидуальные сбросы *)
    GVL_SCADA_in_PropValve_Reset := TRUE;
    GVL_SCADA_in_EMValve_Reset := TRUE;
    GVL_SCADA_in_Level_KIE1_Reset := TRUE;
    GVL_SCADA_in_Pressure_Reset := TRUE;
    GVL_SCADA_in_Flow_Reset := TRUE;
    GVL_SCADA_in_Flow_PumpOut1_Reset := TRUE;
    GVL_SCADA_in_Flow_PumpOut2_Reset := TRUE;
    GVL_SCADA_in_Flow_Pipe_Reset := TRUE;
    GVL_SCADA_in_System_ResetAllErrors := FALSE; (* Сброс команды *)
END_IF;

(* ======================================================================== *)
(* Обмен данными с пропорциональным краном                                  *)
(* ======================================================================== *)

(* Передача режима работы с конвертацией DINT -> ENUM *)
CASE GVL_SCADA_in_PropValve_Mode OF
    0: stPropValve.stCommands.eMode := AUTO;
    1: stPropValve.stCommands.eMode := MANUAL;
    2: stPropValve.stCommands.eMode := DISABLED;
    3: stPropValve.stCommands.eMode := E_STOP;
ELSE
    (* Неизвестное значение - установка MANUAL как безопасного режима *)
    stPropValve.stCommands.eMode := MANUAL;
    GVL_SCADA_in_PropValve_Mode := 1;
END_CASE;

(* Применение команд и настроек *)
stPropValve.stCommands.rPositionSetpoint := GVL_SCADA_in_PropValve_SetPosition;                     (* Установка целевой позиции *)
stPropValve.stSettings.rSafePosition := GVL_SCADA_in_PropValve_SafePosition;                        (* Установка безопасной позиции *)
stPropValve.stSettings.rCloseThreshold := GVL_SCADA_in_PropValve_CloseThreshold;                    (* Установка порога закрытия *)
stPropValve.stSettings.rOpenThreshold := GVL_SCADA_in_PropValve_OpenThreshold;                      (* Установка порога открытия *)
stPropValve.stSettings.rDeadband := GVL_SCADA_in_PropValve_Deadband;                                (* Установка зоны нечувствительности *)
stPropValve.stSettings.tPositionTimeout := DINT_TO_TIME(GVL_SCADA_in_PropValve_PositionTimeout_ms); (* Таймаут достижения позиции *)
stPropValve.stSettings.tStuckTimeout := DINT_TO_TIME(GVL_SCADA_in_PropValve_StuckTimeout_ms);       (* Таймаут заклинивания *)

(* Обработка команды сброса по фронту сигнала *)
rtPropValveReset(CLK := GVL_SCADA_in_PropValve_Reset);
IF rtPropValveReset.Q THEN
    stPropValve.stCommands.bReset := TRUE;
    GVL_SCADA_in_PropValve_Reset := FALSE; (* Сброс флага команды *)
END_IF;

(* Обновление текущих значений *)
GVL_SCADA_out_PropValve_ActualPosition := stPropValve.rActualPosition; (* Текущая позиция *)
GVL_SCADA_out_PropValve_TargetPosition := stPropValve.rTargetPosition; (* Целевая позиция *)
GVL_SCADA_out_PropValve_ErrorCode := stPropValve.wErrorCode; (* Код ошибки *)
GVL_SCADA_out_PropValve_Valid := stPropValve.bValid; (* Валидность *)
GVL_SCADA_out_PropValve_Moving := stPropValve.bMoving; (*  Флаг движения *)

(* Обновление статусов с конвертацией ENUM -> DINT *)
GVL_SCADA_out_PropValve_Mode := ENUM_TO_DINT(stPropValve.eMode); (* Режим работы *)
GVL_SCADA_out_PropValve_State := ENUM_TO_DINT(stPropValve.eState); (* Состояние *)

(* ======================================================================== *)
(* Обмен данными с электромагнитным клапаном                                *)
(* ======================================================================== *)

(* Передача режима работы с конвертацией DINT -> ENUM *)
CASE GVL_SCADA_in_EMValve_Mode OF
    0: GVL_in_SCADA_EMValve_Mode := AUTO;
    1: GVL_in_SCADA_EMValve_Mode := MANUAL;
    2: GVL_in_SCADA_EMValve_Mode := DISABLED;
    3: GVL_in_SCADA_EMValve_Mode := E_STOP;
ELSE
    (* Неизвестное значение - установка MANUAL как безопасного режима *)
    GVL_in_SCADA_EMValve_Mode := MANUAL;
    GVL_SCADA_in_EMValve_Mode := 1;
END_CASE;

(* Применение команд через оригинальные переменные для PRG_EquipmentProcessing *)
GVL_in_SCADA_EMValve_Open := GVL_SCADA_in_EMValve_Open;                                 (* Команда открытия в ручном режиме *)
GVL_in_SCADA_EMValve_AutoOpen := GVL_SCADA_in_EMValve_AutoOpen;                         (* Команда открытия от регулятора *)
GVL_in_SCADA_EMValve_WarningTime := DINT_TO_TIME(GVL_SCADA_in_EMValve_WarningTime_ms);  (* Время предупреждения *)

(* Обработка команды сброса по фронту сигнала *)
rtEMValveReset(CLK := GVL_SCADA_in_EMValve_Reset);
IF rtEMValveReset.Q THEN
    stEMValve.bReset := TRUE;
    GVL_SCADA_in_EMValve_Reset := FALSE; (* Сброс флага команды *)
END_IF;

(* Обновление текущих значений *)
GVL_SCADA_out_EMValve_IsOpen := stEMValve.bIsOpen; (* Флаг открытия *)
GVL_SCADA_out_EMValve_Mode := ENUM_TO_DINT(stEMValve.eMode); (* Режим работы *)
GVL_SCADA_out_EMValve_State := ENUM_TO_DINT(stEMValve.eState); (* Состояние *)
GVL_SCADA_out_EMValve_ContinuousOpTime_ms := TIME_TO_DINT(stEMValve.tContinuousOpTime); (* Время непрерывной работы *)
GVL_SCADA_out_EMValve_TotalOpTime_ms := TIME_TO_DINT(stEMValve.tOperationTime); (* Общее время работы *)
GVL_SCADA_out_EMValve_WarningThreshold_ms := TIME_TO_DINT(stEMValve.tWarningThreshold); (* Порог предупреждения *)

(* ======================================================================== *)
(* Обмен данными с датчиками уровня                                         *)
(* ======================================================================== *)

(* Обработка команды сброса для гидростатического датчика *)
rtLevelKIE1Reset(CLK := GVL_SCADA_in_Level_KIE1_Reset);
IF rtLevelKIE1Reset.Q THEN
    
    GVL_SCADA_in_Level_KIE1_Reset := FALSE; (* Сброс флага команды *)
END_IF;

(* Гидростатический датчик уровня в КИЕ1 - обновление статусов с конвертацией *)
GVL_SCADA_out_Level_KIE1_LevelMM := GVL_stHydroLevel_KIE1.rLevelMM; (* Уровень в мм *)
GVL_SCADA_out_Level_KIE1_LevelPercent := GVL_stHydroLevel_KIE1.rLevelPercent; (* Уровень в процентах *)
GVL_SCADA_out_Level_KIE1_RawPressurePa := GVL_stHydroLevel_KIE1.rRawPressurePa; (* Исходное давление в Па *)
GVL_SCADA_out_Level_KIE1_Status := ENUM_TO_DINT(GVL_stHydroLevel_KIE1.eStatus); (* Статус *)
GVL_SCADA_out_Level_KIE1_ErrorCode := GVL_stHydroLevel_KIE1.wErrorCode; (* Код ошибки *)
GVL_SCADA_out_Level_KIE1_Valid := GVL_stHydroLevel_KIE1.bValid; (* Валидность *)

(* Обработка команды сброса для поплавковых датчиков уровня *)
rtFloatLevelReset(CLK := GVL_SCADA_in_FloatLevel_Reset);
IF rtFloatLevelReset.Q THEN

    GVL_SCADA_in_FloatLevel_Reset := FALSE; (* Сброс флага команды *)
END_IF;

(* Поплавковые датчики уровня - обновление статусов с конвертацией *) 
GVL_SCADA_out_FloatLevel_Low := GVL_stFloatLevelSensors.bLowLevelActive; (* Низкий уровень активен *)
GVL_SCADA_out_FloatLevel_Mid := GVL_stFloatLevelSensors.bMidLevelActive; (* Средний уровень активен *)
GVL_SCADA_out_FloatLevel_High := GVL_stFloatLevelSensors.bHighLevelActive; (* Высокий уровень активен *)
GVL_SCADA_out_FloatLevel_EstimationMM := GVL_stFloatLevelSensors.rLevelEstimationMM; (* Оценка уровня в мм *)
GVL_SCADA_out_FloatLevel_Percent := GVL_stFloatLevelSensors.rLevelPercent; (* Уровень в процентах *)
GVL_SCADA_out_FloatLevel_Status := ENUM_TO_DINT(GVL_stFloatLevelSensors.eStatus); (* Статус *)
GVL_SCADA_out_FloatLevel_ErrorCode := GVL_stFloatLevelSensors.wErrorCode; (* Код ошибки *)
GVL_SCADA_out_FloatLevel_Valid := GVL_stFloatLevelSensors.bValid; (* Валидность *)

(* ======================================================================== *)
(* Обмен данными с датчиками давления                                       *)
(* ======================================================================== *)

(* Обработка команды сброса для датчиков давления *)
rtPressureReset(CLK := GVL_SCADA_in_Pressure_Reset);
IF rtPressureReset.Q THEN
    (* Здесь можно добавить код для сброса ошибок датчиков давления *)
    bResetErrors := TRUE; (* Переменная, используемая в PRG_SensorProcessing *)
    GVL_SCADA_in_Pressure_Reset := FALSE; (* Сброс флага команды *)
END_IF;

(* Датчик давления в КИЕ2 - обновление статусов с конвертацией *)
GVL_SCADA_out_Pressure_KIE2_PressureKPa := GVL_stPressureKIE2.rPressureKPa; (* Давление в кПа *)
GVL_SCADA_out_Pressure_KIE2_Status := ENUM_TO_DINT(GVL_stPressureKIE2.eStatus); (* Статус *)
GVL_SCADA_out_Pressure_KIE2_ErrorCode := GVL_stPressureKIE2.wErrorCode;          (* Код ошибки *)
GVL_SCADA_out_Pressure_KIE2_Valid := GVL_stPressureKIE2.bValid;              (* Валидность *)

(* Датчик давления в трубопроводе - обновление статусов с конвертацией *)
GVL_SCADA_out_Pressure_Pipe_PressureKPa := GVL_stPressurePipe.rPressureKPa; (* Давление в кПа *)
GVL_SCADA_out_Pressure_Pipe_Status := ENUM_TO_DINT(GVL_stPressurePipe.eStatus); (* Статус *)
GVL_SCADA_out_Pressure_Pipe_ErrorCode := GVL_stPressurePipe.wErrorCode;         (* Код ошибки *)
GVL_SCADA_out_Pressure_Pipe_Valid := GVL_stPressurePipe.bValid; (* Валидность *)

(* Датчик давления перед насосом 1 - обновление статусов с конвертацией *)
GVL_SCADA_out_Pressure_PumpIn1_PressureKPa := GVL_stPressurePumpIn1.rPressureKPa; (* Давление в кПа *)
GVL_SCADA_out_Pressure_PumpIn1_Status := ENUM_TO_DINT(GVL_stPressurePumpIn1.eStatus); (* Статус *)
GVL_SCADA_out_Pressure_PumpIn1_ErrorCode := GVL_stPressurePumpIn1.wErrorCode;         (* Код ошибки *)
GVL_SCADA_out_Pressure_PumpIn1_Valid := GVL_stPressurePumpIn1.bValid;            (* Валидность *)

(* Датчик давления после насоса 1 - обновление статусов с конвертацией *)
GVL_SCADA_out_Pressure_PumpOut1_PressureKPa := GVL_stPressurePumpOut1.rPressureKPa; (* Давление в кПа *)
GVL_SCADA_out_Pressure_PumpOut1_Status := ENUM_TO_DINT(GVL_stPressurePumpOut1.eStatus); (* Статус *)
GVL_SCADA_out_Pressure_PumpOut1_ErrorCode := GVL_stPressurePumpOut1.wErrorCode;        (* Код ошибки *)
GVL_SCADA_out_Pressure_PumpOut1_Valid := GVL_stPressurePumpOut1.bValid;         (* Валидность *)

(* Датчик давления перед насосом 2 - обновление статусов с конвертацией *)
GVL_SCADA_out_Pressure_PumpIn2_PressureKPa := GVL_stPressurePumpIn2.rPressureKPa; (* Давление в кПа *)
GVL_SCADA_out_Pressure_PumpIn2_Status := ENUM_TO_DINT(GVL_stPressurePumpIn2.eStatus); (* Статус *)
GVL_SCADA_out_Pressure_PumpIn2_ErrorCode := GVL_stPressurePumpIn2.wErrorCode;        (* Код ошибки *)
GVL_SCADA_out_Pressure_PumpIn2_Valid := GVL_stPressurePumpIn2.bValid;          (* Валидность *)

(* Датчик давления после насоса 2 - обновление статусов с конвертацией *)
GVL_SCADA_out_Pressure_PumpOut2_PressureKPa := GVL_stPressurePumpOut2.rPressureKPa; (* Давление в кПа *)
GVL_SCADA_out_Pressure_PumpOut2_Status := ENUM_TO_DINT(GVL_stPressurePumpOut2.eStatus); (* Статус *)
GVL_SCADA_out_Pressure_PumpOut2_ErrorCode := GVL_stPressurePumpOut2.wErrorCode;           (* Код ошибки *)
GVL_SCADA_out_Pressure_PumpOut2_Valid := GVL_stPressurePumpOut2.bValid;               (* Валидность *)

(* ======================================================================== *)
(* Обмен данными с расходомерами                                            *)
(* ======================================================================== *)

(* Обработка команды сброса для расходомеров *)
rtFlowReset(CLK := GVL_SCADA_in_Flow_Reset);
IF rtFlowReset.Q THEN
    GVL_SCADA_in_Flow_PumpOut1_Reset := TRUE;
    GVL_SCADA_in_Flow_PumpOut2_Reset := TRUE;
    GVL_SCADA_in_Flow_Pipe_Reset := TRUE;
    GVL_SCADA_in_Flow_Reset := FALSE; (* Сброс флага команды *)
END_IF;

(* Обработка индивидуальных команд сброса для расходомеров *)
rtFlowPumpOut1Reset(CLK := GVL_SCADA_in_Flow_PumpOut1_Reset);
rtFlowPumpOut2Reset(CLK := GVL_SCADA_in_Flow_PumpOut2_Reset);
rtFlowPipeReset(CLK := GVL_SCADA_in_Flow_Pipe_Reset);

(* Сброс счетчиков по фронтам сигналов - логика должна быть реализована
   в соответствующих функциональных блоках *)
IF rtFlowPumpOut1Reset.Q THEN
    GVL_SCADA_in_Flow_PumpOut1_Reset := FALSE; (* Сброс флага команды *)
END_IF;

IF rtFlowPumpOut2Reset.Q THEN
    GVL_SCADA_in_Flow_PumpOut2_Reset := FALSE; (* Сброс флага команды *)
END_IF;

IF rtFlowPipeReset.Q THEN
    GVL_SCADA_in_Flow_Pipe_Reset := FALSE; (* Сброс флага команды *)
END_IF;

(* Расходомер после насоса 1 - обновление статусов с конвертацией *)
GVL_SCADA_out_Flow_PumpOut1_FlowLPM := GVL_stFlowSensor_PumpOut1.rFlowLPM; (* Расход в л/мин *)
GVL_SCADA_out_Flow_PumpOut1_FlowM3H := GVL_stFlowSensor_PumpOut1.rFlowM3H; (* Расход в м³/ч *)
GVL_SCADA_out_Flow_PumpOut1_TotalLiters := GVL_stFlowSensor_PumpOut1.rTotalLiters; (* Всего литров *)
GVL_SCADA_out_Flow_PumpOut1_FrequencyHz := GVL_stFlowSensor_PumpOut1.rFrequencyHz; (* Частота в Гц *)
GVL_SCADA_out_Flow_PumpOut1_Status := ENUM_TO_DINT(GVL_stFlowSensor_PumpOut1.eStatus); (* Статус *)
GVL_SCADA_out_Flow_PumpOut1_ErrorCode := GVL_stFlowSensor_PumpOut1.wErrorCode; (* Код ошибки *)
GVL_SCADA_out_Flow_PumpOut1_Valid := GVL_stFlowSensor_PumpOut1.bValid; (* Валидность *)

(* Расходомер после насоса 2 - обновление статусов с конвертацией *)
GVL_SCADA_out_Flow_PumpOut2_FlowLPM := GVL_stFlowSensor_PumpOut2.rFlowLPM; (* Расход в л/мин *)
GVL_SCADA_out_Flow_PumpOut2_FlowM3H := GVL_stFlowSensor_PumpOut2.rFlowM3H; (* Расход в м³/ч *)
GVL_SCADA_out_Flow_PumpOut2_TotalLiters := GVL_stFlowSensor_PumpOut2.rTotalLiters; (* Всего литров *)
GVL_SCADA_out_Flow_PumpOut2_FrequencyHz := GVL_stFlowSensor_PumpOut2.rFrequencyHz; (* Частота в Гц *)
GVL_SCADA_out_Flow_PumpOut2_Status := ENUM_TO_DINT(GVL_stFlowSensor_PumpOut2.eStatus); (* Статус *)
GVL_SCADA_out_Flow_PumpOut2_ErrorCode := GVL_stFlowSensor_PumpOut2.wErrorCode;  (* Код ошибки *)
GVL_SCADA_out_Flow_PumpOut2_Valid := GVL_stFlowSensor_PumpOut2.bValid; (* Валидность *)

(* Расходомер в трубопроводе - обновление статусов с конвертацией *)
GVL_SCADA_out_Flow_Pipe_FlowLPM := GVL_stFlowSensor_Pipe.rFlowLPM; (* Расход в л/мин *)
GVL_SCADA_out_Flow_Pipe_FlowM3H := GVL_stFlowSensor_Pipe.rFlowM3H; (* Расход в м³/ч *)
GVL_SCADA_out_Flow_Pipe_TotalLiters := GVL_stFlowSensor_Pipe.rTotalLiters; (* Всего литров *)
GVL_SCADA_out_Flow_Pipe_FrequencyHz := GVL_stFlowSensor_Pipe.rFrequencyHz; (* Частота в Гц *)
GVL_SCADA_out_Flow_Pipe_Status := ENUM_TO_DINT(GVL_stFlowSensor_Pipe.eStatus); (* Статус *)
GVL_SCADA_out_Flow_Pipe_ErrorCode := GVL_stFlowSensor_Pipe.wErrorCode; (* Код ошибки *) 
GVL_SCADA_out_Flow_Pipe_Valid := GVL_stFlowSensor_Pipe.bValid; (* Валидность *)
