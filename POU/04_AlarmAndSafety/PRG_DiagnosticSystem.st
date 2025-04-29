(*==============================================================================
    Название:    PRG_DiagnosticSystem_Extended
    Автор:       
    Дата:        2025-04-30
    Версия:      1.0
    
    Описание:    Программа расширенной диагностики и управления блокировками
                 Обрабатывает ошибки, сценарии диагностики, управляет
                 последовательностью останова и блокировками оборудования
==============================================================================*)
PROGRAM PRG_DiagnosticSystem_Extended
VAR
    (* Экземпляры функциональных блоков *)
    fbErrorManager: FB_ErrorManager;          (* Менеджер ошибок и блокировок *)
    fbDiagnosticScenario: FB_DiagnosticScenario; (* Блок диагностических сценариев *)
    fbSystemManager: FB_SystemManager;        (* Менеджер состояния системы *)
    fbShutdownSequencer: FB_ShutdownSequencer;(* Последовательность останова *)
    fbLampController: FB_LampController;      (* Контроллер сигнальной лампы *)
    
    (* Локальные переменные *)
    bInitialized: BOOL := FALSE;              (* Флаг инициализации *)
    
    (* Триггеры для обработки команд от SCADA *)
    rtResetAll: R_TRIG;                       (* Триггер сброса всех ошибок *)
    rtResetMeasurement: R_TRIG;               (* Триггер сброса ошибок измерения *)
    rtResetPropValve: R_TRIG;                 (* Триггер сброса ошибок пропорционального клапана *)
    rtResetEMValve: R_TRIG;                   (* Триггер сброса ошибок электромагнитного клапана *)
    rtResetPump1: R_TRIG;                     (* Триггер сброса ошибок насоса 1 *)
    rtResetPump2: R_TRIG;                     (* Триггер сброса ошибок насоса 2 *)
    rtResetHeater: R_TRIG;                    (* Триггер сброса ошибок нагревателя *)
    rtStartNormalShutdown: R_TRIG;            (* Триггер запуска нормального останова *)
    rtStartEmergencyShutdown: R_TRIG;         (* Триггер запуска аварийного останова *)
    
    (* Данные о состоянии оборудования для диагностики *)
    bHeaterOn: BOOL;                          (* Нагреватель включен *)
    rHeaterPower: REAL;                       (* Мощность нагревателя (%) *)
    bPump1Running: BOOL;                      (* Насос 1 работает *)
    bPump2Running: BOOL;                      (* Насос 2 работает *)
    rPump1Speed: REAL;                        (* Скорость насоса 1 (%) *)
    rPump2Speed: REAL;                        (* Скорость насоса 2 (%) *)
    rTemperature: REAL;                       (* Температура (°C) *)
END_VAR

(* ======================================================================== *)
(* Инициализация системы                                                    *)
(* ======================================================================== *)

