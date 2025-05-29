(*========================================================================
    ��������:    FB_TRM10_Control
    �����:       
    ����:        2025-01-27
    ������:      1.0
    ��������:    ���������� �������� ������ ���10 ����� Modbus
========================================================================*)

FUNCTION_BLOCK FB_TRM10_Control
VAR_INPUT
    xEnable : BOOL;                 (* ���������� ���������� *)
    eCommandMode : E_TRM10Mode;     (* ��������� ����� *)
    rSetpoint : REAL;               (* ������� ����������� *)
    rManualPower : REAL;            (* ������ �������� *)
    xStartAutotune : BOOL;          (* ������ ������������� *)
    xReset : BOOL;                  (* ����� ���10 *)
END_VAR

VAR_OUTPUT
    eActualMode : E_TRM10Mode;      (* ����������� ����� *)
    xModeChanged : BOOL;            (* ����� ������� *)
    xReady : BOOL;                  (* ����� � ���������� *)
END_VAR

VAR
    (* ���������� ���������� *)
    eCommandModeOld : E_TRM10Mode;  (* ���������� ������� ������ *)
    xStartAutotuneOld : BOOL;       (* ���������� ��������� ������������� *)
    xResetOld : BOOL;               (* ���������� ��������� ������ *)
    tonModeDelay : TON;             (* �������� ����� ������ *)
    iStep : INT;                    (* ��� ������������������ *)
END_VAR

(* �������� ���������� *)
IF NOT xEnable THEN
    (* ����� ���������� *)
    MB_TRM_ControlMode_WR := 0;    (* STOP *)
    MB_TRM_Autotune_WR := 0;       (* OFF *)
    xReady := FALSE;
    iStep := 0;
    RETURN;
END_IF

(* ������ �������� ������ *)
eActualMode := WORD_TO_INT(MB_TRM_ControlMode_RD);

(* ������������������ ���������� ������� *)
CASE iStep OF
    0: (* �������� ������� *)
        xReady := TRUE;
        
        (* �������� ��������� ������ *)
        IF eCommandMode <> eCommandModeOld THEN
            iStep := 10;
        END_IF
        
        (* �������� ������� ������������� *)
        IF xStartAutotune AND NOT xStartAutotuneOld THEN
            iStep := 20;
        END_IF
        
        (* �������� ������ *)
        IF xReset AND NOT xResetOld THEN
            iStep := 30;
        END_IF
        
    10: (* ��������� ������ *)
        MB_TRM_ControlMode_WR := INT_TO_WORD(eCommandMode);
        tonModeDelay(IN := TRUE, PT := T#500ms);
        
        IF tonModeDelay.Q THEN
            tonModeDelay(IN := FALSE);
            xModeChanged := TRUE;
            iStep := 0;
        END_IF
        
    20: (* ������ ������������� *)
        (* ������� ��������� � STOP *)
        IF eActualMode <> TRM10_STOP THEN
            MB_TRM_ControlMode_WR := INT_TO_WORD(TRM10_STOP);
            tonModeDelay(IN := TRUE, PT := T#500ms);
            
            IF tonModeDelay.Q THEN
                tonModeDelay(IN := FALSE);
                iStep := 21;
            END_IF
        ELSE
            iStep := 21;
        END_IF
        
    21: (* ������ ������������� �� ������ STOP *)
        MB_TRM_Autotune_WR := 1; (* RUN *)
        tonModeDelay(IN := TRUE, PT := T#500ms);
        
        IF tonModeDelay.Q THEN
            tonModeDelay(IN := FALSE);
            iStep := 0;
        END_IF
        
    30: (* ����� ������� *)
        MB_TRM_Reset_WR := 1;
        tonModeDelay(IN := TRUE, PT := T#1s);
        
        IF tonModeDelay.Q THEN
            tonModeDelay(IN := FALSE);
            MB_TRM_Reset_WR := 0;
            iStep := 0;
        END_IF
        
END_CASE

(* ������ ������� � �������� ���������� �� ���� *)
IF xEnable THEN
    (* ����������� � ������ ������� *)
    MB_TRM_Setpoint_WR := rSetpoint;
    
    (* ����������� � ������ ������ �������� *)
    IF rManualPower < 0.0 THEN
        MB_TRM_OutputPower_WR := 0.0;
    ELSIF rManualPower > 100.0 THEN
        MB_TRM_OutputPower_WR := 100.0;
    ELSE
        MB_TRM_OutputPower_WR := rManualPower;
    END_IF
END_IF

(* ����� ����� ��������� ������ *)
IF xModeChanged THEN
    xModeChanged := FALSE;
END_IF

(* ���������� ���������� �������� *)
eCommandModeOld := eCommandMode;
xStartAutotuneOld := xStartAutotune;
xResetOld := xReset;