
# ����������� � ��������� ������ "�����" (Pump)

������ �������� ��������� ����������� � ��������� ����� `Project/POU/02_Equipment/Pump` � �������� � ��� �������������� ������ (��).

## �����

������ "�����" (`Pump`) ������������� ��� ������ ����������, ����������� � ������ ��������� ������������. �������� �������������� ������ �������� `FB_Pump`, ������� ������������ ������ ������ ������������������ ��.

## ��������� ����� `Project/POU/02_Equipment/Pump`

```mermaid
graph TD
    subgraph POU/02_Equipment/Pump
        A[FB_Pump] --> B(FB_PumpControl)
        A --> C(FB_PumpDiagnostics)
        A --> D(FB_PumpModeControl)
        A --> E(FB_PumpProtection)
        A --> F(FB_PumpSequencer)

        B --> G(ST_PumpCommands)
        B --> H(ST_PumpConfig)
        B --> I(ST_PumpInterface)
        B --> J(ST_PumpProcessData)

        C --> K(ST_PumpDiagnostics)
        C --> L(E_PumpFaultClass)

        D --> M(E_PumpMode)
        D --> N(E_PumpState)

        F --> N

        subgraph ENUM
            L(E_PumpFaultClass)
            M(E_PumpMode)
            N(E_PumpState)
        end

        subgraph STRUCT
            G(ST_PumpCommands)
            H(ST_PumpConfig)
            I(ST_PumpInterface)
            J(ST_PumpProcessData)
            K(ST_PumpDiagnostics)
        end
    end
```

## �������� �������������� ������ (��)

*   **FB_Pump**: ������� �������������� ����, ������������ � �������������� ������ ���� ���-�� ��� ���������� �������.
*   **FB_PumpControl**: �������� �� ���������������� ���������� �������, ������� ������� �����/��������, ������������� �������� � �.�. ��������������� �� ����������� ������ � ������������.
*   **FB_PumpDiagnostics**: ������������ ��������������� ������ � ���������� ��������� �������������� ������. ���������� ��������� ����������� � ������������ ������� ��������������.
*   **FB_PumpModeControl**: ��������� �������� ������ ������ (��������, ������, ��������������) � ��� �����������. ���������� ������������ ������� � ���������.
*   **FB_PumpProtection**: ��������� ������ ������ ������ �� ����������, ������ ���� � ������ ��������� ��������.
*   **FB_PumpSequencer**: �������� �� ������������������ �������� ������, ��������, ��� ������� ��� ��������.

## �������� ����� ������ (ENUM � STRUCT)

### ENUM (������������)

*   **E_PumpFaultClass**: ���������� ������ �������������� ������.
*   **E_PumpMode**: ���������� ��������� ������ ������ ������.
*   **E_PumpState**: ���������� ��������� ��������� ������ (��������, "����������", "��������", "������").

### STRUCT (���������)

*   **ST_PumpCommands**: �������� ������� ����������, ���������� �� �����.
*   **ST_PumpConfig**: �������� ��������� ������������ ������.
*   **ST_PumpDiagnostics**: �������� ��������������� ������ ������.
*   **ST_PumpInterface**: ���������� ����� ��������� ��� �������������� � �������.
*   **ST_PumpProcessData**: �������� ������ ��������, ��������� � ������� ������ (��������, ������� ��������, ��������).

## ��������� �������� �������������� ������

### FB_Pump

������� �������������� ����, ������������ � �������������� ������ ���� ���-�� ��� ���������� �������.

#### ����� (VAR_INPUT)

