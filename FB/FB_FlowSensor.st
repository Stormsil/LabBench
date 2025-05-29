(*==============================================================================
    Название:    FB_FlowSensor
    Автор:       Редько А.
    Дата:        2025-04-27
    Версия:      1.0
    
    Описание:    Универсальный функциональный блок для расходомеров
                 с частотным/импульсным выходом.
==============================================================================*)
FUNCTION_BLOCK FB_FlowSensor
VAR_INPUT
    wPulseCounter: WORD;          (* Значение счетчика импульсов *)
    rPulsePerLiter: REAL;         (* Количество импульсов на литр *)
    tSampleTime: TIME := T#500MS; (* Время выборки для расчета расхода *)
    bEnable: BOOL := TRUE;        (* Разрешение работы *)
    bReset: BOOL;                 (* Сброс счетчиков и ошибок *)
END_VAR
VAR_OUTPUT
    stData: ST_FlowSensor_Data;   (* Структура с результатами *)
END_VAR
VAR
    (* Переменные для обработки импульсов *)
    dwPrevPulseCount: DWORD;      (* Предыдущее значение счетчика импульсов *)
    dwCurrentPulseCount: DWORD;   (* Текущее значение счетчика импульсов *)
    dwTotalPulseCount: DWORD;     (* Общее количество импульсов с учетом переполнений *)
    dwOverflowCounter: DWORD;     (* Счетчик переполнений WORD *)
    
    bFirstCycle: BOOL := TRUE;    (* Флаг первого цикла *)
    bValid: BOOL;                 (* Флаг валидности данных *)
    
    tTimer: TON;                  (* Таймер для расчета расхода *)
    rSampleTimeInSec: REAL;       (* Время выборки в секундах *)
END_VAR
VAR CONSTANT
    (* Битовая маска для кодов ошибок *)
    ERR_NONE: WORD := 16#0000;            (* Нет ошибок *)
    ERR_CONFIG: WORD := 16#0001;          (* Ошибка конфигурации *)
END_VAR

(* ======================================================================== *)
(* Основная логика функционального блока                                    *)
(* ======================================================================== *)

(* Инициализация *)

stData.wErrorCode := ERR_NONE;
stData.bValid := FALSE;
bValid := FALSE;

(* Проверка конфигурации *)
IF rPulsePerLiter <= 0.0 THEN
    (* Некорректно задан коэффициент пересчета *)
    stData.eStatus := STATUS_CONFIG_ERROR;
    stData.wErrorCode := stData.wErrorCode OR ERR_CONFIG;
    
ELSIF NOT bEnable THEN
    (* Блок отключен - нулевые значения *)
    stData.eStatus := STATUS_OK;
    stData.rFlowLPM := 0.0;
    stData.rFlowM3H := 0.0;
    stData.rFrequencyHz := 0.0;
    stData.wErrorCode := ERR_NONE;
    stData.bValid := FALSE;
    
ELSE
    (* Нормальная работа - обработка данных *)
    
    (* Преобразование WORD в DWORD *)
    dwCurrentPulseCount := WORD_TO_DWORD(wPulseCounter); (*  *)
    
    (* Обработка первого вызова *)
    IF bFirstCycle THEN
        dwPrevPulseCount := dwCurrentPulseCount;
        dwTotalPulseCount := dwCurrentPulseCount;
        bFirstCycle := FALSE; (*  *)
    END_IF;
    
    (* Обработка переполнения счетчика *)
    IF dwCurrentPulseCount < dwPrevPulseCount THEN
        (* Счетчик переполнился - добавляем 65536 (2^16) *)
        dwOverflowCounter := dwOverflowCounter + 65536; 
    END_IF;
    
    (* Расчет общего количества импульсов *)
    dwTotalPulseCount := dwCurrentPulseCount + dwOverflowCounter;
    stData.dwPulseCount := dwTotalPulseCount;
    
    (* Запуск таймера для расчета расхода *)
    tTimer(IN := TRUE, PT := tSampleTime);
    
    (* Расчет расхода по частоте импульсов *)
    IF tTimer.Q THEN
        (* Вычисление количества импульсов за период *)
        stData.dwPulseDelta := dwTotalPulseCount - dwPrevPulseCount;
        dwPrevPulseCount := dwTotalPulseCount;
        
        (* Преобразование времени выборки в секунды *)
        rSampleTimeInSec := TIME_TO_REAL(tSampleTime) / 1000.0;
        
        (* Расчет частоты импульсов (Гц) *)
        stData.rFrequencyHz := DWORD_TO_REAL(stData.dwPulseDelta) / rSampleTimeInSec;
        
        (* Расчет расхода в л/мин - универсальная формула для любого расходомера *)
        stData.rFlowLPM := (stData.rFrequencyHz * 60.0) / rPulsePerLiter;
        
        (* Расчет расхода в м?/ч *)
        stData.rFlowM3H := stData.rFlowLPM * 0.06; (* 1 л/мин = 0.06 м?/ч *)
        
        (* Расчет общего объема в литрах (полезно для учебных целей) *)
        stData.rTotalLiters := DWORD_TO_REAL(stData.dwPulseCount) / rPulsePerLiter;
        
        ⁡⁢⁣⁣(* Данные валидны *)⁡
        bValid := TRUE;
        stData.eStatus := STATUS_OK;
        
        (* Сброс таймера для следующего периода *)
        tTimer(IN := FALSE);
    END_IF;
    
    (* Установка флага валидности *)
    stData.bValid := bValid;
END_IF;

(* Сброс по внешнему сигналу *)
IF bReset THEN
    dwPrevPulseCount := dwCurrentPulseCount;
    dwOverflowCounter := 0;
    stData.rTotalLiters := 0.0;
    stData.eStatus := STATUS_OK;
    stData.wErrorCode := ERR_NONE;
    stData.bValid := TRUE;
END_IF;