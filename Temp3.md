(*========================================================================
    ��������:    FB_HeaterRuntime
    �����:       
    ����:        2025-01-27
    ������:      1.0
    ��������:    �������������� ���� ����� ������� ������ �ͽ�
========================================================================*)

FUNCTION_BLOCK FB_HeaterRuntime
VAR_INPUT
    xEnable : BOOL;                 (* ���������� ����� *)
    xRunning : BOOL;                (* �ͽ �������� *)
    xReset : BOOL;                  (* ����� ��������� *)
END_VAR

VAR_OUTPUT
    dwRunCount : DWORD;             (* ���������� ��������� *)
    tTotalRunTime : TIME;           (* ����� ����� ������ *)
    tCurrentRunTime : TIME;         (* ����� �������� ������� *)
    tLastRunTime : TIME;            (* ����� ���������� ������� *)
END_VAR

VAR
    (* ���������� ���������� *)
    xRunningOld : BOOL;             (* ���������� ��������� *)
    tonRunTime : TON;               (* ������ ������� ������ *)
    tStartTime : TIME;              (* ����� ������ ������ *)
    tAccumulatedTime : TIME;        (* ����������� ����� *)
END_VAR

(* ����� ��������� *)
IF xReset THEN
    dwRunCount := 0;
    tTotalRunTime := T#0s;
    tCurrentRunTime := T#0s;
    tLastRunTime := T#0s;
    tAccumulatedTime := T#0s;
    xRunningOld := FALSE;
    RETURN;
END_IF

(* �������� ���������� *)
IF NOT xEnable THEN
    tonRunTime(IN := FALSE);
    tCurrentRunTime := T#0s;
    xRunningOld := FALSE;
    RETURN;
END_IF

(* �������������� ������ ��������� *)
IF xRunning AND NOT xRunningOld THEN
    (* ����� ��������� *)
    dwRunCount := dwRunCount + 1;
    tStartTime := TIME();
    tonRunTime(IN := FALSE);
    tonRunTime(IN := TRUE, PT := T#24h);
END_IF

(* �������������� ������ ���������� *)
IF NOT xRunning AND xRunningOld THEN
    (* ���������� - ��������� ����� ���������� ������� *)
    tLastRunTime := tCurrentRunTime;
    tAccumulatedTime := tAccumulatedTime + tCurrentRunTime;
    tTotalRunTime := tAccumulatedTime;
END_IF

(* ���������� �������� ������� ������ *)
IF xRunning THEN
    tonRunTime(IN := TRUE, PT := T#24h);
    tCurrentRunTime := tonRunTime.ET;
ELSE
    tonRunTime(IN := FALSE);
    tCurrentRunTime := T#0s;
END_IF

(* ���������� ������ ������� ������ *)
IF xRunning THEN
    tTotalRunTime := tAccumulatedTime + tCurrentRunTime;
END_IF

(* ���������� ����������� ��������� *)
xRunningOld := xRunning;