| ��� ���������� | ��� ������ | �������� |
|---|---|---|
| i_xStart | BOOL | ������� ����� |
| i_xStop | BOOL | ������� �������� |
| i_xReset | BOOL | ����� ������ |
| i_eMode | E_PumpMode | ����� ������ |
| i_rManualSetpoint | REAL | ������ ������� �������, �� |
| i_rAutoSetpoint | REAL | �������������� ������� |
| i_rPressureInlet | REAL | �������� �� �����, ��� |
| i_rPressureOutlet | REAL | �������� �� ������, ��� |
| i_rFlow | REAL | ������, �?/� |
| i_rTemperature | REAL | �����������, �C |
| i_stFCModbus | ST_FC_ModbusInterface | ��������� Modbus �� |
| i_xExternalInterlock | BOOL | ������� ���������� |
| i_xLowLevelInterlock | BOOL | ���������� �� ������ |
| i_stConfig | ST_PumpConfig | ������������ ������ |

#### ������ (VAR_OUTPUT)

| ��� ���������� | ��� ������ | �������� |
|---|---|---|
| o_xReady | BOOL | ����� � ������ |
| o_xRunning | BOOL | �������� |
| o_xFault | BOOL | ������ |
| o_xWarning | BOOL | �������������� |
| o_eState | E_PumpState | ��������� ������ |
| o_eMode | E_PumpMode | ������� ����� |
| o_eFaultClass | E_PumpFaultClass | ����� ������ |
| o_stDiagnostics | ST_PumpDiagnostics | ����������� |
| o_stFCModbus | ST_FC_ModbusInterface | ��������� Modbus �� |
| o_stInterface | ST_PumpInterface | ������ ��������� |

#### ���������� ���������� (VAR)

| ��� ���������� | ��� ������ | �������� |
|---|---|---|
| fbPumpControl | FB_PumpControl | ���������� �������������� ���� |
| fbFrequencyConverter | FB_FrequencyConverter_AFD | ���������� �������������� ���� |
| fbPumpProtection | FB_PumpProtection | ���������� �������������� ���� |
| fbPumpDiagnostics | FB_PumpDiagnostics | ���������� �������������� ���� |
| fbPumpModeControl | FB_PumpModeControl | ���������� �������������� ���� |
| fbPumpSequencer | FB_PumpSequencer | ���������� �������������� ���� |
| stProcessData | ST_PumpProcessData | ���������� ������ |
| stCommands | ST_PumpCommands | ���������� ������ |
| stFCInterface | ST_FC_Interface | ���������� ������ |
| xFCStart | BOOL | |
| xFCInterlock | BOOL | |
| rFCSetpoint | REAL | |
| xFirstScan | BOOL | ����� |

#### ������ ������ � ��������������

