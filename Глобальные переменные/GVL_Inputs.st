(*==============================================================================
    Название:    GVL_WaterSystem
    Автор:       Редько А.
    Дата:        2025-04-23
    Версия:      1.0
    
    Описание:    Глобальные переменные системы датчиков
==============================================================================*)
VAR_GLOBAL
    GVL_stHydroLevel_KIE1: 		ST_HydroLevel_Data;     	(* Структура гидростатического датчика уровня в емкости КИЕ1 *)
    GVL_stPressureKIE2: 		ST_PressureSensor_Data;		(* Структура датчика давления в емкости КИЕ2 *)
    GVL_stPressurePipe: 		ST_PressureSensor_Data;   	(* Структура датчика давления в трубопроводе *)
    GVL_stPressurePumpIn1:		ST_PressureSensor_Data;  	(* Структура датчика давления перед насосом 1 *)
    GVL_stPressurePumpOut1:     ST_PressureSensor_Data;  	(* Структура датчика давления после насоса 1 *)
    GVL_stPressurePumpIn2: 		ST_PressureSensor_Data;  	(* Структура датчика давления перед насосом 2 *)
    GVL_stPressurePumpOut2: 	ST_PressureSensor_Data;  	(* Структура датчика давления после насоса 2 *)
END_VAR