(* Инициализация при первом запуске *)
IF NOT bInitialized THEN
    (* Инициализация ошибок и сценариев *)
    
    (* === ОШИБКИ ИЗМЕРИТЕЛЬНОЙ СИСТЕМЫ === *)
    
    (* Ошибка датчика давления КИЕ2 *)
    gaBlockingErrors[1].eCategory := ERROR_MEASUREMENT;
    gaBlockingErrors[1].eBlockingLevel := DEVICE_BLOCKING;
    gaBlockingErrors[1].bLamp := TRUE;
    gaBlockingErrors[1].wSourceID := PRESSURE_SENSORS_ID + 1;
    gaBlockingErrors[1].wDeviceID := PROP_VALVE_ID; (* Блокирует пропорциональный клапан *)
    
    (* Ошибка датчика давления в трубопроводе *)
    gaBlockingErrors[2].eCategory := ERROR_MEASUREMENT;
    gaBlockingErrors[2].eBlockingLevel := SYSTEM_BLOCKING;
    gaBlockingErrors[2].bLamp := TRUE;
    gaBlockingErrors[2].wSourceID := PRESSURE_SENSORS_ID + 2;
    
    (* Ошибка гидростатического датчика уровня *)
    gaBlockingErrors[3].eCategory := ERROR_MEASUREMENT;
    gaBlockingErrors[3].eBlockingLevel := DEVICE_BLOCKING;
    gaBlockingErrors[3].bLamp := TRUE;
    gaBlockingErrors[3].wSourceID := LEVEL_SENSORS_ID + 1;
    gaBlockingErrors[3].wDeviceID := EM_VALVE_ID; (* Блокирует электромагнитный клапан *)
    
    (* Ошибка поплавковых датчиков уровня *)
    gaBlockingErrors[4].eCategory := ERROR_MEASUREMENT;
    gaBlockingErrors[4].eBlockingLevel := SYSTEM_BLOCKING;
    gaBlockingErrors[4].bLamp := TRUE;
    gaBlockingErrors[4].wSourceID := LEVEL_SENSORS_ID + 2;
    
    (* Ошибка расходомера после насоса 1 *)
    gaBlockingErrors[5].eCategory := ERROR_MEASUREMENT;
    gaBlockingErrors[5].eBlockingLevel := DEVICE_BLOCKING;
    gaBlockingErrors[5].bLamp := TRUE;
    gaBlockingErrors[5].wSourceID := FLOW_SENSORS_ID + 1;
    gaBlockingErrors[5].wDeviceID := PUMP1_ID; (* Блокирует насос 1 *)
    
    (* Ошибка расходомера после насоса 2 *)
    gaBlockingErrors[6].eCategory := ERROR_MEASUREMENT;
    gaBlockingErrors[6].eBlockingLevel := DEVICE_BLOCKING;
    gaBlockingErrors[6].bLamp := TRUE;
    gaBlockingErrors[6].wSourceID := FLOW_SENSORS_ID + 2;
    gaBlockingErrors[6].wDeviceID := PUMP2_ID; (* Блокирует насос 2 *)
    
    (* === ОШИБКИ ОБОРУДОВАНИЯ === *)
    
    (* Ошибка пропорционального клапана *)
    gaBlockingErrors[7].eCategory := ERROR_EQUIPMENT;
    gaBlockingErrors[7].eBlockingLevel := DEVICE_BLOCKING;
    gaBlockingErrors[7].bLamp := TRUE;
    gaBlockingErrors[7].wSourceID := PROP_VALVE_ID;
    gaBlockingErrors[7].wDeviceID := PROP_VALVE_ID;
    
    (* Ошибка электромагнитного клапана *)
    gaBlockingErrors[8].eCategory := ERROR_EQUIPMENT;
    gaBlockingErrors[8].eBlockingLevel := DEVICE_BLOCKING;
    gaBlockingErrors[8].bLamp := TRUE;
    gaBlockingErrors[8].wSourceID := EM_VALVE_ID;
    gaBlockingErrors[8].wDeviceID := EM_VALVE_ID;
    
    (* Ошибка насоса 1 (ПЧ) *)
    gaBlockingErrors[9].eCategory := ERROR_EQUIPMENT;
    gaBlockingErrors[9].eBlockingLevel := DEVICE_BLOCKING;
    gaBlockingErrors[9].bLamp := TRUE;
    gaBlockingErrors[9].wSourceID := PUMP1_ID;
    gaBlockingErrors[9].wDeviceID := PUMP1_ID;
    
    (* Ошибка насоса 2 (ПЧ) *)
    gaBlockingErrors[10].eCategory := ERROR_EQUIPMENT;
    gaBlockingErrors[10].eBlockingLevel := DEVICE_BLOCKING;
    gaBlockingErrors[10].bLamp := TRUE;
    gaBlockingErrors[10].wSourceID := PUMP2_ID;
    gaBlockingErrors[10].wDeviceID := PUMP2_ID;
    
    (* Ошибка нагревателя (ТЭН/ТРМ10) *)
    gaBlockingErrors[11].eCategory := ERROR_EQUIPMENT;
    gaBlockingErrors[11].eBlockingLevel := DEVICE_BLOCKING;
    gaBlockingErrors[11].bLamp := TRUE;
    gaBlockingErrors[11].wSourceID := HEATER_ID;
    gaBlockingErrors[11].wDeviceID := HEATER_ID;
    
    (* === ОШИБКИ СВЯЗИ === *)
    gaBlockingErrors[12].eCategory := ERROR_COMMUNICATION;
    gaBlockingErrors[12].eBlockingLevel := SYSTEM_BLOCKING;
    gaBlockingErrors[12].bLamp := TRUE;
    gaBlockingErrors[12].wSourceID := COMMUNICATION_ID;
    
    (* === ОШИБКИ ПРОЦЕССА === *)
    gaBlockingErrors[13].eCategory := ERROR_PROCESS;
    gaBlockingErrors[13].eBlockingLevel := SYSTEM_BLOCKING;
    gaBlockingErrors[13].bLamp := TRUE;
    gaBlockingErrors[13].wSourceID := SYSTEM_ID;
    
    (* Инициализация последовательности останова *)
    gstShutdownSequence.eCurrentStep := SHUTDOWN_INIT;
    gstShutdownSequence.bInProgress := FALSE;
    gstShutdownSequence.bEmergency := FALSE;
    gstShutdownSequence.bCompleted := FALSE;
    gstShutdownSequence.bError := FALSE;
    
    (* Установка системного состояния *)
    geSystemState := SYSTEM_INIT;
    
    bInitialized := TRUE;
