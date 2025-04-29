(*==============================================================================
    Название:    FB_DiagnosticScenario
    Автор:       
    Дата:        2025-04-30
    Версия:      1.0
    
    Описание:    Функциональный блок обработки сценариев диагностики
                 Анализирует состояние системы на предмет обнаружения сценариев
                 неисправностей, таких как "насос работает, но нет расхода" и т.п.
==============================================================================*)
FUNCTION_BLOCK FB_DiagnosticScenario
VAR_INPUT
    (* Входные сигналы состояния системы *)
    
    (* Состояние насосов *)
    bPump1Running: BOOL;           (* Насос 1 работает *)
    bPump2Running: BOOL;           (* Насос 2 работает *)
    rPump1Speed: REAL;             (* Скорость насоса 1 (%) *)
    rPump2Speed: REAL;             (* Скорость насоса 2 (%) *)
    
    (* Состояние клапанов *)
    rPropValvePosition: REAL;      (* Положение пропорционального клапана (%) *)
    bEMValveOpen: BOOL;            (* Состояние электромагнитного клапана *)
    
    (* Состояние нагревателя *)
    bHeaterOn: BOOL;               (* Нагреватель включен *)
    rHeaterPower: REAL;            (* Мощность нагревателя (%) *)
    
    (* Сигналы с датчиков *)
    
    (* Давление *)
    rPressureKIE2: REAL;           (* Давление в емкости КИЕ2 (кПа) *)
    bPressureKIE2Valid: BOOL;      (* Сигнал валиден *)
    
    rPressurePipe: REAL;           (* Давление в трубопроводе (кПа) *)
    bPressurePipeValid: BOOL;      (* Сигнал валиден *)
    
    rPressurePumpIn1: REAL;        (* Давление перед насосом 1 (кПа) *)
    bPressurePumpIn1Valid: BOOL;   (* Сигнал валиден *)
    
    rPressurePumpOut1: REAL;       (* Давление после насоса 1 (кПа) *)
    bPressurePumpOut1Valid: BOOL;  (* Сигнал валиден *)
    
    rPressurePumpIn2: REAL;        (* Давление перед насосом 2 (кПа) *)
    bPressurePumpIn2Valid: BOOL;   (* Сигнал валиден *)
    
    rPressurePumpOut2: REAL;       (* Давление после насоса 2 (кПа) *)
    bPressurePumpOut2Valid: BOOL;  (* Сигнал валиден *)
    
    (* Расход *)
    rFlowPumpOut1: REAL;           (* Расход после насоса 1 (л/мин) *)
    bFlowPumpOut1Valid: BOOL;      (* Сигнал валиден *)
    
    rFlowPumpOut2: REAL;           (* Расход после насоса 2 (л/мин) *)
    bFlowPumpOut2Valid: BOOL;      (* Сигнал валиден *)
    
    rFlowPipe: REAL;               (* Расход в трубопроводе (л/мин) *)
    bFlowPipeValid: BOOL;          (* Сигнал валиден *)
    
    (* Уровень *)
    rLevelKIE1: REAL;              (* Уровень в емкости КИЕ1 (мм) *)
    bLevelKIE1Valid: BOOL;         (* Сигнал валиден *)
    
    bLevelLow: BOOL;               (* Уровень низкий (поплавок) *)
    bLevelMid: BOOL;               (* Уровень средний (поплавок) *)
    bLevelHigh: BOOL;              (* Уровень высокий (поплавок) *)
    bLevelValid: BOOL;             (* Сигналы валидны *)
    
    (* Температура *)
    rTemperature: REAL;            (* Температура (°C) *)
    bTemperatureValid: BOOL;       (* Сигнал валиден *)
    
    (* Управление *)
    bReset: BOOL;                  (* Сброс сценариев *)
    bEnable: BOOL := TRUE;         (* Разрешение работы *)
END_VAR

VAR_OUTPUT
    bAnyScenarioActive: BOOL;      (* Флаг наличия активных сценариев *)
    bBlockingRequired: BOOL;       (* Требуется блокировка *)
    bShutdownRequired: BOOL;       (* Требуется останов *)
    uiActiveScenarioCount: UINT;   (* Количество активных сценариев *)
    uiLastActiveScenarioIndex: UINT; (* Индекс последнего активного сценария *)
    dwActiveScenariosMask: DWORD;  (* Битовая маска активных сценариев *)
END_VAR

