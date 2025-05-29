
# Архитектура и структура модуля "Насос" (Pump)

Данный документ описывает архитектуру и структуру папки `Project/POU/02_Equipment/Pump` и входящих в нее функциональных блоков (ФБ).

## Обзор

Модуль "Насос" (`Pump`) инкапсулирует всю логику управления, диагностики и защиты насосного оборудования. Основным функциональным блоком является `FB_Pump`, который координирует работу других специализированных ФБ.

## Структура папки `Project/POU/02_Equipment/Pump`

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

## Описание функциональных блоков (ФБ)

*   **FB_Pump**: Главный функциональный блок, агрегирующий и координирующий работу всех под-ФБ для управления насосом.
*   **FB_PumpControl**: Отвечает за непосредственное управление насосом, включая команды пуска/останова, регулирование скорости и т.д. Взаимодействует со структурами команд и конфигурации.
*   **FB_PumpDiagnostics**: Обрабатывает диагностические данные и определяет состояние неисправностей насоса. Использует структуры диагностики и перечисления классов неисправностей.
*   **FB_PumpModeControl**: Управляет режимами работы насоса (например, ручной, автоматический) и его состояниями. Использует перечисления режимов и состояний.
*   **FB_PumpProtection**: Реализует логику защиты насоса от перегрузок, сухого хода и других аварийных ситуаций.
*   **FB_PumpSequencer**: Отвечает за последовательность операций насоса, например, при запуске или останове.

## Описание типов данных (ENUM и STRUCT)

### ENUM (Перечисления)

*   **E_PumpFaultClass**: Определяет классы неисправностей насоса.
*   **E_PumpMode**: Определяет доступные режимы работы насоса.
*   **E_PumpState**: Определяет возможные состояния насоса (например, "Остановлен", "Работает", "Ошибка").

### STRUCT (Структуры)

*   **ST_PumpCommands**: Содержит команды управления, подаваемые на насос.
*   **ST_PumpConfig**: Содержит параметры конфигурации насоса.
*   **ST_PumpDiagnostics**: Содержит диагностические данные насоса.
*   **ST_PumpInterface**: Определяет общий интерфейс для взаимодействия с насосом.
*   **ST_PumpProcessData**: Содержит данные процесса, связанные с работой насоса (например, текущая скорость, давление).

## Детальное описание функциональных блоков

### FB_Pump

Главный функциональный блок, агрегирующий и координирующий работу всех под-ФБ для управления насосом.

#### Входы (VAR_INPUT)

| Имя переменной | Тип данных | Описание |
|---|---|---|
| i_xStart | BOOL | Команда пуска |
| i_xStop | BOOL | Команда останова |
| i_xReset | BOOL | Сброс ошибок |
| i_eMode | E_PumpMode | Режим работы |
| i_rManualSetpoint | REAL | Ручная уставка частоты, Гц |
| i_rAutoSetpoint | REAL | Автоматическая уставка |
| i_rPressureInlet | REAL | Давление на входе, бар |
| i_rPressureOutlet | REAL | Давление на выходе, бар |
| i_rFlow | REAL | Расход, м?/ч |
| i_rTemperature | REAL | Температура, °C |
| i_stFCModbus | ST_FC_ModbusInterface | Интерфейс Modbus ПЧ |
| i_xExternalInterlock | BOOL | Внешняя блокировка |
| i_xLowLevelInterlock | BOOL | Блокировка по уровню |
| i_stConfig | ST_PumpConfig | Конфигурация насоса |

#### Выходы (VAR_OUTPUT)

| Имя переменной | Тип данных | Описание |
|---|---|---|
| o_xReady | BOOL | Готов к работе |
| o_xRunning | BOOL | Работает |
| o_xFault | BOOL | Авария |
| o_xWarning | BOOL | Предупреждение |
| o_eState | E_PumpState | Состояние насоса |
| o_eMode | E_PumpMode | Текущий режим |
| o_eFaultClass | E_PumpFaultClass | Класс ошибки |
| o_stDiagnostics | ST_PumpDiagnostics | Диагностика |
| o_stFCModbus | ST_FC_ModbusInterface | Интерфейс Modbus ПЧ |
| o_stInterface | ST_PumpInterface | Полный интерфейс |

#### Внутренние переменные (VAR)

| Имя переменной | Тип данных | Описание |
|---|---|---|
| fbPumpControl | FB_PumpControl | Внутренний функциональный блок |
| fbFrequencyConverter | FB_FrequencyConverter_AFD | Внутренний функциональный блок |
| fbPumpProtection | FB_PumpProtection | Внутренний функциональный блок |
| fbPumpDiagnostics | FB_PumpDiagnostics | Внутренний функциональный блок |
| fbPumpModeControl | FB_PumpModeControl | Внутренний функциональный блок |
| fbPumpSequencer | FB_PumpSequencer | Внутренний функциональный блок |
| stProcessData | ST_PumpProcessData | Внутренние данные |
| stCommands | ST_PumpCommands | Внутренние данные |
| stFCInterface | ST_FC_Interface | Внутренние данные |
| xFCStart | BOOL | |
| xFCInterlock | BOOL | |
| rFCSetpoint | REAL | |
| xFirstScan | BOOL | Флаги |