END_IF;

(* ======================================================================== *)
(* Обработка команд от SCADA                                                *)
(* ======================================================================== *)

(* Обработка команды общего сброса *)
rtResetAll(CLK := GVL_SCADA_in_Reset_All);
IF rtResetAll.Q THEN
    gxResetAll := TRUE;
    GVL_SCADA_in_Reset_All := FALSE;
END_IF;

(* Обработка команды сброса ошибок измерительной системы *)
rtResetMeasurement(CLK := GVL_SCADA_in_Reset_Measurement);
IF rtResetMeasurement.Q THEN
    gxResetMeasurement := TRUE;
    GVL_SCADA_in_Reset_Measurement := FALSE;
END_IF;

(* Обработка команды сброса ошибок пропорционального клапана *)
rtResetPropValve(CLK := GVL_SCADA_in_Reset_PropValve);
IF rtResetPropValve.Q THEN
    gxResetPropValve := TRUE;
    GVL_SCADA_in_Reset_PropValve := FALSE;
END_IF;

(* Обработка команды сброса ошибок электромагнитного клапана *)
rtResetEMValve(CLK := GVL_SCADA_in_Reset_EMValve);
IF rtResetEMValve.Q THEN
    gxResetEMValve := TRUE;
    GVL_SCADA_in_Reset_EMValve := FALSE;
END_IF;

(* Обработка команды сброса ошибок насоса 1 *)
rtResetPump1(CLK := GVL_SCADA_in_Reset_Pump1);
IF rtResetPump1.Q THEN
    gxResetPump1 := TRUE;
    GVL_SCADA_in_Reset_Pump1 := FALSE;
END_IF;

(* Обработка команды сброса ошибок насоса 2 *)
rtResetPump2(CLK := GVL_SCADA_in_Reset_Pump2);
IF rtResetPump2.Q THEN
    gxResetPump2 := TRUE;
    GVL_SCADA_in_Reset_Pump2 := FALSE;
END_IF;

(* Обработка команды сброса ошибок нагревателя *)
rtResetHeater(CLK := GVL_SCADA_in_Reset_Heater);
IF rtResetHeater.Q THEN
    gxResetHeater := TRUE;
    GVL_SCADA_in_Reset_Heater := FALSE;
END_IF;

(* Обработка команды запуска нормального останова *)
rtStartNormalShutdown(CLK := GVL_SCADA_in_StartNormalShutdown);
IF rtStartNormalShutdown.Q THEN
    gxStartNormalShutdown := TRUE;
    GVL_SCADA_in_StartNormalShutdown := FALSE;
END_IF;

(* Обработка команды запуска аварийного останова *)
rtStartEmergencyShutdown(CLK := GVL_SCADA_in_StartEmergencyShutdown);
IF rtStartEmergencyShutdown.Q THEN
    gxStartEmergencyShutdown := TRUE;
    GVL_SCADA_in_StartEmergencyShutdown := FALSE;
END_IF;

(* ======================================================================== *)
(* Получение состояния оборудования                                         *)
(* ======================================================================== *)

