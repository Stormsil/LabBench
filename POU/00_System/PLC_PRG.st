
PROGRAM PLC_PRG
VAR
END_VAR

(* 1. Обработка датчиков *)
PRG_SensorProcessing();

TYPE StructName : STRUCT
        Valve1 : BOOL; (* Comment *)
         : BOOL; (* Comment *)
    END_STRUCT
END_TYPE