```mermaid
graph TD
    subgraph FB_Pump
        direction LR
        A[i_stConfig: ST_PumpConfig] --> FB_PumpProtection
        A --> FB_PumpDiagnostics

        B[i_stFCModbus: ST_FC_ModbusInterface] --> FB_FrequencyConverter_AFD
        FB_FrequencyConverter_AFD --> C[o_stFCModbus: ST_FC_ModbusInterface]

        D[i_xExternalInterlock: BOOL] --> FB_PumpProtection
        E[i_xLowLevelInterlock: BOOL] --> FB_PumpProtection

        F[i_xStart: BOOL] --> FB_PumpControl
        F --> FB_PumpModeControl
        G[i_xStop: BOOL] --> FB_PumpControl
        H[i_xReset: BOOL] --> FB_FrequencyConverter_AFD
        I[i_eMode: E_PumpMode] --> FB_PumpControl
        I --> FB_PumpModeControl

        J[i_rManualSetpoint: REAL] --> FB_PumpModeControl
        K[i_rAutoSetpoint: REAL] --> FB_PumpModeControl

        L[i_rPressureInlet: REAL] --> FB_PumpDiagnostics
        L --> FB_PumpProtection
        M[i_rPressureOutlet: REAL] --> FB_PumpDiagnostics
        M --> FB_PumpProtection
        N[i_rFlow: REAL] --> FB_PumpDiagnostics
        N --> FB_PumpProtection
        O[i_rTemperature: REAL] --> FB_PumpDiagnostics
        O --> FB_PumpProtection

        FB_PumpControl --> P[o_xReady: BOOL]
        FB_PumpControl --> Q[o_xRunning: BOOL]
        FB_PumpControl --> R[o_xFault: BOOL]
        FB_PumpControl --> S[o_eState: E_PumpState]

        FB_PumpModeControl --> T[o_eMode: E_PumpMode]
        FB_PumpProtection --> U[o_eFaultClass: E_PumpFaultClass]
        FB_PumpDiagnostics --> V[o_stDiagnostics: ST_PumpDiagnostics]

        FB_PumpControl -- xFCStart --> FB_FrequencyConverter_AFD
        FB_PumpProtection -- xFCInterlock --> FB_FrequencyConverter_AFD
        FB_PumpModeControl -- rFCSetpoint --> FB_FrequencyConverter_AFD

        FB_FrequencyConverter_AFD -- xReady --> FB_PumpControl
        FB_FrequencyConverter_AFD -- xReady --> FB_PumpModeControl
        FB_FrequencyConverter_AFD -- xRunning --> FB_PumpControl
        FB_FrequencyConverter_AFD -- xRunning --> FB_PumpProtection
        FB_FrequencyConverter_AFD -- xFault --> FB_PumpControl
        FB_FrequencyConverter_AFD -- xFault --> FB_PumpModeControl

        FB_PumpControl -- o_eState --> FB_PumpModeControl
        FB_PumpControl -- o_xRunning --> FB_PumpDiagnostics

        FB_PumpSequencer -- o_eState --> S

        subgraph Internal Variables
            stProcessData(stProcessData: ST_PumpProcessData)
            stCommands(stCommands: ST_PumpCommands)
            xFCStart(xFCStart: BOOL)
            xFCInterlock(xFCInterlock: BOOL)
            rFCSetpoint(rFCSetpoint: REAL)
        end

        stProcessData --> FB_PumpDiagnostics
        stProcessData --> FB_PumpProtection
        stCommands --> FB_PumpControl
        stCommands --> FB_PumpModeControl
        stCommands --> FB_PumpSequencer

        L,M,N,O --> stProcessData
        F,G,H,I,J,K --> stCommands

        Q --> o_stInterface
        P --> o_stInterface
        R --> o_stInterface
        V --> o_stInterface
        S --> o_stInterface
        T --> o_stInterface
        U --> o_stInterface
        C --> o_stInterface
        B --> o_stInterface
        D --> o_stInterface
        E --> o_stInterface
        W[o_xWarning: BOOL] --> o_stInterface
        stProcessData --> o_stInterface
        stCommands --> o_stInterface
    end
```

### FB_PumpControl

�������� �� ���������������� ���������� �������, ������� ������� �����/��������, ������������� �������� � �.�. ��������������� �� ����������� ������ � ������������.

#### ����� (VAR_INPUT)

| ��� ���������� | ��� ������ | �������� |
|---|---|---|
| i_stCommands | ST_PumpCommands | ������� ���������� |
| i_eMode | E_PumpMode | ������� ����� |
| i_xInterlock | BOOL | ���������� �� ����� |
| i_xFCReady | BOOL | �� ����� |
| i_xFCRunning | BOOL | �� �������� |
| i_xFCFault | BOOL | ������ �� |

#### ������ (VAR_OUTPUT)

| ��� ���������� | ��� ������ | �������� |
|---|---|---|
| o_eState | E_PumpState | ��������� ������ |
| o_xFCStart | BOOL | ������� ����� �� |
| o_xReady | BOOL | ����� � ������ |
| o_xRunning | BOOL | �������� |
| o_xFault | BOOL | ������ |

#### ���������� ���������� (VAR)