(* Получение данных о состоянии насосов (через ПЧ) *)
(* Примечание: Это заглушки, которые нужно заменить на реальные данные *)
bPump1Running := FALSE; (* TODO: Получить реальное состояние насоса 1 *)
bPump2Running := FALSE; (* TODO: Получить реальное состояние насоса 2 *)
rPump1Speed := 0.0;     (* TODO: Получить реальную скорость насоса 1 *)
rPump2Speed := 0.0;     (* TODO: Получить реальную скорость насоса 2 *)

(* Получение данных о состоянии нагревателя (через ТРМ10) *)
bHeaterOn := FALSE;     (* TODO: Получить реальное состояние нагревателя *)
rHeaterPower := 0.0;    (* TODO: Получить реальную мощность нагревателя *)
rTemperature := 0.0;    (* TODO: Получить реальную температуру *)

(* ======================================================================== *)
(* Сбор состояний ошибок устройств                                          *)
(* ======================================================================== *)

(* Ошибка датчика давления КИЕ2 *)
gaBlockingErrors[1].bActive := GVL_stPressureKIE2.eStatus = STATUS_VALUE_ABOVE_MAX OR 
                                NOT GVL_stPressureKIE2.bValid;
gaBlockingErrors[1].wErrorCode := GVL_stPressureKIE2.wErrorCode;

(* Ошибка датчика давления в трубопроводе *)
gaBlockingErrors[2].bActive := GVL_stPressurePipe.eStatus = STATUS_VALUE_ABOVE_MAX OR 
                                NOT GVL_stPressurePipe.bValid;
gaBlockingErrors[2].wErrorCode := GVL_stPressurePipe.wErrorCode;

(* Ошибка гидростатического датчика уровня *)
gaBlockingErrors[3].bActive := NOT GVL_stHydroLevel_KIE1.bValid;
gaBlockingErrors[3].wErrorCode := GVL_stHydroLevel_KIE1.wErrorCode;

(* Ошибка поплавковых датчиков уровня *)
gaBlockingErrors[4].bActive := NOT GVL_stFloatLevelSensors.bValid;
gaBlockingErrors[4].wErrorCode := GVL_stFloatLevelSensors.wErrorCode;

(* Ошибка расходомера после насоса 1 *)
gaBlockingErrors[5].bActive := NOT GVL_stFlowSensor_PumpOut1.bValid;
gaBlockingErrors[5].wErrorCode := GVL_stFlowSensor_PumpOut1.wErrorCode;

(* Ошибка расходомера после насоса 2 *)
gaBlockingErrors[6].bActive := NOT GVL_stFlowSensor_PumpOut2.bValid;
gaBlockingErrors[6].wErrorCode := GVL_stFlowSensor_PumpOut2.wErrorCode;

(* Ошибка пропорционального клапана *)
gaBlockingErrors[7].bActive := stPropValve.wErrorCode <> 0;
gaBlockingErrors[7].wErrorCode := stPropValve.wErrorCode;

(* Ошибка электромагнитного клапана *)
gaBlockingErrors[8].bActive := stEMValve.eState = LONG_OPERATION;
gaBlockingErrors[8].wErrorCode := 16#0001; (* Код ошибки для длительной работы соленоида *)

(* Ошибка насоса 1 (ПЧ) *)
gaBlockingErrors[9].bActive := FALSE; (* TODO: Обработка ошибок ПЧ1 *)
gaBlockingErrors[9].wErrorCode := 0;

(* Ошибка насоса 2 (ПЧ) *)
gaBlockingErrors[10].bActive := FALSE; (* TODO: Обработка ошибок ПЧ2 *)
gaBlockingErrors[10].wErrorCode := 0;

(* Ошибка нагревателя (ТЭН/ТРМ10) *)
gaBlockingErrors[11].bActive := FALSE; (* TODO: Обработка ошибок нагревателя *)
gaBlockingErrors[11].wErrorCode := 0;

(* Ошибка связи *)
gaBlockingErrors[12].bActive := FALSE; (* TODO: Обработка ошибок связи *)
gaBlockingErrors[12].wErrorCode := 0;

(* Ошибка технологического процесса (пример логики) *)
gaBlockingErrors[13].bActive := FALSE; (* TODO: Обработка ошибок технологического процесса *)
gaBlockingErrors[13].wErrorCode := 0;

(* ======================================================================== *)
(* Обработка диагностических сценариев                                      *)
(* ======================================================================== *)

