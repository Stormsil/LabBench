(*========================================================================
    Название:    FB_HeaterInterlocks
    Автор:       
    Дата:        2025-01-27
    Версия:      1.0
    Описание:    Функциональный блок проверки блокировок безопасности ТЭНа
========================================================================*)

FUNCTION_BLOCK FB_HeaterInterlocks
VAR_INPUT
    xEnable : BOOL;                 (* Разрешение проверки блокировок *)
    rTemperature : REAL;            (* Текущая температура *)
    rMaxTemp : REAL;                (* Максимально допустимая температура *)
    xSensorFault : BOOL;            (* Ошибка датчика температуры *)
    xLoopBreak : BOOL;              (* Обрыв контура регулирования *)
    xCommFault : BOOL;              (* Ошибка связи с ТРМ10 *)
    xInternalError : BOOL;          (* Внутренняя ошибка ТРМ10 *)
END_VAR

VAR_OUTPUT
    xInterlockActive : BOOL;        (* Активна любая блокировка *)
    xOvertemp : BOOL;               (* Превышение температуры *)
    xSensorInterlock : BOOL;        (* Блокировка по датчику *)
    xLoopInterlock : BOOL;          (* Блокировка по обрыву контура *)
    xCommInterlock : BOOL;          (* Блокировка по связи *)
    xInternalInterlock : BOOL;      (* Блокировка по внутренней ошибке *)
    wInterlockCode : WORD;          (* Битовая маска активных блокировок *)
END_VAR

VAR
    (* Внутренние переменные *)
    xOvertempLatch : BOOL;          (* Защелка перегрева *)
    rTempHysteresis : REAL := 2.0;  (* Гистерезис для сброса перегрева *)
END_VAR

(* Проверка разрешения *)
IF NOT xEnable THEN
    xInterlockActive := FALSE;
    xOvertemp := FALSE;
    xSensorInterlock := FALSE;
    xLoopInterlock := FALSE;
    xCommInterlock := FALSE;
    xInternalInterlock := FALSE;
    wInterlockCode := 0;
    RETURN;
END_IF

(* Проверка превышения температуры с гистерезисом *)
IF rTemperature >= rMaxTemp THEN
    xOvertempLatch := TRUE;
END_IF

IF xOvertempLatch AND (rTemperature < (rMaxTemp - rTempHysteresis)) THEN
    xOvertempLatch := FALSE;
END_IF

xOvertemp := xOvertempLatch;

(* Проверка остальных блокировок *)
xSensorInterlock := xSensorFault;
xLoopInterlock := xLoopBreak;
xCommInterlock := xCommFault;
xInternalInterlock := xInternalError;

(* Формирование общего флага блокировки *)
xInterlockActive := xOvertemp OR 
                   xSensorInterlock OR 
                   xLoopInterlock OR 
                   xCommInterlock OR 
                   xInternalInterlock;

(* Формирование битовой маски *)
wInterlockCode := 0;
IF xOvertemp THEN wInterlockCode := wInterlockCode OR 16#0001; END_IF
IF xSensorInterlock THEN wInterlockCode := wInterlockCode OR 16#0002; END_IF
IF xLoopInterlock THEN wInterlockCode := wInterlockCode OR 16#0004; END_IF
IF xCommInterlock THEN wInterlockCode := wInterlockCode OR 16#0008; END_IF
IF xInternalInterlock THEN wInterlockCode := wInterlockCode OR 16#0010; END_IF