| ��� ���������� | ��� ������ | �������� |
|---|---|---|
| eState | E_PumpState | ������ ��������� |
| eStatePrev | E_PumpState | |
| tonStateTimer | TON | ������� |
| tonStartDelay | TON | |
| tonStopDelay | TON | |
| xStartCmd | BOOL | ����� |
| xStopCmd | BOOL | |
| xStartRising | BOOL | |
| xStopRising | BOOL | |
| xStartPrev | BOOL | |
| xStopPrev | BOOL | |
| xStartPermissive | BOOL | ���������� ���������� |
| xRunPermissive | BOOL | |
| tStateTime | TIME | |

#### ������ ������ � ��������������

```mermaid
graph TD
    subgraph FB_PumpControl
        direction LR
        A[i_stCommands: ST_PumpCommands] --> B{�������������� ������� ������}
        A --> C{����������� ������ � ����������� �� ������}
        A -- xReset --> D{������ ���������: PUMP_STATE_FAULT}

        E[i_eMode: E_PumpMode] --> C
        E --> F{������ ���������: PUMP_STATE_OOS}
        E --> G{������ ���������: PUMP_STATE_IDLE}
        E --> H{������ ���������: PUMP_STATE_READY}
        E --> I{������ ���������: PUMP_STATE_RUNNING}
        E --> J{����������� ����������}

        K[i_xInterlock: BOOL] --> J
        L[i_xFCReady: BOOL] --> J
        L --> G
        L --> H
        M[i_xFCRunning: BOOL] --> I
        M --> N{������ ���������: PUMP_STATE_STARTING}
        M --> O{������ ���������: PUMP_STATE_STOPPING}
        P[i_xFCFault: BOOL] --> J
        P --> G
        P --> H
        P --> Q[o_xFault: BOOL]

        C -- xStartCmd --> H
        C -- xStopCmd --> I

        J -- xStartPermissive --> H
        J -- xRunPermissive --> I

        subgraph State Machine
            eState(eState: E_PumpState)
            eStatePrev(eStatePrev: E_PumpState)
            tonStateTimer(tonStateTimer: TON)
            tonStartDelay(tonStartDelay: TON)
            tonStopDelay(tonStopDelay: TON)
        end

        eState --> o_eState(o_eState: E_PumpState)
        eState --> o_xReady(o_xReady: BOOL)
        eState --> o_xRunning(o_xRunning: BOOL)
        eState --> o_xFault

        H -- o_xFCStart --> R(o_xFCStart: BOOL)
        N -- o_xFCStart --> R
        I -- o_xFCStart --> R
        O -- o_xFCStart --> R
        D -- o_xFCStart --> R
        F -- o_xFCStart --> R
        G -- o_xFCStart --> R
    end
```

### FB_PumpDiagnostics

������������ ��������������� ������ � ���������� ��������� �������������� ������. ���������� ��������� ����������� � ������������ ������� ��������������.

#### ����� (VAR_INPUT)

| ��� ���������� | ��� ������ | �������� |
|---|---|---|
| i_stProcessData | ST_PumpProcessData | ������ �������� |
| i_stConfig | ST_PumpConfig | ������������ |
| i_xRunning | BOOL | ����� �������� |
| i_xStart | BOOL | ������� ����� |
| i_xMaintenanceReset | BOOL | ����� �������� �� |

#### ������ (VAR_OUTPUT)

| ��� ���������� | ��� ������ | �������� |
|---|---|---|
| o_stDiagnostics | ST_PumpDiagnostics | ��������� ����������� |

#### ���������� ���������� (VAR)