(* Вызов блока диагностических сценариев *)
fbDiagnosticScenario(
    (* Состояние насосов *)
    bPump1Running := bPump1Running,
    bPump2Running := bPump2Running,
    rPump1Speed := rPump1Speed,
    rPump2Speed := rPump2Speed,
    
    (* Состояние клапанов *)
    rPropValvePosition := stPropValve.rActualPosition,
    bEMValveOpen := stEMValve.bIsOpen,
    
    (* Состояние нагревателя *)
    bHeaterOn := bHeaterOn,
    rHeaterPower := rHeaterPower,
    
    (* Сигналы с датчиков давления *)
    rPressureKIE2 := GVL_stPressureKIE2.rPressureKPa,
    bPressureKIE2Valid := GVL_stPressureKIE2.bValid,
    
    rPressurePipe := GVL_stPressurePipe.rPressureKPa,
    bPressurePipeValid := GVL_stPressurePipe.bValid,
    
    rPressurePumpIn1 := GVL_stPressurePumpIn1.rPressureKPa,
    bPressurePumpIn1Valid := GVL_stPressurePumpIn1.bValid,
    
    rPressurePumpOut1 := GVL_stPressurePumpOut1.rPressureKPa,
    bPressurePumpOut1Valid := GVL_stPressurePumpOut1.bValid,
    
    rPressurePumpIn2 := GVL_stPressurePumpIn2.rPressureKPa,
    bPressurePumpIn2Valid := GVL_stPressurePumpIn2.bValid,
    
    rPressurePumpOut2 := GVL_stPressurePumpOut2.rPressureKPa,
    bPressurePumpOut2Valid := GVL_stPressurePumpOut2.bValid,
    
    (* Сигналы с расходомеров *)
    rFlowPumpOut1 := GVL_stFlowSensor_PumpOut1.rFlowLPM,
    bFlowPumpOut1Valid := GVL_stFlowSensor_PumpOut1.bValid,
    
    rFlowPumpOut2 := GVL_stFlowSensor_PumpOut2.rFlowLPM,
    bFlowPumpOut2Valid := GVL_stFlowSensor_PumpOut2.bValid,
    
    rFlowPipe := GVL_stFlowSensor_Pipe.rFlowLPM,
    bFlowPipeValid := GVL_stFlowSensor_Pipe.bValid,
    
    (* Сигналы с датчиков уровня *)
    rLevelKIE1 := GVL_stHydroLevel_KIE1.rLevelMM,
    bLevelKIE1Valid := GVL_stHydroLevel_KIE1.bValid,
    
    bLevelLow := GVL_stFloatLevelSensors.bLowLevelActive,
    bLevelMid := GVL_stFloatLevelSensors.bMidLevelActive,
    bLevelHigh := GVL_stFloatLevelSensors.bHighLevelActive,
    bLevelValid := GVL_stFloatLevelSensors.bValid,
    
    (* Температура *)
    rTemperature := rTemperature,
    bTemperatureValid := TRUE, (* TODO: Проверка валидности температуры *)
    
    (* Управление *)
    bReset := gxResetAll,
    bEnable := TRUE,
    
    (* Выходы *)
    bAnyScenarioActive => gxAnyScenarioActive,
    bBlockingRequired => gxAnyScenarioBlockingRequired,
    bShutdownRequired => gxAnyScenarioShutdownRequired,
    uiActiveScenarioCount => ,
    uiLastActiveScenarioIndex => giLastActiveScenarioIndex,
    dwActiveScenariosMask => gdwActiveScenariosMask
);

(* ======================================================================== *)
(* Обработка ошибок и блокировок                                            *)
(* ======================================================================== *)

(* Вызов менеджера ошибок *)
fbErrorManager(
    bResetAll := gxResetAll,
    bResetMeasurement := gxResetMeasurement,
    bResetPropValve := gxResetPropValve,
    bResetEMValve := gxResetEMValve,
    bResetPump1 := gxResetPump1,
    bResetPump2 := gxResetPump2,
    bAnyError => gxAnyError,
    bSystemBlocking => gxSystemBlocking,
    eLampMode => geLampMode,
    dwActiveErrorMask => gdwActiveErrorMask,
    bPropValveBlocking => gxPropValveBlocking,
    bEMValveBlocking => gxEMValveBlocking,
    bPump1Blocking => gxPump1Blocking,
    bPump2Blocking => gxPump2Blocking
);