VAR
    (* Триггеры для обнаружения изменений *)
    rtPump1Running: R_TRIG;        (* Насос 1 запустился *)
    rtPump2Running: R_TRIG;        (* Насос 2 запустился *)
    rtHeaterOn: R_TRIG;            (* Нагреватель включился *)
    
    ftPump1Running: F_TRIG;        (* Насос 1 остановился *)
    ftPump2Running: F_TRIG;        (* Насос 2 остановился *)
    ftHeaterOn: F_TRIG;            (* Нагреватель выключился *)
    
    (* Таймеры для задержек обнаружения *)
    tonScenario1: TON;             (* Таймер для сценария 1 *)
    tonScenario2: TON;             (* Таймер для сценария 2 *)
    tonScenario3: TON;             (* Таймер для сценария 3 *)
    
    (* Локальные переменные *)
    uiCounter: UINT;               (* Счетчик для циклов *)
    
    (* Параметры сценариев *)
    rPump1DeltaP: REAL;            (* Перепад давления на насосе 1 *)
    rPump2DeltaP: REAL;            (* Перепад давления на насосе 2 *)
    
    (* Флаги обнаружения условий сценариев *)
    bPump1NoFlow: BOOL;            (* Условие "Насос 1 работает, но нет расхода" *)
    bPump2NoFlow: BOOL;            (* Условие "Насос 2 работает, но нет расхода" *)
    bPump1NoPressure: BOOL;        (* Условие "Насос 1 работает, но нет давления" *)
    bPump2NoPressure: BOOL;        (* Условие "Насос 2 работает, но нет давления" *)
    bPipeBlock: BOOL;              (* Условие "Блокировка в трубопроводе" *)
    bHeaterNoTempRise: BOOL;       (* Условие "Нагреватель включен, но температура не растет" *)
END_VAR

VAR CONSTANT
    (* Пороговые значения для обнаружения сценариев *)
    PUMP_MIN_SPEED: REAL := 10.0;          (* Минимальная скорость насоса (%) *)
    FLOW_THRESHOLD_LOW: REAL := 0.5;       (* Пороговое значение расхода (л/мин) *)
    PRESSURE_DELTA_MIN: REAL := 10.0;      (* Минимальный перепад давления (кПа) *)
    TEMPERATURE_RISE_MIN: REAL := 0.1;     (* Минимальный рост температуры (°C/мин) *)
    
    (* Времена задержек для обнаружения сценариев *)
    T_PUMP_NO_FLOW: TIME := T#5S;          (* Задержка для сценария "нет расхода" *)
    T_PUMP_NO_PRESSURE: TIME := T#3S;      (* Задержка для сценария "нет давления" *)
    T_HEATER_NO_TEMP: TIME := T#60S;       (* Задержка для сценария "нет роста температуры" *)
END_VAR

(* ======================================================================== *)
(* Основная логика функционального блока                                    *)
(* ======================================================================== *)

(* Обнаружение изменений состояния оборудования *)
rtPump1Running(CLK := bPump1Running);
rtPump2Running(CLK := bPump2Running);
rtHeaterOn(CLK := bHeaterOn);

ftPump1Running(CLK := bPump1Running);
ftPump2Running(CLK := bPump2Running);
ftHeaterOn(CLK := bHeaterOn);

(* Обработка команды сброса *)
IF bReset THEN
    (* Сброс всех сценариев *)
    FOR uiCounter := 1 TO MAX_SCENARIOS DO
        gaDiagScenarios[uiCounter].bActive := FALSE;
    END_FOR;
    
    (* Сброс таймеров *)
    tonScenario1(IN := FALSE);
    tonScenario2(IN := FALSE);
    tonScenario3(IN := FALSE);
END_IF;

(* Инициализация выходных переменных *)
bAnyScenarioActive := FALSE;
bBlockingRequired := FALSE;
bShutdownRequired := FALSE;
uiActiveScenarioCount := 0;
uiLastActiveScenarioIndex := 0;
dwActiveScenariosMask := 0;

(* ======================================================================== *)
(* Обнаружение условий для сценариев                                        *)
(* ======================================================================== *)

