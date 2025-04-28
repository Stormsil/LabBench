(*==============================================================================
    Название:    PRG_SensorProcessing
    Автор:       Редько А.
    Дата:        2025-04-25
    Версия:      1.1
    
    Описание:   Программа обработки сигналов от датчиков давления и уровня.
==============================================================================*)
PROGRAM PRG_SensorProcessing
VAR
    (* Датчики давления *)
    fbPressure_KIE2: FB_PressureSensor;        			(* Датчик в емкости КИЕ2 (0-250 кПа) *)
    fbPressure_Pipe: FB_PressureSensor;        			(* Датчик в трубопроводе (0-400 кПа) *)
    fbPressure_PumpIn1: FB_PressureSensor;    	   	 (* Датчик перед насосом 1 ((-100)-400 кПа) *)
    fbPressure_PumpOut1: FB_PressureSensor;    	   	 (* Датчик после насоса 1 ((-100)-400 кПа) *)
    fbPressure_PumpIn2: FB_PressureSensor;     	    	(* Датчик перед насосом 2 ((-100)-400 кПа) *)
    fbPressure_PumpOut2: FB_PressureSensor;    	   	 (* Датчик после насоса 2 ((-100)-400 кПа) *)

    (* Датчики уровня *)
    fbLevel_KIE1: FB_HydroLevelSensor;              (* Гидростатический датчик в емкости КИЕ1 *)
    fbFloatLevelSensors: FB_FloatLevelSensorGroup;  (* Группа поплавковых датчиков уровня *)

    (* Датчики расхода *)
    fbFlowSensor_PumpOut1: FB_FlowSensor;         (* Расходомер после насоса 1 *)
    fbFlowSensor_PumpOut2: FB_FlowSensor;         (* Расходомер после насоса 2 *)
    fbFlowSensor_Pipe: FB_FlowSensor;             (* ЭМ расходомер в трубопроводе *)
    
    (* Служебные переменные *)
    bResetErrors: BOOL;                        (* Сброс ошибок всех датчиков *)
END_VAR


(* ======================================================================== *)
(* Основная логика программы                                                *)
(* ======================================================================== *)

(* Обработка сигнала с гидростатического датчика уровня в КИЕ1 *)
fbLevel_KIE1(
    rPressurePa := AI_Pressure_KIE1,           	(* Давление в Па (с аналогового входа) *)
    rMaxAllowedLevelMM := 500.0,               	(* Максимально допустимый уровень 500 мм *)
    rDensity := 1000.0,                        			(* Плотность воды 1000 кг/м? *)
    rGravity := 9.81,                          				(* Ускорение свободного падения 9.81 м/с? *)
    rLevelOffset := -1.0,                      			(* Коррекция положения датчика -1 мм *)
    bEnable := TRUE,
    bReset := GVL_SCADA_in_Level_Reset,
    stData => GVL_stHydroLevel_KIE1            (* Результаты в глобальную структуру *)
);

(* Обработка сигналов с поплавковых датчиков в емкости *)
fbFloatLevelSensors(
    bLowLevelSensor := DI_Level_Low,    (* Сигнал с нижнего датчика (150 мм) *)
    bMidLevelSensor := DI_Level_Mid,    (* Сигнал со среднего датчика (250 мм) *)
    bHighLevelSensor := DI_Level_Hight, (* Сигнал с верхнего датчика (350 мм) *)
    rTankHeightMM := 500.0,             (* Высота емкости 500 мм *)
    bEnable := TRUE,
    bReset := GVL_SCADA_in_Level_Reset,
    stData => GVL_stFloatLevelSensors   (* Результаты в глобальной переменной *)
);

(* Обработка сигнала с датчика давления в КИЕ2 *)
fbPressure_KIE2(
    rPressureKPa := AI_Pressure_KIE2,          (* Давление в кПа (с аналогового входа) *)
    rMaxPressureKPa := 200.0,                 		(* Максимально допустимое давление 200 кПа *)
    bEnable := TRUE,
    bReset := GVL_SCADA_in_Pressure_Reset,
    stData => GVL_stPressureKIE2			(* Результаты в глобальную структуру *)
);