(* ======================================================================== *)
(* Управление состоянием системы                                            *)
(* ======================================================================== *)

(* Вызов менеджера системы *)
fbSystemManager(
    bSystemInitialized := bInitialized,
    bAnyError := gxAnyError,
    bAnyScenarioActive := gxAnyScenarioActive,
    bAnyBlockingRequired := gxAnyError OR gxAnyScenarioBlockingRequired,
    bAnyShutdownRequired := gxAnyScenarioShutdownRequired,
    bShutdownInProgress := gstShutdownSequence.bInProgress,
    bShutdownCompleted := gstShutdownSequence.bCompleted,
    bShutdownError := gstShutdownSequence.bError,
    bResetSystem := gxResetAll,
    bStartNormalShutdown := gxStartNormalShutdown,
    bStartEmergencyShutdown := gxStartEmergencyShutdown,
    eSystemState => geSystemState,
    bSystemBlockingRequired => gxSystemBlockingRequired,
    bSystemShutdownRequired => gxSystemShutdownRequired,
    bSystemResetRequired => gxSystemResetRequired
);

(* ======================================================================== *)
(* Обработка последовательности останова                                    *)
(* ======================================================================== *)

(* Вызов секвенсора останова *)
fbShutdownSequencer(
    stSequence := gstShutdownSequence,
    bStartNormal := gxStartNormalShutdown,
    bStartEmergency := gxStartEmergencyShutdown OR gxSystemShutdownRequired,
    bReset := gxResetAll,
    bHeaterOn := bHeaterOn,
    rPump1Speed := rPump1Speed,
    rPump2Speed := rPump2Speed,
    rPropValvePosition := stPropValve.rActualPosition,
    bEMValveOpen := stEMValve.bIsOpen,
    bHeaterOff => ,
    rPump1SpeedSetpoint => ,
    rPump2SpeedSetpoint => ,
    bPump1Stop => ,
    bPump2Stop => ,
    rPropValveSetpoint => ,
    bEMValveClose => 
);

(* ======================================================================== *)
(* Управление сигнальной лампой                                             *)
(* ======================================================================== *)

(* Вызов контроллера лампы *)
fbLampController(
    eMode := geLampMode,
    bEnable := TRUE,
    bOutput => gxLampState
);

(* Вывод сигнала на лампу *)
DO_Alarm_Lamp := gxLampState;

(* ======================================================================== *)
(* Сброс команд управления                                                  *)
(* ======================================================================== *)

(* Сброс флагов команд *)
gxResetAll := FALSE;
gxResetMeasurement := FALSE;
gxResetPropValve := FALSE;
gxResetEMValve := FALSE;
gxResetPump1 := FALSE;
gxResetPump2 := FALSE;
gxResetHeater := FALSE;
gxStartNormalShutdown := FALSE;
gxStartEmergencyShutdown := FALSE;

(* ======================================================================== *)
(* Обмен данными со SCADA                                                   *)
(* ======================================================================== *)

(* Передача информации в SCADA *)
GVL_SCADA_out_AnyError := gxAnyError;
GVL_SCADA_out_SystemBlocking := gxSystemBlocking;
GVL_SCADA_out_LampState := gxLampState;
GVL_SCADA_out_LampMode := ENUM_TO_DINT(geLampMode);
GVL_SCADA_out_ErrorMask := gdwActiveErrorMask;
GVL_SCADA_out_ActiveScenariosMask := gdwActiveScenariosMask;
GVL_SCADA_out_SystemState := ENUM_TO_DINT(geSystemState);
GVL_SCADA_out_ShutdownInProgress := gstShutdownSequence.bInProgress;
GVL_SCADA_out_ShutdownStep := ENUM_TO_DINT(gstShutdownSequence.eCurrentStep);

(* Передача состояния блокировок *)
GVL_SCADA_out_PropValveBlocking := gxPropValveBlocking;
GVL_SCADA_out_EMValveBlocking := gxEMValveBlocking;
GVL_SCADA_out_Pump1Blocking := gxPump1Blocking;
GVL_SCADA_out_Pump2Blocking := gxPump2Blocking;
GVL_SCADA_out_HeaterBlocking := gxHeaterBlocking;