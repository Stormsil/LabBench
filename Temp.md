(*========================================================================
    ��������:    ���� ������ ��� ������� ���������� �ͽ��
    �����:       
    ����:        2025-01-27
    ������:      1.0
    ��������:    ������������ � ��������� ��� ı ���������� �ͽ��
========================================================================*)

(* ������������ ������� ������ �ͽ� *)
TYPE E_HeaterMode :
(
    HEATER_MODE_OOS := 0,        (* Out of Service - ������� �� ������������ *)
    HEATER_MODE_STOP := 1,       (* ���������� *)
    HEATER_MODE_MANUAL := 2,     (* ������ ����� *)
    HEATER_MODE_AUTO := 3        (* �������������� ����� *)
);
END_TYPE

(* ������������ ������� ���10 *)
TYPE E_TRM10Mode :
(
    TRM10_STOP := 0,    (* ����� STOP *)
    TRM10_RUN := 1,     (* ����� RUN *)
    TRM10_MANUAL := 2   (* ����� MANUAL *)
);
END_TYPE

(* ������������ ��������� ������ ��������� *)
TYPE E_HeaterState :
(
    STATE_INIT := 0,
    STATE_OUT_OF_SERVICE := 1,
    STATE_READY := 2,
    STATE_STOP := 3,
    STATE_MANUAL := 4,
    STATE_AUTO := 5,
    STATE_AUTOTUNE := 6,
    STATE_ERROR := 7
);
END_TYPE

(* ������������ ������ *)
TYPE E_HeaterError :
(
    HEATER_NO_ERROR := 0,
    HEATER_ERR_COMM_TIMEOUT := 1,      (* ������ ����� � ���10 *)
    HEATER_ERR_SENSOR_FAULT := 2,      (* ������ ������� ����������� *)
    HEATER_ERR_OVERTEMP := 3,          (* �������� *)
    HEATER_ERR_LOOP_BREAK := 4,        (* ����� ������� *)
    HEATER_ERR_TRM10_FAULT := 5,       (* ���������� ������ ���10 *)
    HEATER_ERR_AUTOTUNE_FAIL := 6,     (* ������ ������������� *)
    HEATER_ERR_INVALID_MODE := 7,      (* ������������ ����� ������ *)
    HEATER_ERR_INTERLOCK := 8          (* ������� ���������� ������������ *)
);
END_TYPE

(* ��������� �������� ��� *)
TYPE ST_PIDSettings :
STRUCT
    rP : REAL := 10.0;              (* ������ ������������������ *)
    iI : INT := 100;                (* ������������ ����������, ��� *)
    iD : INT := 25;                 (* ���������������� ����������, ��� *)
    iPeriod : INT := 2;             (* ������ ���������, ��� *)
    rDeadBand : REAL := 0.5;        (* ���� ������������������ *)
    rOutMin : REAL := 0.0;          (* ����������� ��������, % *)
    rOutMax : REAL := 100.0;        (* ������������ ��������, % *)
    rOutRate : REAL := 10.0;        (* �������� ��������� ��������, %/� *)
    rErrorPower : REAL := 0.0;      (* �������� � ������ ������, % *)
    rStopPower : REAL := 0.0;       (* �������� � ������ ����, % *)
END_STRUCT
END_TYPE

(* ��������� ����������� *)
TYPE ST_HeaterLimits :
STRUCT
    rMaxTemp : REAL := 40.0;        (* ������������ ����������� *)
    rMinSetpoint : REAL := 0.0;     (* ����������� ������� *)
    rMaxSetpoint : REAL := 40.0;    (* ������������ ������� *)
    rMaxPower : REAL := 100.0;      (* ������������ �������� *)
    iLBATime : INT := 300;          (* ����� ����������� ������ �������, ��� *)
    rLBABand : REAL := 5.0;         (* ���� ����������� ������ *)
    rSetpointBand : REAL := 1.0;    (* ���� ���������� ������� *)
END_STRUCT
END_TYPE

(* ��������� ������� �ͽ� *)
TYPE ST_HeaterStatus :
STRUCT
    xOutOfService : BOOL;           (* ������� �� ������������ *)
    xEnabled : BOOL;                (* �������� *)
    xRunning : BOOL;                (* � ������ *)
    eMode : E_HeaterMode;           (* ������� ����� *)
    eState : E_HeaterState;         (* ������� ��������� *)
    rTemperature : REAL;            (* ����������� *)
    rSetpoint : REAL;               (* ������� *)
    rPower : REAL;                  (* �������� *)
    xAtSetpoint : BOOL;             (* ���������� ������� *)
    xAutotuning : BOOL;             (* ���� ������������� *)
    xAutotuneDone : BOOL;           (* ������������� ��������� *)
    tStateTime : TIME;              (* ����� � ������� ��������� *)
END_STRUCT
END_TYPE

(* ��������� ����������� *)
TYPE ST_HeaterDiag :
STRUCT
    xCommOK : BOOL;                 (* ����� � ����� *)
    iCommErrors : INT;              (* ������� ������ ����� *)
    wTRM10Status : WORD;            (* ������ ���10 *)
    eLastError : E_HeaterError;     (* ��������� ������ *)
    sErrorText : STRING(80);        (* ����� ������ *)
    dtLastError : DATE_AND_TIME;    (* ����� ��������� ������ *)
    dwRunCount : DWORD;             (* ������� ��������� *)
    tTotalRunTime : TIME;           (* ����� ����� ������ *)
    tLastRunTime : TIME;            (* ����� ���������� ������� *)
END_STRUCT
END_TYPE

(* ��������� ������� ���10 *)
TYPE ST_TRM10Status :
STRUCT
    (* ����������� ����� �������� ������� *)
    xSensorError : BOOL;            (* ��� 0: ������ ������� *)
    xFunctionError : BOOL;          (* ��� 2: ������ ������� *)
    xInternalError : BOOL;          (* ��� 4: ���������� ������ *)
    xManualMode : BOOL;             (* ��� 7: ������ ����� *)
    xStopMode : BOOL;               (* ��� 8: ����� ���� *)
    xLoopBreak : BOOL;              (* ��� 9: ����� ������� *)
    xAutotuning : BOOL;             (* ��� 11: ���� ������������� *)
    xAutotuneDone : BOOL;           (* ��� 12: ������������� ��������� *)
    
    (* ������� ��������� *)
    rTemperature : REAL;            (* ���������� ����������� *)
    rSetpoint : REAL;               (* ������� ������� *)
    rPower : REAL;                  (* �������� �������� *)
    eMode : E_TRM10Mode;            (* ����� ������ *)
    
    (* ��������� ��� *)
    rCurrentP : REAL;               (* ������� ������ ������������������ *)
    iCurrentI : INT;                (* ������� ������������ ���������� *)
    iCurrentD : INT;                (* ������� ���������������� ���������� *)
END_STRUCT
END_TYPE

(* ��������� ������ ��� ���10 *)
TYPE ST_TRM10Command :
STRUCT
    xEnable : BOOL;                 (* ���������� ������ *)
    eMode : E_TRM10Mode;            (* ��������� ����� *)
    rSetpoint : REAL;               (* ������� *)
    rManualPower : REAL;            (* ������ �������� *)
    xStartAutotune : BOOL;          (* ������ ������������� *)
    xReset : BOOL;                  (* ����� ������� *)
    stPID : ST_PIDSettings;         (* ��������� ��� *)
END_STRUCT
END_TYPE