#### Потоки данных и взаимодействие

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

Отвечает за непосредственное управление насосом, включая команды пуска/останова, регулирование скорости и т.д. Взаимодействует со структурами команд и конфигурации.

#### Входы (VAR_INPUT)

| Имя переменной | Тип данных | Описание |
|---|---|---|
| i_stCommands | ST_PumpCommands | Команды управления |
| i_eMode | E_PumpMode | Текущий режим |
| i_xInterlock | BOOL | Блокировка от защит |
| i_xFCReady | BOOL | ПЧ готов |
| i_xFCRunning | BOOL | ПЧ работает |
| i_xFCFault | BOOL | Ошибка ПЧ |

#### Выходы (VAR_OUTPUT)

| Имя переменной | Тип данных | Описание |
|---|---|---|
| o_eState | E_PumpState | Состояние насоса |
| o_xFCStart | BOOL | Команда пуска ПЧ |
| o_xReady | BOOL | Готов к работе |
| o_xRunning | BOOL | Работает |
| o_xFault | BOOL | Авария |

#### Внутренние переменные (VAR)

| Имя переменной | Тип данных | Описание |
|---|---|---|
| eState | E_PumpState | Машина состояний |
| eStatePrev | E_PumpState | |
| tonStateTimer | TON | Таймеры |
| tonStartDelay | TON | |
| tonStopDelay | TON | |
| xStartCmd | BOOL | Флаги |
| xStopCmd | BOOL | |
| xStartRising | BOOL | |
| xStopRising | BOOL | |
| xStartPrev | BOOL | |
| xStopPrev | BOOL | |
| xStartPermissive | BOOL | Внутренние переменные |
| xRunPermissive | BOOL | |
| tStateTime | TIME | |

#### Потоки данных и взаимодействие

```mermaid
graph TD
    subgraph FB_PumpControl
        direction LR
        A[i_stCommands: ST_PumpCommands] --> B{Детектирование фронтов команд}
        A --> C{Определение команд в зависимости от режима}
        A -- xReset --> D{Машина состояний: PUMP_STATE_FAULT}

        E[i_eMode: E_PumpMode] --> C
        E --> F{Машина состояний: PUMP_STATE_OOS}
        E --> G{Машина состояний: PUMP_STATE_IDLE}
        E --> H{Машина состояний: PUMP_STATE_READY}
        E --> I{Машина состояний: PUMP_STATE_RUNNING}
        E --> J{Определение разрешений}

        K[i_xInterlock: BOOL] --> J
        L[i_xFCReady: BOOL] --> J
        L --> G
        L --> H
        M[i_xFCRunning: BOOL] --> I
        M --> N{Машина состояний: PUMP_STATE_STARTING}
        M --> O{Машина состояний: PUMP_STATE_STOPPING}
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

Обрабатывает диагностические данные и определяет состояние неисправностей насоса. Использует структуры диагностики и перечисления классов неисправностей.

#### Входы (VAR_INPUT)

| Имя переменной | Тип данных | Описание |
|---|---|---|
| i_stProcessData | ST_PumpProcessData | Данные процесса |
| i_stConfig | ST_PumpConfig | Конфигурация |
| i_xRunning | BOOL | Насос работает |
| i_xStart | BOOL | Импульс пуска |
| i_xMaintenanceReset | BOOL | Сброс счетчика ТО |

#### Выходы (VAR_OUTPUT)

| Имя переменной | Тип данных | Описание |
|---|---|---|
| o_stDiagnostics | ST_PumpDiagnostics | Структура диагностики |

#### Внутренние переменные (VAR)

| Имя переменной | Тип данных | Описание |
|---|---|---|
| tonRunTimer | TON | Таймеры |
| tonHourTimer | TON | |
| rtStartDetect | R_TRIG | |
| dwRunSeconds | DWORD | Счетчики и накопители |
| dwTotalStarts | DWORD | |
| iStartsThisHour | INT | |
| rTotalVolume | REAL | |
| rTotalEnergy | REAL | |
| rEfficiency | REAL | Расчетные параметры |
| rSpecificPower | REAL | |
| rFlowDeviation | REAL | |
| rPressureDeviation | REAL | |
| rSumEfficiency | REAL | Средние значения |
| rSumPower | REAL | |
| dwEfficiencyCount | DWORD | |
| xLowEfficiency | BOOL | Диагностические флаги |
| xHighVibration | BOOL | |
| xMechanicalWear | BOOL | |
| xFirstScan | BOOL | Вспомогательные |
| dwLastHour | DWORD | |
| rPowerFactor | REAL | |

#### Потоки данных и взаимодействие

```mermaid
graph TD
    subgraph FB_PumpDiagnostics
        direction LR
        A[i_stProcessData: ST_PumpProcessData] --> B{Счетчики наработки}
        A --> C{Расчет КПД насоса}
        A --> D{Удельная мощность}
        A --> E{Диагностика состояния}
        A --> F{Заполнение выходной структуры}

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