| ��� ���������� | ��� ������ | �������� |
|---|---|---|
| tonRunTimer | TON | ������� |
| tonHourTimer | TON | |
| rtStartDetect | R_TRIG | |
| dwRunSeconds | DWORD | �������� � ���������� |
| dwTotalStarts | DWORD | |
| iStartsThisHour | INT | |
| rTotalVolume | REAL | |
| rTotalEnergy | REAL | |
| rEfficiency | REAL | ��������� ��������� |
| rSpecificPower | REAL | |
| rFlowDeviation | REAL | |
| rPressureDeviation | REAL | |
| rSumEfficiency | REAL | ������� �������� |
| rSumPower | REAL | |
| dwEfficiencyCount | DWORD | |
| xLowEfficiency | BOOL | ��������������� ����� |
| xHighVibration | BOOL | |
| xMechanicalWear | BOOL | |
| xFirstScan | BOOL | ��������������� |
| dwLastHour | DWORD | |
| rPowerFactor | REAL | |

#### ������ ������ � ��������������

```mermaid
graph TD
    subgraph FB_PumpDiagnostics
        direction LR
        A[i_stProcessData: ST_PumpProcessData] --> B{�������� ���������}
        A --> C{������ ��� ������}
        A --> D{�������� ��������}
        A --> E{����������� ���������}
        A --> F{���������� �������� ���������}

        G[i_stConfig: ST_PumpConfig] --> C
        G --> E
        G --> F

        H[i_xRunning: BOOL] --> B
        H --> C
        H --> E

        I[i_xStart: BOOL] --> B

        J[i_xMaintenanceReset: BOOL] --> B

        B -- dwRunSeconds --> F
        B -- dwTotalStarts --> F
        B -- iStartsThisHour --> F
        B -- rTotalVolume --> F
        B -- rTotalEnergy --> F

        C -- rEfficiency --> F
        C -- rAvgEfficiency --> F
        C -- xLowEfficiency --> F

        D -- rSpecificPower --> F

        E -- xLowEfficiency --> F
        E -- xMechanicalWear --> F
        E -- xHighVibration --> F
        E -- rFlowDeviation --> F
        E -- rPressureDeviation --> F

        F --> o_stDiagnostics(o_stDiagnostics: ST_PumpDiagnostics)
    end
```

### FB_PumpModeControl

��������� �������� ������ ������ (��������, ������, ��������������) � ��� �����������. ���������� ������������ ������� � ���������.

#### ����� (VAR_INPUT)

| ��� ���������� | ��� ������ | �������� |
|---|---|---|
| i_stCommands | ST_PumpCommands | ������� ���������� |
| i_eCurrentState | E_PumpState | ������� ��������� ������ |
| i_xFCReady | BOOL | �� ����� |
| i_xFCFault | BOOL | ������ �� |

#### ������ (VAR_OUTPUT)

| ��� ���������� | ��� ������ | �������� |
|---|---|---|
| o_eMode | E_PumpMode | �������� ����� |
| o_xModeValid | BOOL | ����� ������� |
| o_rActiveSetpoint | REAL | �������� ������� |

#### ���������� ���������� (VAR)

| ��� ���������� | ��� ������ | �������� |
|---|---|---|
| eMode | E_PumpMode | ������� ����� |
| eModePrev | E_PumpMode | |
| eModeRequest | E_PumpMode | |
| tonModeChangeDelay | TON | ������� |
| xModeChangeRequest | BOOL | ����� |
| xModeChangeAllowed | BOOL | |
| xModeChangeActive | BOOL | |
| rManualSetpoint | REAL | ������� |
| rAutoSetpoint | REAL | |
| rActiveSetpoint | REAL | |

#### ������ ������ � ��������������

```mermaid
graph TD
    subgraph FB_PumpModeControl
        direction LR
        A[i_stCommands: ST_PumpCommands] --> B{������ �� ��������� ������}
        A --> C{����� �������� �������}

        D[i_eCurrentState: E_PumpState] --> E{�������� ����������� ����� ������}

        F[i_xFCReady: BOOL] --> G{�������� ���������� ������}
        H[i_xFCFault: BOOL] --> G

        B -- eModeRequest --> E
        B -- xModeChangeRequest --> I{���������� ����� ������}

        E -- xModeChangeAllowed --> I

        I -- eMode --> G
        I -- eMode --> C

        G -- o_xModeValid(o_xModeValid: BOOL)

        C -- o_rActiveSetpoint(o_rActiveSetpoint: REAL)

        eMode(eMode: E_PumpMode) --> o_eMode(o_eMode: E_PumpMode)
    end
```

