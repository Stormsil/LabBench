(*========================================================================
    ��������:    FB_HeaterStateMachine
    �����:       
    ����:        2025-01-27
    ������:      1.0
    ��������:    ������ ��������� ��� ���������� �ͽ��
========================================================================*)

FUNCTION_BLOCK FB_HeaterStateMachine
VAR_INPUT
    xEnable : BOOL;                 (* ���������� ������ *)
    eCommandMode : E_HeaterMode;    (* ��������� ����� ������ *)
    xInterlockActive : BOOL;        (* ������� ���������� *)
    xCommOK : BOOL;                 (* ����� � ����� *)
    xTRM10Ready : BOOL;             (* ���10 ����� *)
    xAutotuneComplete : BOOL;       (* ������������� ��������� *)
    xAutotuneFailed : BOOL;         (* ������ ������������� *)
    xError : BOOL;                  (* ����� ������ *)
    xReset : BOOL;                  (* ����� ������ *)
END_VAR

VAR_OUTPUT
    eState : E_HeaterState;         (* ������� ��������� *)
    eMode : E_HeaterMode;           (* ������� ����� *)
    xStateChanged : BOOL;           (* ��������� ���������� *)
    tStateTime : TIME;              (* ����� � ������� ��������� *)
    xAllowRun : BOOL;               (* ���������� ������ *)
    xAllowAutotune : BOOL;          (* ���������� ������������� *)
END_VAR

VAR
    (* ���������� ���������� *)
    eStateOld : E_HeaterState;      (* ���������� ��������� *)
    tonStateTime : TON;             (* ������ ������� ��������� *)
    xInitDone : BOOL;               (* ������������� ��������� *)
END_VAR

(* ������������� ��� ������ ������ *)
IF NOT xInitDone THEN
    eState := STATE_INIT;
    eMode := HEATER_MODE_OOS;
    xInitDone := TRUE;
END_IF

(* �������������� ��������� ��������� *)
xStateChanged := (eState <> eStateOld);
IF xStateChanged THEN
    tonStateTime(IN := FALSE);
END_IF

(* ������� ������� � ������� ��������� *)
tonStateTime(IN := TRUE, PT := T#24h);
tStateTime := tonStateTime.ET;

(* ������ ��������� *)
CASE eState OF
    STATE_INIT:
        (* ������������� *)
        IF xEnable THEN
            eState := STATE_READY;
        END_IF
        
    STATE_OUT_OF_SERVICE:
        (* ������� �� ������������ *)
        eMode := HEATER_MODE_OOS;
        xAllowRun := FALSE;
        xAllowAutotune := FALSE;
        
        IF eCommandMode <> HEATER_MODE_OOS THEN
            eState := STATE_READY;
        END_IF
        
    STATE_READY:
        (* ����� � ������ *)
        xAllowRun := FALSE;
        xAllowAutotune := FALSE;
        
        (* �������� �������� � OOS *)
        IF eCommandMode = HEATER_MODE_OOS THEN
            eState := STATE_OUT_OF_SERVICE;
        (* �������� ������ *)
        ELSIF xError OR NOT xCommOK THEN
            eState := STATE_ERROR;
        (* �������� ���������� � ������ *)
        ELSIF xEnable AND NOT xInterlockActive THEN
            CASE eCommandMode OF
                HEATER_MODE_STOP:
                    eState := STATE_STOP;
                HEATER_MODE_MANUAL:
                    eState := STATE_MANUAL;
                HEATER_MODE_AUTO:
                    eState := STATE_AUTO;
            END_CASE
        END_IF
        
    STATE_STOP:
        (* ����� �¾� *)
        eMode := HEATER_MODE_STOP;
        xAllowRun := FALSE;
        xAllowAutotune := TRUE;
        
        (* �������� ������� �������� *)
        IF NOT xEnable THEN
            eState := STATE_READY;
        ELSIF eCommandMode = HEATER_MODE_OOS THEN
            eState := STATE_OUT_OF_SERVICE;
        ELSIF xError OR NOT xCommOK THEN
            eState := STATE_ERROR;
        ELSIF xInterlockActive THEN
            eState := STATE_ERROR;
        ELSIF eCommandMode = HEATER_MODE_MANUAL AND xTRM10Ready THEN
            eState := STATE_MANUAL;
        ELSIF eCommandMode = HEATER_MODE_AUTO AND xTRM10Ready THEN
            eState := STATE_AUTO;
        END_IF
        
    STATE_MANUAL:
        (* ������ ����� *)
        eMode := HEATER_MODE_MANUAL;
        xAllowRun := TRUE;
        xAllowAutotune := FALSE;
        
        (* �������� ������� �������� *)
        IF eCommandMode = HEATER_MODE_OOS THEN
            eState := STATE_OUT_OF_SERVICE;
        ELSIF xError OR NOT xCommOK OR xInterlockActive THEN
            eState := STATE_ERROR;
        ELSIF eCommandMode = HEATER_MODE_STOP THEN
            eState := STATE_STOP;
        ELSIF eCommandMode = HEATER_MODE_AUTO THEN
            eState := STATE_AUTO;
        END_IF
        
    STATE_AUTO:
        (* �������������� ����� *)
        eMode := HEATER_MODE_AUTO;
        xAllowRun := TRUE;
        xAllowAutotune := FALSE;
        
        (* �������� ������� �������� *)
        IF eCommandMode = HEATER_MODE_OOS THEN
            eState := STATE_OUT_OF_SERVICE;
        ELSIF xError OR NOT xCommOK OR xInterlockActive THEN
            eState := STATE_ERROR;
        ELSIF eCommandMode = HEATER_MODE_STOP THEN
            eState := STATE_STOP;
        ELSIF eCommandMode = HEATER_MODE_MANUAL THEN
            eState := STATE_MANUAL;
        END_IF
        
    STATE_AUTOTUNE:
        (* ������������� *)
        eMode := HEATER_MODE_AUTO;
        xAllowRun := TRUE;
        xAllowAutotune := TRUE;
        
        (* �������� ������� �������� *)
        IF xAutotuneComplete THEN
            eState := STATE_AUTO;
        ELSIF xAutotuneFailed THEN
            eState := STATE_STOP;
        ELSIF xError OR NOT xCommOK OR xInterlockActive THEN
            eState := STATE_ERROR;
        END_IF
        
    STATE_ERROR:
        (* ��������� ������ *)
        xAllowRun := FALSE;
        xAllowAutotune := FALSE;
        
        (* �������� ������� ������ �� ������ *)
        IF eCommandMode = HEATER_MODE_OOS THEN
            eState := STATE_OUT_OF_SERVICE;
        ELSIF xReset AND NOT xError AND xCommOK AND NOT xInterlockActive THEN
            eState := STATE_READY;
        END_IF
        
END_CASE

(* ����������� ��������� ������� ������������� *)
IF eState = STATE_STOP AND xAllowAutotune AND xEnable THEN
    (* ����� ����� �������� ������� ��� ������������� *)
    (* ����������� � ������� ı *)
END_IF

(* ���������� ����������� ��������� *)
eStateOld := eState;