(*========================================================================
    ��������:    FB_HeaterDiagnostics
    �����:       
    ����:        2025-01-27
    ������:      1.0
    ��������:    �������������� ���� ����������� ��������� �ͽ�
========================================================================*)

FUNCTION_BLOCK FB_HeaterDiagnostics
VAR_INPUT
    xEnable : BOOL;                 (* ���������� ����������� *)
    xCommOK : BOOL;                 (* ����� � ���10 � ����� *)
    wTRM10Status : WORD;            (* ������� ������� ���10 *)
    eCurrentError : E_HeaterError;  (* ������� ������ *)
    xReset : BOOL;                  (* ����� ��������� *)
END_VAR

VAR_OUTPUT
    stDiag : ST_HeaterDiag;         (* ��������� ����������� *)
END_VAR

VAR
    (* ���������� ���������� *)
    xCommOKOld : BOOL;              (* ���������� ��������� ����� *)
    eLastErrorOld : E_HeaterError;  (* ���������� ������ *)
    tonCommTimeout : TON;           (* ������ �������� ����� *)
    rtGetTime : RTC;                (* ��������� ���������� ������� *)
END_VAR

(* ����� ����������� *)
IF xReset THEN
    stDiag.iCommErrors := 0;
    stDiag.eLastError := HEATER_NO_ERROR;
    stDiag.sErrorText := '';
    RETURN;
END_IF

(* �������� ���������� *)
IF NOT xEnable THEN
    RETURN;
END_IF

(* ���������� ��������� ����� *)
stDiag.xCommOK := xCommOK;
stDiag.wTRM10Status := wTRM10Status;

(* ������� ������ ����� *)
IF NOT xCommOK AND xCommOKOld THEN
    stDiag.iCommErrors := stDiag.iCommErrors + 1;
END_IF

(* ���������� ���������� �� ������ *)
IF eCurrentError <> eLastErrorOld AND eCurrentError <> HEATER_NO_ERROR THEN
    stDiag.eLastError := eCurrentError;
    
    (* ��������� ������� ������ *)
    rtGetTime();
    stDiag.dtLastError := rtGetTime.CDT;
    
    (* ������������ ������ ������ *)
    CASE eCurrentError OF
        HEATER_NO_ERROR:
            stDiag.sErrorText := '��� ������';
            
        HEATER_ERR_COMM_TIMEOUT:
            stDiag.sErrorText := '������ ����� � ���10';
            
        HEATER_ERR_SENSOR_FAULT:
            stDiag.sErrorText := '������ ������� �����������';
            
        HEATER_ERR_OVERTEMP:
            stDiag.sErrorText := '���������� ������������ �����������!';
            
        HEATER_ERR_LOOP_BREAK:
            stDiag.sErrorText := '����� ������� �������������';
            
        HEATER_ERR_TRM10_FAULT:
            stDiag.sErrorText := '���������� ������ ���10';
            
        HEATER_ERR_AUTOTUNE_FAIL:
            stDiag.sErrorText := '������ �������������';
            
        HEATER_ERR_INVALID_MODE:
            stDiag.sErrorText := '������������ ����� ������';
            
        HEATER_ERR_INTERLOCK:
            stDiag.sErrorText := '������� ���������� ������������';
            
    ELSE
        stDiag.sErrorText := '����������� ������';
    END_CASE
END_IF

(* ���������� ���������� �������� *)
xCommOKOld := xCommOK;
eLastErrorOld := eCurrentError;