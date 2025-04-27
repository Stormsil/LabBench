(*==============================================================================
    Название:    GVL_Inputs
    Автор:       Редько А.
    Дата:        2025-04-23
    Версия:      1.0
    
    Описание:    Глобальные переменные системы датчиков
==============================================================================*)
VAR_GLOBAL
    (* Датчики уровня *)
    GVL_stHydroLevel_KIE1: 		ST_HydroLevel_Data;     	(* Структура гидростатического датчика уровня в емкости КИЕ1 *)
    GVL_stFloatLevelSensors:    ST_FloatLevelGroup_Data;    (* Структура группы поплавковых датчиков уровня *)

    (* Датчики давления *)
    GVL_stPressureKIE2: 		ST_PressureSensor_Data;		(* Структура датчика давления в емкости КИЕ2 *)
    GVL_stPressurePipe: 		ST_PressureSensor_Data;   	(* Структура датчика давления в трубопроводе *)
    GVL_stPressurePumpIn1:		ST_PressureSensor_Data;  	(* Структура датчика давления перед насосом 1 *)
    GVL_stPressurePumpOut1:     ST_PressureSensor_Data;  	(* Структура датчика давления после насоса 1 *)
    GVL_stPressurePumpIn2: 		ST_PressureSensor_Data;  	(* Структура датчика давления перед насосом 2 *)
    GVL_stPressurePumpOut2: 	ST_PressureSensor_Data;  	(* Структура датчика давления после насоса 2 *)

    (* Датчики расхода *)
    GVL_stFlowSensor_PumpOut1: ST_FlowSensor_Data; (* Расходомер после насоса 1 *)
    GVL_stFlowSensor_PumpOut2: ST_FlowSensor_Data; (* Расходомер после насоса 2 *)
    GVL_stFlowSensor_Pipe: ST_FlowSensor_Data;     (* Расходомер в трубопроводе *)
END_VAR
