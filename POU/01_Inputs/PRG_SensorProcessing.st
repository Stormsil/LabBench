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
    fbPressure_KIE2: FB_PressureSensor;        		(* Датчик в емкости КИЕ2 (0-250 кПа) *)
    fbPressure_Pipe: FB_PressureSensor;        		(* Датчик в трубопроводе (0-400 кПа) *)
    fbPressure_PumpIn1: FB_PressureSensor;    	(* Датчик перед насосом 1 ((-100)-400 кПа) *)
    fbPressure_PumpOut1: FB_PressureSensor;    	(* Датчик после насоса 1 ((-100)-400 кПа) *)
    fbPressure_PumpIn2: FB_PressureSensor;     	(* Датчик перед насосом 2 ((-100)-400 кПа) *)
    fbPressure_PumpOut2: FB_PressureSensor;    	(* Датчик после насоса 2 ((-100)-400 кПа) *)

    (* Датчик уровня *)
    fbLevel_KIE1: FB_HydroLevelSensor;         (* Гидростатический датчик в емкости КИЕ1 *)
    
    (* Служебные переменные *)
    bResetErrors: BOOL;                        (* Сброс ошибок всех датчиков *)
END_VAR


(* ======================================================================== *)
(* Основная логика программы                                                *)
(* ======================================================================== *)

(* Обработка сигнала с гидростатического датчика уровня в КИЕ1 *)
fbLevel_KIE1(
    rPressurePa := AI_Pressure_KIE1,           (* Давление в Па (с аналогового входа) *)
    rMaxAllowedLevelMM := 500.0,               (* Максимально допустимый уровень 500 мм *)
    rDensity := 1000.0,                        (* Плотность воды 1000 кг/м? *)
    rGravity := 9.81,                          (* Ускорение свободного падения 9.81 м/с? *)
    rLevelOffset := -1.0,                      (* Коррекция положения датчика -1 мм *)
    bEnable := TRUE,
    bReset := bResetErrors,
    stData => GVL_stHydroLevel_KIE1            (* Результаты в глобальной переменной *)
);

(* Обработка сигнала с датчика давления в КИЕ2 *)
fbPressure_KIE2(
    rPressureKPa := AI_Pressure_KIE2,          (* Давление в кПа (с аналогового входа) *)
    rMaxPressureKPa := 200.0,                  (* Максимально допустимое давление 200 кПа *)
    bEnable := TRUE,
    bReset := bResetErrors,
    stData => GVL_stPressureKIE2               (* Результаты в глобальной переменной *)
);

(* Обработка сигнала с датчика давления в трубопроводе *)
fbPressure_Pipe(
    rPressureKPa := AI_Pressure_Pipe,          (* Давление в кПа (с аналогового входа) *)
    rMaxPressureKPa := 380.0,                  (* Максимально допустимое давление 380 кПа *)
    bEnable := TRUE,
    bReset := bResetErrors,
    stData => GVL_stPressurePipe               (* Результаты в глобальной переменной *)
);

(* Обработка сигнала с датчика давления перед насосом 1 *)
fbPressure_PumpIn1(
    rPressureKPa := AI_Pressure_PumpIn1,       (* Давление в кПа (с аналогового входа) *)
    rMaxPressureKPa := 380.0,                  (* Максимально допустимое давление 380 кПа *)
    bEnable := TRUE,
    bReset := bResetErrors,
    stData => GVL_stPressurePumpIn1            (* Результаты в глобальной переменной *)
);

(* Обработка сигнала с датчика давления после насоса 1 *)
fbPressure_PumpOut1(
    rPressureKPa := AI_Pressure_PumpOut1,      (* Давление в кПа (с аналогового входа) *)
    rMaxPressureKPa := 380.0,                  (* Максимально допустимое давление 380 кПа *)
    bEnable := TRUE,
    bReset := bResetErrors,
    stData => GVL_stPressurePumpOut1           (* Результаты в глобальной переменной *)
);

(* Обработка сигнала с датчика давления перед насосом 2 *)
fbPressure_PumpIn2(                            (* Исправлено имя экземпляра ФБ *)
    rPressureKPa := AI_Pressure_PumpIn2,       (* Исправлено имя входной переменной *)
    rMaxPressureKPa := 380.0,                  (* Максимально допустимое давление 380 кПа *)
    bEnable := TRUE,
    bReset := bResetErrors,
    stData => GVL_stPressurePumpIn2            (* Исправлено имя выходной переменной *)
);

(* Обработка сигнала с датчика давления после насоса 2 *)
fbPressure_PumpOut2(                           (* Исправлено имя экземпляра ФБ *)
    rPressureKPa := AI_Pressure_PumpOut2,      (* Давление в кПа (с аналогового входа) *)
    rMaxPressureKPa := 380.0,                  (* Максимально допустимое давление 380 кПа *)
    bEnable := TRUE,
    bReset := bResetErrors,
    stData => GVL_stPressurePumpOut2           (* Результаты в глобальной переменной *)
);

(* Сброс флага управления *)
bResetErrors := FALSE;