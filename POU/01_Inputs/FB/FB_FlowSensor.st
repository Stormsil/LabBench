(*==============================================================================
    Название:    FB_FlowSensor
    Автор:       Редько А.
    Дата:        2025-04-27
    Версия:      1.1
    
    Описание:    Универсальный функциональный блок для расходомеров
                 с частотным/импульсным выходом.
                 
                 Реализован как level-controlled (LCon) блок
==============================================================================*)
FUNCTION_BLOCK FB_FlowSensor (* LCon *)
VAR_INPUT
    bEnable: BOOL := TRUE;        (* Разрешение работы *)
    wPulseCounter: WORD;          (* Значение счетчика импульсов *)
    rPulsePerLiter: REAL;         (* Количество импульсов на литр *)
    tSampleTime: TIME := T#500MS; (* Время выборки для расчета расхода *)
    bReset: BOOL;                 (* Сброс счетчиков и ошибок *)
END_VAR
VAR_OUTPUT
    bValid: BOOL;                 (* Данные достоверны *)
    bError: BOOL;                 (* Флаг ошибки *)
    wErrorID: WORD;               (* Код ошибки *)
    rFlowLPM: REAL;               (* Расход в л/мин *)
    rFlowM3H: REAL;               (* Расход в м³/ч *)
    rTotalLiters: REAL;           (* Общий объем в литрах *)
    rFrequencyHz: REAL;           (* Частота импульсов в Гц *)
    eStatus: E_Inputs_Status;     (* Статус датчика *)
    dwPulseCount: DWORD;          (* Накопленное количество импульсов *)
    dwPulseDelta: DWORD;          (* Количество импульсов за период *)
END_VAR
VAR
    (* Переменные для обработки импульсов *)
    dwPrevPulseCount: DWORD;      (* Предыдущее значение счетчика импульсов *)
    dwCurrentPulseCount: DWORD;   (* Текущее значение счетчика импульсов *)
    dwTotalPulseCount: DWORD;     (* Общее количество импульсов с учетом переполнений *)
    dwOverflowCounter: DWORD;     (* Счетчик переполнений WORD *)
    
    bFirstCycle: BOOL := TRUE;    (* Флаг первого цикла *)
    
    tTimer: TON;                  (* Таймер для расчета расхода *)
    rSampleTimeInSec: REAL;       (* Время выборки в секундах *)
    
    (* Структура для обратной совместимости *)
    stDataInternal: ST_FlowSensor_Data;
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
wErrorID := ERR_NONE;
bValid := FALSE;
bError := FALSE;

(* Проверка конфигурации *)
IF rPulsePerLiter <= 0.0 THEN
    (* Некорректно задан коэффициент пересчета *)
    eStatus := STATUS_CONFIG_ERROR;
    wErrorID := wErrorID OR ERR_CONFIG;
    bError := TRUE;
    
ELSIF NOT bEnable THEN
    (* Блок отключен - нулевые значения *)
    eStatus := STATUS_OK;
    rFlowLPM := 0.0;
    rFlowM3H := 0.0;
    rFrequencyHz := 0.0;
    wErrorID := ERR_NONE;
    bValid := FALSE;
    bError := FALSE;
    
ELSE
    (* Нормальная работа - обработка данных *)
    
    (* Преобразование WORD в DWORD *)
    dwCurrentPulseCount := WORD_TO_DWORD(wPulseCounter);
    
    (* Обработка первого вызова *)
    IF bFirstCycle THEN
        dwPrevPulseCount := dwCurrentPulseCount;
        dwTotalPulseCount := dwCurrentPulseCount;
        bFirstCycle := FALSE;
    END_IF;
    
    (* Обработка переполнения счетчика *)
    IF dwCurrentPulseCount < dwPrevPulseCount THEN
        (* Счетчик переполнился - добавляем 65536 (2^16) *)
        dwOverflowCounter := dwOverflowCounter + 65536;
    END_IF;
    
    (* Расчет общего количества импульсов *)
    dwTotalPulseCount := dwCurrentPulseCount + dwOverflowCounter;
    dwPulseCount := dwTotalPulseCount;
    
    (* Запуск таймера для расчета расхода *)
    tTimer(IN := TRUE, PT := tSampleTime);
    
    (* Расчет расхода по частоте импульсов *)
    IF tTimer.Q THEN
        (* Вычисление количества импульсов за период *)
        dwPulseDelta := dwTotalPulseCount - dwPrevPulseCount;
        dwPrevPulseCount := dwTotalPulseCount;
        
        (* Преобразование времени выборки в секунды *)
        rSampleTimeInSec := TIME_TO_REAL(tSampleTime) / 1000.0;
        
        (* Расчет частоты импульсов (Гц) *)
        rFrequencyHz := DWORD_TO_REAL(dwPulseDelta) / rSampleTimeInSec;
        
        (* Расчет расхода в л/мин - универсальная формула для любого расходомера *)
        rFlowLPM := (rFrequencyHz * 60.0) / rPulsePerLiter;
        
        (* Расчет расхода в м³/ч *)
        rFlowM3H := rFlowLPM * 0.06; (* 1 л/мин = 0.06 м³/ч *)
        
        (* Расчет общего объема в литрах (полезно для учебных целей) *)
        rTotalLiters := DWORD_TO_REAL(dwPulseCount) / rPulsePerLiter;
        
        (* Данные валидны *)
        bValid := TRUE;
        bError := FALSE;
        eStatus := STATUS_OK;
        
        (* Сброс таймера для следующего периода *)
        tTimer(IN := FALSE);
    END_IF;
END_IF;

(* Сброс по внешнему сигналу *)
IF bReset THEN
    dwPrevPulseCount := dwCurrentPulseCount;
    dwOverflowCounter := 0;
    rTotalLiters := 0.0;
    eStatus := STATUS_OK;
    wErrorID := ERR_NONE;
    bValid := TRUE;
    bError := FALSE;
END_IF;

(* Заполнение структуры для обратной совместимости *)
stDataInternal.rFlowLPM := rFlowLPM;
stDataInternal.rFlowM3H := rFlowM3H;
stDataInternal.rTotalLiters := rTotalLiters;
stDataInternal.rFrequencyHz := rFrequencyHz;
stDataInternal.eStatus := eStatus;
stDataInternal.wErrorCode := wErrorID;
stDataInternal.bValid := bValid;
stDataInternal.dwPulseCount := dwPulseCount;
stDataInternal.dwPulseDelta := dwPulseDelta;