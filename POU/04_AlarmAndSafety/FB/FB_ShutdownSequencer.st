(*==============================================================================
    Название:    FB_ShutdownSequencer
    Автор:       
    Дата:        2025-04-30
    Версия:      1.0
    
    Описание:    Функциональный блок для управления последовательностью останова
                 Обеспечивает правильный порядок выключения оборудования
                 в штатном и аварийном режимах
==============================================================================*)
FUNCTION_BLOCK FB_ShutdownSequencer
VAR_IN_OUT
    stSequence: ST_ShutdownSequence;   (* Структура данных последовательности останова *)
END_VAR

VAR_INPUT
    bStartNormal: BOOL;                (* Запуск нормального останова *)
    bStartEmergency: BOOL;             (* Запуск аварийного останова *)
    bReset: BOOL;                      (* Сброс последовательности *)
    
    (* Состояние оборудования *)
    bHeaterOn: BOOL;                   (* Нагреватель включен *)
    rPump1Speed: REAL;                 (* Скорость насоса 1 (%) *)
    rPump2Speed: REAL;                 (* Скорость насоса 2 (%) *)
    rPropValvePosition: REAL;          (* Положение пропорционального клапана (%) *)
    bEMValveOpen: BOOL;                (* Состояние электромагнитного клапана *)
END_VAR

VAR_OUTPUT
    (* Команды управления оборудованием *)
    bHeaterOff: BOOL;                  (* Команда выключения нагревателя *)
    rPump1SpeedSetpoint: REAL;         (* Задание скорости насоса 1 (%) *)
    rPump2SpeedSetpoint: REAL;         (* Задание скорости насоса 2 (%) *)
    bPump1Stop: BOOL;                  (* Команда остановки насоса 1 *)
    bPump2Stop: BOOL;                  (* Команда остановки насоса 2 *)
    rPropValveSetpoint: REAL;          (* Задание положения пропорционального клапана (%) *)
    bEMValveClose: BOOL;               (* Команда закрытия электромагнитного клапана *)
END_VAR

VAR
    (* Триггеры *)
    rtStartNormal: R_TRIG;             (* Триггер запуска нормального останова *)
    rtStartEmergency: R_TRIG;          (* Триггер запуска аварийного останова *)
    rtReset: R_TRIG;                   (* Триггер сброса *)
    
    (* Таймеры *)
    tonStep: TON;                      (* Таймер текущего шага *)
    tonTimeout: TON;                   (* Таймер таймаута *)
    
    (* Локальные переменные *)
    tCurrentTime: TIME;                (* Текущее время *)
    tElapsedTime: TIME;                (* Прошедшее время *)
    rRateCalc: REAL;                   (* Расчетная скорость изменения *)
END_VAR

(* ======================================================================== *)
(* Основная логика функционального блока                                    *)
(* ======================================================================== *)

(* Обработка триггеров *)
rtStartNormal(CLK := bStartNormal);
rtStartEmergency(CLK := bStartEmergency);
rtReset(CLK := bReset);

(* Запуск последовательности останова *)
IF rtStartNormal.Q OR rtStartEmergency.Q THEN
    (* Инициализация последовательности *)
    stSequence.eCurrentStep := SHUTDOWN_INIT;
    stSequence.bInProgress := TRUE;
    stSequence.bEmergency := rtStartEmergency.Q;
    stSequence.bCompleted := FALSE;
    stSequence.bError := FALSE;
    stSequence.tStepStartTime := T#0S;
    
    (* Сброс таймеров *)
    tonStep(IN := FALSE);
    tonTimeout(IN := FALSE);
END_IF;

(* Сброс последовательности *)
IF rtReset.Q THEN
    (* Сброс всех параметров *)
    stSequence.eCurrentStep := SHUTDOWN_INIT;
    stSequence.bInProgress := FALSE;
    stSequence.bEmergency := FALSE;
    stSequence.bCompleted := FALSE;
    stSequence.bError := FALSE;
    stSequence.tStepStartTime := T#0S;
    
    (* Сброс таймеров *)
    tonStep(IN := FALSE);
    tonTimeout(IN := FALSE);
    
    (* Сброс выходов *)
    bHeaterOff := FALSE;
    rPump1SpeedSetpoint := 100.0;
    rPump2SpeedSetpoint := 100.0;
    bPump1Stop := FALSE;
    bPump2Stop := FALSE;
    rPropValveSetpoint := 100.0;
    bEMValveClose := FALSE;
    
    RETURN;
END_IF;