(* Обработка сигнала с датчика давления в трубопроводе *)
fbPressure_Pipe(
    rPressureKPa := AI_Pressure_Pipe,          	(* Давление в кПа (с аналогового входа) *)
    rMaxPressureKPa := 300.0,                  		(* Максимально допустимое давление 300 кПа *)
    bEnable := TRUE,
    bReset := GVL_SCADA_in_Pressure_Reset,
    stData => GVL_stPressurePipe               	(* Результаты в глобальную структуру *)
);

(* Обработка сигнала с датчика давления перед насосом 1 *)
fbPressure_PumpIn1(
    rPressureKPa := AI_Pressure_PumpIn1,       	(* Давление в кПа (с аналогового входа) *)
    rMaxPressureKPa := 250.0,                  			(* Максимально допустимое давление 250 кПа *)
    bEnable := TRUE,
    bReset := GVL_SCADA_in_Pressure_Reset,
    stData => GVL_stPressurePumpIn1            	(* Результаты в глобальную структуру *)
);

(* Обработка сигнала с датчика давления после насоса 1 *)
fbPressure_PumpOut1(
    rPressureKPa := AI_Pressure_PumpOut1,      (* Давление в кПа (с аналогового входа) *)
    rMaxPressureKPa := 250.0,                  (* Максимально допустимое давление 250 кПа *)
    bEnable := TRUE,
    bReset := GVL_SCADA_in_Pressure_Reset,
    stData => GVL_stPressurePumpOut1           (* Результаты в глобальной переменной *)
);

(* Обработка сигнала с датчика давления перед насосом 2 *)
fbPressure_PumpIn2(                            (* Исправлено имя экземпляра ФБ *)
    rPressureKPa := AI_Pressure_PumpIn2,       (* Исправлено имя входной переменной *)
    rMaxPressureKPa := 250.0,                  (* Максимально допустимое давление 250 кПа *)
    bEnable := TRUE,
    bReset := GVL_SCADA_in_Pressure_Reset,
    stData => GVL_stPressurePumpIn2            (* Исправлено имя выходной переменной *)
);

(* Обработка сигнала с датчика давления после насоса 2 *)
fbPressure_PumpOut2(                           (* Исправлено имя экземпляра ФБ *)
    rPressureKPa := AI_Pressure_PumpOut2,      (* Давление в кПа (с аналогового входа) *)
    rMaxPressureKPa := 250.0,                  (* Максимально допустимое давление 250 кПа *)
    bEnable := TRUE,
    bReset := GVL_SCADA_in_Pressure_Reset,
    stData => GVL_stPressurePumpOut2           (* Результаты в глобальной переменной *)
);

(* Обработка сигнала с расходомера после насоса 1 *)
fbFlowSensor_PumpOut1(
    wPulseCounter := Counter_Flowmeter_PumpOut1,  (* Счетчик импульсов *)
    rPulsePerLiter := 64.8,                       (* 64.8 импульса на литр (1.08 Гц на 1 л/мин) *)
    tSampleTime := T#500MS,                       (* Период измерения *)
    bEnable := TRUE,
    bReset := GVL_SCADA_in_Flow_Reset,
    stData => GVL_stFlowSensor_PumpOut1           (* Результаты *)
);

(* Обработка сигнала с расходомера после насоса 2 *)
fbFlowSensor_PumpOut2(
    wPulseCounter := Counter_Flowmeter_PumpOut2,  (* Счетчик импульсов *)
    rPulsePerLiter := 64.8,                       (* 64.8 импульса на литр (1.08 Гц на 1 л/мин) *)
    tSampleTime := T#500MS,                       (* Период измерения *)
    bEnable := TRUE,
    bReset := GVL_SCADA_in_Flow_Reset,
    stData => GVL_stFlowSensor_PumpOut2           (* Результаты *)
);

(* Обработка сигнала с ЭМ расходомера в трубопроводе *)
fbFlowSensor_Pipe(
    wPulseCounter := Counter_Flowmeter_Pipe,      (* Счетчик импульсов *)
    rPulsePerLiter := 125.0,                      (* 125 импульсов на литр *)
    tSampleTime := T#500MS,                       (* Период измерения *)
    bEnable := TRUE,
    bReset := GVL_SCADA_in_Flow_Reset,
    stData => GVL_stFlowSensor_Pipe               (* Результаты *)
);


(* Сброс флага управления *)
bResetErrors := FALSE;