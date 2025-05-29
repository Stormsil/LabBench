(*========================================================================
    ��������:    FB_HeaterInterlocks
    �����:       
    ����:        2025-01-27
    ������:      1.0
    ��������:    �������������� ���� �������� ���������� ������������ �ͽ�
========================================================================*)

FUNCTION_BLOCK FB_HeaterInterlocks
VAR_INPUT
    xEnable : BOOL;                 (* ���������� �������� ���������� *)
    rTemperature : REAL;            (* ������� ����������� *)
    rMaxTemp : REAL;                (* ����������� ���������� ����������� *)
    xSensorFault : BOOL;            (* ������ ������� ����������� *)
    xLoopBreak : BOOL;              (* ����� ������� ������������� *)
    xCommFault : BOOL;              (* ������ ����� � ���10 *)
    xInternalError : BOOL;          (* ���������� ������ ���10 *)
END_VAR

VAR_OUTPUT
    xInterlockActive : BOOL;        (* ������� ����� ���������� *)
    xOvertemp : BOOL;               (* ���������� ����������� *)
    xSensorInterlock : BOOL;        (* ���������� �� ������� *)
    xLoopInterlock : BOOL;          (* ���������� �� ������ ������� *)
    xCommInterlock : BOOL;          (* ���������� �� ����� *)
    xInternalInterlock : BOOL;      (* ���������� �� ���������� ������ *)
    wInterlockCode : WORD;          (* ������� ����� �������� ���������� *)
END_VAR

VAR
    (* ���������� ���������� *)
    xOvertempLatch : BOOL;          (* ������� ��������� *)
    rTempHysteresis : REAL := 2.0;  (* ���������� ��� ������ ��������� *)
END_VAR

(* �������� ���������� *)
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

(* �������� ���������� ����������� � ������������ *)
IF rTemperature >= rMaxTemp THEN
    xOvertempLatch := TRUE;
END_IF

IF xOvertempLatch AND (rTemperature < (rMaxTemp - rTempHysteresis)) THEN
    xOvertempLatch := FALSE;
END_IF

xOvertemp := xOvertempLatch;

(* �������� ��������� ���������� *)
xSensorInterlock := xSensorFault;
xLoopInterlock := xLoopBreak;
xCommInterlock := xCommFault;
xInternalInterlock := xInternalError;

(* ������������ ������ ����� ���������� *)
xInterlockActive := xOvertemp OR 
                   xSensorInterlock OR 
                   xLoopInterlock OR 
                   xCommInterlock OR 
                   xInternalInterlock;

(* ������������ ������� ����� *)
wInterlockCode := 0;
IF xOvertemp THEN wInterlockCode := wInterlockCode OR 16#0001; END_IF
IF xSensorInterlock THEN wInterlockCode := wInterlockCode OR 16#0002; END_IF
IF xLoopInterlock THEN wInterlockCode := wInterlockCode OR 16#0004; END_IF
IF xCommInterlock THEN wInterlockCode := wInterlockCode OR 16#0008; END_IF
IF xInternalInterlock THEN wInterlockCode := wInterlockCode OR 16#0010; END_IF