### FB_PumpProtection

��������� ������ ������ ������ �� ����������, ������ ���� � ������ ��������� ��������.

#### ����� (VAR_INPUT)

| ��� ���������� | ��� ������ | �������� |
|---|---|---|
| i_stProcessData | ST_PumpProcessData | ������ �������� |
| i_stConfig | ST_PumpConfig | ������������ |
| i_xRunning | BOOL | ����� �������� |
| i_xExternalInterlock | BOOL | ������� ���������� |
| i_xLowLevelInterlock | BOOL | ���������� �� ������ |

#### ������ (VAR_OUTPUT)

| ��� ���������� | ��� ������ | �������� |
|---|---|---|
| o_xInterlock | BOOL | ����� ���������� |
| o_eFaultClass | E_PumpFaultClass | ����� ������ |
| o_wFaultCode | WORD | ��� ������ |

#### ���������� ���������� (VAR)

| ��� ���������� | ��� ������ | �������� |
|---|---|---|
| xDryRun | BOOL | ����� ����� |
| xClosedValve | BOOL | |
| xCavitation | BOOL | |
| xOverload | BOOL | |
| xLowFlow | BOOL | |
| xHighFlow | BOOL | |
| xLowInletPressure | BOOL | |
| xHighOutletPressure | BOOL | |
| xHighDifferentialPressure | BOOL | |
| xMechanicalFailure | BOOL | |
| tonDryRun | TON | ������� ����� |
| tonClosedValve | TON | |
| tonCavitation | TON | |
| tonOverload | TON | |
| tonLowFlow | TON | |
| tonHighFlow | TON | |
| tonStartupBypass | TON | |
| rDryRunFlowThreshold | REAL | ��������� �������� |
| rClosedValveFlowThreshold | REAL | |
| rOverloadCurrentThreshold | REAL | |
| rCavitationThreshold | REAL | |
| xStartupBypass | BOOL | ���������� ���������� |
| wFaultCode | WORD | |
| eFaultClass | E_PumpFaultClass | |

#### ������ ������ � ��������������

```mermaid
graph TD
    subgraph FB_PumpProtection
        direction LR
        A[i_stProcessData: ST_PumpProcessData] --> B{������ �� ������ ����}
        A --> C{������ �� ������ �� �������� ��������}
        A --> D{������ �� ���������}
        A --> E{������ �� ����������}
        A --> F{������ �� ������� �������}
        A --> G{������ �� �������� �������}
        A --> H{������ �� ��������}
        A --> I{����������� ������������ �������������}

        J[i_stConfig: ST_PumpConfig] --> B
        J --> C
        J --> D
        J --> E
        J --> F
        J --> G
        J --> H
        J --> I

        K[i_xRunning: BOOL] --> B
        K --> C
        K --> D
        K --> E
        K --> F
        K --> G
        K --> I

        L[i_xExternalInterlock: BOOL] --> M{������������ ���� ������}
        N[i_xLowLevelInterlock: BOOL] --> M

        B -- xDryRun --> M
        C -- xClosedValve --> M
        D -- xCavitation --> M
        E -- xOverload --> M
        F -- xLowFlow --> M
        G -- xHighFlow --> M
        H -- xLowInletPressure --> M
        H --> M
        I -- xMechanicalFailure --> M

        M -- o_wFaultCode(o_wFaultCode: WORD)
        M -- o_eFaultClass(o_eFaultClass: E_PumpFaultClass)

        M --> O{������������ ����������}
        L --> O
        N --> O

        O --> o_xInterlock(o_xInterlock: BOOL)
    end