(* Обработка последовательности останова *)
IF stSequence.bInProgress THEN
    (* Отработка шагов последовательности *)
    CASE stSequence.eCurrentStep OF
        SHUTDOWN_INIT:
            (* Инициализация последовательности *)
            stSequence.tStepStartTime := T#0S;
            bHeaterOff := FALSE;
            bPump1Stop := FALSE;
            bPump2Stop := FALSE;
            bEMValveClose := FALSE;
            
            (* Переход к следующему шагу *)
            stSequence.eCurrentStep := SHUTDOWN_HEATER_OFF;
            
        SHUTDOWN_HEATER_OFF:
            (* Выключение нагревателя *)
            bHeaterOff := TRUE;
            
            (* Проверка выполнения шага *)
            IF NOT bHeaterOn THEN
                (* Нагреватель выключен - переход к следующему шагу *)
                stSequence.eCurrentStep := SHUTDOWN_PUMP_SLOWDOWN;
                tonStep(IN := FALSE);
            ELSE
                (* Ожидание выключения с таймаутом *)
                tonStep(IN := TRUE, PT := stSequence.tHeaterOffTimeout);
                IF tonStep.Q THEN
                    (* Таймаут - переход к следующему шагу с ошибкой *)
                    stSequence.eCurrentStep := SHUTDOWN_PUMP_SLOWDOWN;
                    stSequence.bError := TRUE;
                    tonStep(IN := FALSE);
                END_IF;
            END_IF;
            
        SHUTDOWN_PUMP_SLOWDOWN:
            (* Снижение скорости насосов *)
            IF stSequence.bEmergency THEN
                (* Аварийный останов - сразу к остановке насосов *)
                stSequence.eCurrentStep := SHUTDOWN_PUMP_STOP;
            ELSE
                (* Плавное снижение скорости насосов *)
                tonStep(IN := TRUE, PT := stSequence.tPumpSlowdownTime);
                
                (* Расчет скорости с учетом прошедшего времени *)
                rRateCalc := 100.0 - (TIME_TO_REAL(tonStep.ET) / TIME_TO_REAL(stSequence.tPumpSlowdownTime)) * 100.0;
                
                (* Установка скорости насосов *)
                rPump1SpeedSetpoint := MAX(0.0, rRateCalc);
                rPump2SpeedSetpoint := MAX(0.0, rRateCalc);
                
                (* Проверка завершения шага *)
                IF tonStep.Q THEN
                    (* Снижение скорости завершено - переход к остановке насосов *)
                    stSequence.eCurrentStep := SHUTDOWN_PUMP_STOP;
                    tonStep(IN := FALSE);
                END_IF;
            END_IF;
            
        SHUTDOWN_PUMP_STOP:
            (* Полная остановка насосов *)
            bPump1Stop := TRUE;
            bPump2Stop := TRUE;
            rPump1SpeedSetpoint := 0.0;
            rPump2SpeedSetpoint := 0.0;
            
            (* Проверка выполнения шага *)
            IF rPump1Speed <= 0.1 AND rPump2Speed <= 0.1 THEN
                (* Насосы остановлены - переход к следующему шагу *)
                stSequence.eCurrentStep := SHUTDOWN_VALVE_CLOSE;
                tonStep(IN := FALSE);
            ELSE
                (* Ожидание остановки с таймаутом *)
                tonStep(IN := TRUE, PT := stSequence.tPumpStopTimeout);
                IF tonStep.Q THEN
                    (* Таймаут - переход к следующему шагу с ошибкой *)
                    stSequence.eCurrentStep := SHUTDOWN_VALVE_CLOSE;
                    stSequence.bError := TRUE;
                    tonStep(IN := FALSE);
                END_IF;
            END_IF;
            
        SHUTDOWN_VALVE_CLOSE:
            (* Закрытие клапанов *)
            bEMValveClose := TRUE;
            
            IF stSequence.bEmergency THEN
                (* Аварийный останов - сразу закрываем пропорциональный клапан *)
                rPropValveSetpoint := 0.0;
            ELSE
                (* Плавное закрытие пропорционального клапана *)
                tonStep(IN := TRUE, PT := stSequence.tValveCloseTimeout);
                
                (* Расчет положения с учетом прошедшего времени *)
                rRateCalc := 100.0 - (TIME_TO_REAL(tonStep.ET) / TIME_TO_REAL(stSequence.tValveCloseTimeout)) * 100.0;
                
                (* Установка положения клапана *)
                rPropValveSetpoint := MAX(0.0, rRateCalc);
            END_IF;
            
            (* Проверка выполнения шага *)
            IF rPropValvePosition <= 0.1 AND NOT bEMValveOpen THEN
                (* Клапаны закрыты - переход к следующему шагу *)
                stSequence.eCurrentStep := SHUTDOWN_WAIT;
                tonStep(IN := FALSE);
            ELSE
                (* Ожидание закрытия с таймаутом *)
                tonStep(IN := TRUE, PT := stSequence.tValveCloseTimeout);
                IF tonStep.Q THEN
                    (* Таймаут - переход к следующему шагу с ошибкой *)
                    stSequence.eCurrentStep := SHUTDOWN_WAIT;
                    stSequence.bError := TRUE;
                    tonStep(IN := FALSE);
                END_IF;
            END_IF;
            
        SHUTDOWN_WAIT:
            (* Ожидание перед завершением останова *)
            tonStep(IN := TRUE, PT := stSequence.tWaitTime);
            
            (* Проверка выполнения шага *)
            IF tonStep.Q THEN
                (* Ожидание завершено - переход к завершению останова *)
                stSequence.eCurrentStep := SHUTDOWN_COMPLETE;
                tonStep(IN := FALSE);
            END_IF;
            
        SHUTDOWN_COMPLETE:
            (* Останов завершен *)
            stSequence.bInProgress := FALSE;
            stSequence.bCompleted := TRUE;
            
            (* Финальная проверка состояния оборудования *)
            IF bHeaterOn OR rPump1Speed > 0.1 OR rPump2Speed > 0.1 OR
               rPropValvePosition > 0.1 OR bEMValveOpen THEN
                (* Не все оборудование остановлено - ошибка *)
                stSequence.bError := TRUE;
                stSequence.eCurrentStep := SHUTDOWN_ERROR;
            END_IF;
            
        SHUTDOWN_ERROR:
            (* Ошибка останова - ничего не делаем, ждем сброса *)
            stSequence.bInProgress := FALSE;
            stSequence.bError := TRUE;
    END_CASE;
ELSE
    (* Последовательность неактивна - сброс выходов *)
    IF NOT stSequence.bCompleted THEN
        bHeaterOff := FALSE;
        rPump1SpeedSetpoint := 100.0;
        rPump2SpeedSetpoint := 100.0;
        bPump1Stop := FALSE;
        bPump2Stop := FALSE;
        rPropValveSetpoint := 100.0;
        bEMValveClose := FALSE;
    END_IF;
END_IF;