IF bEnable THEN
    
    (* Расчет параметров системы *)
    IF bPressurePumpIn1Valid AND bPressurePumpOut1Valid THEN
        rPump1DeltaP := rPressurePumpOut1 - rPressurePumpIn1;
    ELSE
        rPump1DeltaP := 0.0;
    END_IF;
    
    IF bPressurePumpIn2Valid AND bPressurePumpOut2Valid THEN
        rPump2DeltaP := rPressurePumpOut2 - rPressurePumpIn2;
    ELSE
        rPump2DeltaP := 0.0;
    END_IF;
    
    (* Условие "Насос 1 работает, но нет расхода" *)
    bPump1NoFlow := bPump1Running AND rPump1Speed > PUMP_MIN_SPEED AND 
                    bFlowPumpOut1Valid AND rFlowPumpOut1 < FLOW_THRESHOLD_LOW;
    
    (* Условие "Насос 2 работает, но нет расхода" *)
    bPump2NoFlow := bPump2Running AND rPump2Speed > PUMP_MIN_SPEED AND 
                    bFlowPumpOut2Valid AND rFlowPumpOut2 < FLOW_THRESHOLD_LOW;
    
    (* Условие "Насос 1 работает, но нет давления" *)
    bPump1NoPressure := bPump1Running AND rPump1Speed > PUMP_MIN_SPEED AND 
                        bPressurePumpIn1Valid AND bPressurePumpOut1Valid AND 
                        rPump1DeltaP < PRESSURE_DELTA_MIN;
    
    (* Условие "Насос 2 работает, но нет давления" *)
    bPump2NoPressure := bPump2Running AND rPump2Speed > PUMP_MIN_SPEED AND 
                        bPressurePumpIn2Valid AND bPressurePumpOut2Valid AND 
                        rPump2DeltaP < PRESSURE_DELTA_MIN;
    
    (* Условие "Блокировка в трубопроводе" *)
    bPipeBlock := bFlowPipeValid AND rFlowPipe < FLOW_THRESHOLD_LOW AND 
                  bPressurePipeValid AND rPressurePipe > (rPressureKIE2 * 1.5);
    
    (* Условие "Нагреватель включен, но температура не растет" *)
    (* Требует дополнительной логики с отслеживанием изменения температуры во времени *)
    bHeaterNoTempRise := FALSE; (* Пока не реализовано *)
    
    (* ======================================================================== *)
    (* Обработка таймеров задержки обнаружения сценариев                       *)
    (* ======================================================================== *)
    
    (* Таймер для сценария "Насос 1 работает, но нет расхода" *)
    tonScenario1(IN := bPump1NoFlow, PT := T_PUMP_NO_FLOW);
    
    (* Таймер для сценария "Насос 2 работает, но нет расхода" *)
    tonScenario2(IN := bPump2NoFlow, PT := T_PUMP_NO_FLOW);
    
    (* Таймер для сценария "Нагреватель включен, но температура не растет" *)
    tonScenario3(IN := bHeaterNoTempRise, PT := T_HEATER_NO_TEMP);
    
    (* ======================================================================== *)
    (* Активация сценариев диагностики                                         *)
    (* ======================================================================== *)
    
    (* Сценарий 1: "Насос 1 работает, но нет расхода" *)
    IF tonScenario1.Q THEN
        gaDiagScenarios[1].bActive := TRUE;
        gaDiagScenarios[1].eType := DIAG_PUMP_NO_FLOW;
        gaDiagScenarios[1].wSourceID := PUMP1_ID;
        gaDiagScenarios[1].wDeviceID := PUMP1_ID;
        gaDiagScenarios[1].eBlockingLevel := DEVICE_BLOCKING;
        gaDiagScenarios[1].bRequireShutdown := FALSE;
        gaDiagScenarios[1].rValue1 := rPump1Speed;
        gaDiagScenarios[1].rValue2 := rFlowPumpOut1;
        gaDiagScenarios[1].wErrorCode := 16#0101;
        gaDiagScenarios[1].sMessage := 'Насос 1 работает, но нет расхода';
    END_IF;
    
    (* Сценарий 2: "Насос 2 работает, но нет расхода" *)
    IF tonScenario2.Q THEN
        gaDiagScenarios[2].bActive := TRUE;
        gaDiagScenarios[2].eType := DIAG_PUMP_NO_FLOW;
        gaDiagScenarios[2].wSourceID := PUMP2_ID;
        gaDiagScenarios[2].wDeviceID := PUMP2_ID;
        gaDiagScenarios[2].eBlockingLevel := DEVICE_BLOCKING;
        gaDiagScenarios[2].bRequireShutdown := FALSE;
        gaDiagScenarios[2].rValue1 := rPump2Speed;
        gaDiagScenarios[2].rValue2 := rFlowPumpOut2;
        gaDiagScenarios[2].wErrorCode := 16#0102;
        gaDiagScenarios[2].sMessage := 'Насос 2 работает, но нет расхода';
    END_IF;
    
    (* Сценарий 3: "Насос 1 работает, но нет давления" *)
    IF bPump1NoPressure THEN
        gaDiagScenarios[3].bActive := TRUE;
        gaDiagScenarios[3].eType := DIAG_PUMP_NO_PRESSURE;
        gaDiagScenarios[3].wSourceID := PUMP1_ID;
        gaDiagScenarios[3].wDeviceID := PUMP1_ID;
        gaDiagScenarios[3].eBlockingLevel := DEVICE_BLOCKING;
        gaDiagScenarios[3].bRequireShutdown := FALSE;
        gaDiagScenarios[3].rValue1 := rPump1Speed;
        gaDiagScenarios[3].rValue2 := rPump1DeltaP;
        gaDiagScenarios[3].wErrorCode := 16#0103;
        gaDiagScenarios[3].sMessage := 'Насос 1 работает, но нет давления';
    END_IF;
    
    (* Сценарий 4: "Насос 2 работает, но нет давления" *)
    IF bPump2NoPressure THEN
        gaDiagScenarios[4].bActive := TRUE;
        gaDiagScenarios[4].eType := DIAG_PUMP_NO_PRESSURE;
        gaDiagScenarios[4].wSourceID := PUMP2_ID;
        gaDiagScenarios[4].wDeviceID := PUMP2_ID;
        gaDiagScenarios[4].eBlockingLevel := DEVICE_BLOCKING;
        gaDiagScenarios[4].bRequireShutdown := FALSE;
        gaDiagScenarios[4].rValue1 := rPump2Speed;
        gaDiagScenarios[4].rValue2 := rPump2DeltaP;
        gaDiagScenarios[4].wErrorCode := 16#0104;
        gaDiagScenarios[4].sMessage := 'Насос 2 работает, но нет давления';
    END_IF;
    
    (* Сценарий 5: "Блокировка в трубопроводе" *)
    IF bPipeBlock THEN
        gaDiagScenarios[5].bActive := TRUE;
        gaDiagScenarios[5].eType := DIAG_PIPE_BLOCK;
        gaDiagScenarios[5].wSourceID := SYSTEM_ID;
        gaDiagScenarios[5].wDeviceID := 0;
        gaDiagScenarios[5].eBlockingLevel := SYSTEM_BLOCKING;
        gaDiagScenarios[5].bRequireShutdown := TRUE;
        gaDiagScenarios[5].rValue1 := rFlowPipe;
        gaDiagScenarios[5].rValue2 := rPressurePipe;
        gaDiagScenarios[5].wErrorCode := 16#0105;
        gaDiagScenarios[5].sMessage := 'Блокировка в трубопроводе';
    END_IF;
    
    (* Сценарий 6: "Нагреватель включен, но температура не растет" *)
    IF tonScenario3.Q THEN
        gaDiagScenarios[6].bActive := TRUE;
        gaDiagScenarios[6].eType := DIAG_HEATER_NO_TEMP_RISE;
        gaDiagScenarios[6].wSourceID := HEATER_ID;
        gaDiagScenarios[6].wDeviceID := HEATER_ID;
        gaDiagScenarios[6].eBlockingLevel := DEVICE_BLOCKING;
        gaDiagScenarios[6].bRequireShutdown := FALSE;
        gaDiagScenarios[6].rValue1 := rHeaterPower;
        gaDiagScenarios[6].rValue2 := rTemperature;
        gaDiagScenarios[6].wErrorCode := 16#0106;
        gaDiagScenarios[6].sMessage := 'Нагреватель включен, но температура не растет';
    END_IF;
    
    (* ======================================================================== *)
    (* Обработка результатов анализа сценариев                                 *)
    (* ======================================================================== *)
    
    (* Обработка всех сценариев *)
    FOR uiCounter := 1 TO MAX_SCENARIOS DO
        IF gaDiagScenarios[uiCounter].bActive THEN
            (* Сценарий активен *)
            bAnyScenarioActive := TRUE;
            uiActiveScenarioCount := uiActiveScenarioCount + 1;
            uiLastActiveScenarioIndex := uiCounter;
            
            (* Установка бита в маске активных сценариев (только для первых 32 сценариев) *)
            IF uiCounter <= 32 THEN
                dwActiveScenariosMask := dwActiveScenariosMask OR SHL(DWORD#1, uiCounter-1);
            END_IF;
            
            (* Проверка требований блокировки и останова *)
            IF gaDiagScenarios[uiCounter].eBlockingLevel <> NO_BLOCKING THEN
                bBlockingRequired := TRUE;
            END_IF;
            
            IF gaDiagScenarios[uiCounter].bRequireShutdown THEN
                bShutdownRequired := TRUE;
            END_IF;
        END_IF;
    END_FOR;
END_IF;