Управляет режимами работы насоса (например, ручной, автоматический) и его состояниями. Использует перечисления режимов и состояний.

#### Входы (VAR_INPUT)

| Имя переменной | Тип данных | Описание |
|---|---|---|
| i_stCommands | ST_PumpCommands | Команды управления |
| i_eCurrentState | E_PumpState | Текущее состояние насоса |
| i_xFCReady | BOOL | ПЧ готов |
| i_xFCFault | BOOL | Ошибка ПЧ |

#### Выходы (VAR_OUTPUT)

| Имя переменной | Тип данных | Описание |
|---|---|---|
| o_eMode | E_PumpMode | Активный режим |
| o_xModeValid | BOOL | Режим валиден |
| o_rActiveSetpoint | REAL | Активная уставка |

#### Внутренние переменные (VAR)

| Имя переменной | Тип данных | Описание |
|---|---|---|
| eMode | E_PumpMode | Текущий режим |
| eModePrev | E_PumpMode | |
| eModeRequest | E_PumpMode | |
| tonModeChangeDelay | TON | Таймеры |
| xModeChangeRequest | BOOL | Флаги |
| xModeChangeAllowed | BOOL | |
| xModeChangeActive | BOOL | |
| rManualSetpoint | REAL | Уставки |
| rAutoSetpoint | REAL | |
| rActiveSetpoint | REAL | |

#### Потоки данных и взаимодействие

```mermaid
graph TD
    subgraph FB_PumpModeControl
        direction LR
        A[i_stCommands: ST_PumpCommands] --> B{Запрос на изменение режима}
        A --> C{Выбор активной уставки}

        D[i_eCurrentState: E_PumpState] --> E{Проверка возможности смены режима}

        F[i_xFCReady: BOOL] --> G{Проверка валидности режима}
        H[i_xFCFault: BOOL] --> G

        B -- eModeRequest --> E
        B -- xModeChangeRequest --> I{Выполнение смены режима}

        E -- xModeChangeAllowed --> I

        I -- eMode --> G
        I -- eMode --> C

        G -- o_xModeValid(o_xModeValid: BOOL)

        C -- o_rActiveSetpoint(o_rActiveSetpoint: REAL)

        eMode(eMode: E_PumpMode) --> o_eMode(o_eMode: E_PumpMode)
    end
```

### FB_PumpProtection

Реализует логику защиты насоса от перегрузок, сухого хода и других аварийных ситуаций.

#### Входы (VAR_INPUT)

| Имя переменной | Тип данных | Описание |
|---|---|---|
| i_stProcessData | ST_PumpProcessData | Данные процесса |
| i_stConfig | ST_PumpConfig | Конфигурация |
| i_xRunning | BOOL | Насос работает |
| i_xExternalInterlock | BOOL | Внешняя блокировка |
| i_xLowLevelInterlock | BOOL | Блокировка по уровню |

#### Выходы (VAR_OUTPUT)

| Имя переменной | Тип данных | Описание |
|---|---|---|
| o_xInterlock | BOOL | Общая блокировка |
| o_eFaultClass | E_PumpFaultClass | Класс ошибки |
| o_wFaultCode | WORD | Код ошибки |

#### Внутренние переменные (VAR)

| Имя переменной | Тип данных | Описание |
|---|---|---|
| xDryRun | BOOL | Флаги защит |
| xClosedValve | BOOL | |
| xCavitation | BOOL | |
| xOverload | BOOL | |
| xLowFlow | BOOL | |
| xHighFlow | BOOL | |
| xLowInletPressure | BOOL | |
| xHighOutletPressure | BOOL | |
| xHighDifferentialPressure | BOOL | |
| xMechanicalFailure | BOOL | |
| tonDryRun | TON | Таймеры защит |
| tonClosedValve | TON | |
| tonCavitation | TON | |
| tonOverload | TON | |
| tonLowFlow | TON | |
| tonHighFlow | TON | |
| tonStartupBypass | TON | |
| rDryRunFlowThreshold | REAL | Пороговые значения |
| rClosedValveFlowThreshold | REAL | |
| rOverloadCurrentThreshold | REAL | |
| rCavitationThreshold | REAL | |
| xStartupBypass | BOOL | Внутренние переменные |
| wFaultCode | WORD | |
| eFaultClass | E_PumpFaultClass | |

#### Потоки данных и взаимодействие

```mermaid
graph TD
    subgraph FB_PumpProtection
        direction LR
        A[i_stProcessData: ST_PumpProcessData] --> B{Защита от сухого хода}
        A --> C{Защита от работы на закрытую задвижку}
        A --> D{Защита от кавитации}
        A --> E{Защита от перегрузки}
        A --> F{Защита по низкому расходу}
        A --> G{Защита по высокому расходу}
        A --> H{Защита по давлению}
        A --> I{Определение механической неисправности}

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

        L[i_xExternalInterlock: BOOL] --> M{Формирование кода ошибки}
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

        M --> O{Формирование блокировки}
        L --> O
        N --> O

        O --> o_xInterlock(o_xInterlock: BOOL)
    end
