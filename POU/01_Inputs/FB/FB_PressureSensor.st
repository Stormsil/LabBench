(*==============================================================================
    Название:    FB_PressureSensor
    Автор:       Редько А.
    Дата:        2025-04-25
    Версия:      1.2
    
    Описание:    Функциональный блок для датчиков давления.
                 
                 Данные получаются после масштабирования в конфигурации ПЛК.
                 Блок проверяет статус измерения, выполняет проверку на
                 превышение предельного значения и формирует результаты.
                 
                 Фильтрация и обработка статусов выполняется в конфигурации ПЛК
                 
                 Реализован как level-controlled (LCon) блок
==============================================================================*)
FUNCTION_BLOCK FB_PressureSensor (* LCon *)
VAR_INPUT
    bEnable: BOOL := TRUE;      (* Разрешение работы *)
    rPressureKPa: REAL;         (* Давление в кПа (с аналогового входа после масштабирования) *)
    rMaxPressureKPa: REAL;      (* Максимально допустимое давление, кПа *)
    bReset: BOOL;               (* Сброс ошибок *)
END_VAR

VAR_OUTPUT
    bValid: BOOL;               (* Данные достоверны *)
    bError: BOOL;               (* Флаг ошибки *)
    wErrorID: WORD;             (* Код ошибки *)
    rPressureValue: REAL;       (* Давление в кПа *)
    eStatus: E_Inputs_Status;   (* Статус датчика *)
END_VAR

VAR
    (* Системные переменные *)
    byStatus: BYTE;             (* Старший байт из переменной для анализа статуса *)
    
    (* Структура для обратной совместимости *)
    stDataInternal: ST_PressureSensor_Data;
END_VAR

VAR CONSTANT
    (* Константы для статусов аналогового входа (старший байт) *)
    ERR_NONE: BYTE := 16#00;           (* Ошибок нет *)
    ERR_INVALID: BYTE := 16#F1;        (* Результаты измерения заведомо неверны *)
    ERR_NOT_READY: BYTE := 16#F6;      (* Результаты измерения не готовы *)
    ERR_ABOVE_RANGE: BYTE := 16#FA;    (* Сигнал на входе больше возможного *)
    ERR_BELOW_RANGE: BYTE := 16#FB;    (* Сигнал на входе меньше возможного *)
    ERR_CURRENT_OVERLOAD: BYTE := 16#FC;(* Перегрузка в канале измерения тока *)
    ERR_VOLTAGE_BREAK: BYTE := 16#FD;  (* Обрыв датчика в канале измерения напряжения *)
    
    (* Битовые маски для кодов ошибок *)
    ERROR_NONE: WORD := 16#0000;           (* Нет ошибок *)
    ERROR_CONFIG: WORD := 16#0001;         (* Ошибка конфигурации *)
    ERROR_VALUE_ABOVE_MAX: WORD := 16#0002;    (* Превышение максимального давления *)
    ERROR_AI_ABOVE_RANGE: WORD := 16#0004; (* Превышение диапазона аналогового входа *)
    ERROR_AI_BELOW_RANGE: WORD := 16#0008; (* Значение ниже диапазона аналогового входа *)
    ERROR_WIRE_BREAK: WORD := 16#0010;     (* Обрыв линии датчика *)
    ERROR_CURRENT_OVERLOAD: WORD := 16#0020; (* Перегрузка в канале измерения тока *)
    ERROR_NOT_READY: WORD := 16#0040;      (* Измерение не готово *)
    ERROR_UNKNOWN: WORD := 16#8000;        (* Неизвестная ошибка *)
END_VAR

(* ======================================================================== *)
(* Основная логика функционального блока                                    *)
(* ======================================================================== *)

(* Инициализация *)
rPressureValue := rPressureKPa;  (* Сохраняем исходное значение *)
wErrorID := ERROR_NONE;
bValid := FALSE;
bError := FALSE;

(* Проверка конфигурации *)
IF rMaxPressureKPa <= 0.0 THEN
    (* Некорректно задано максимальное давление *)
    eStatus := STATUS_CONFIG_ERROR;
    wErrorID := wErrorID OR ERROR_CONFIG;
    bError := TRUE;
    
ELSIF NOT bEnable THEN
    (* Блок отключен - возвращаем нулевые значения *)
    eStatus := STATUS_OK;
    rPressureValue := 0.0;
    wErrorID := ERROR_NONE;
    bValid := FALSE;
    bError := FALSE;
    
ELSE
    (* Нормальная работа - обработка данных и проверка ошибок *)
    
    (* Получение старшего байта для анализа статуса *)
    byStatus := DWORD_TO_BYTE(SHR(REAL_TO_DWORD(rPressureKPa) AND 16#FF000000, 24));

    (* Проверка статуса аналогового входа *)
    CASE byStatus OF
        ERR_NONE:
            (* Нормальные данные - статус OK *)
            eStatus := STATUS_OK;
            bValid := TRUE;
            bError := FALSE;
            
        ERR_ABOVE_RANGE:
            (* Превышение диапазона аналогового входа *)
            eStatus := STATUS_AI_ABOVE_RANGE;
            wErrorID := wErrorID OR ERROR_AI_ABOVE_RANGE;
            bValid := FALSE;
            bError := TRUE;
            
        ERR_BELOW_RANGE:
            (* Значение ниже диапазона аналогового входа *)
            eStatus := STATUS_AI_BELOW_RANGE;
            wErrorID := wErrorID OR ERROR_AI_BELOW_RANGE;
            bValid := FALSE;
            bError := TRUE;
            
        ERR_VOLTAGE_BREAK:
            (* Обрыв линии датчика *)
            eStatus := STATUS_WIRE_BREAK;
            wErrorID := wErrorID OR ERROR_WIRE_BREAK;
            bValid := FALSE;
            bError := TRUE;
            
        ERR_CURRENT_OVERLOAD:
            (* Перегрузка в канале измерения тока *)
            eStatus := STATUS_CURRENT_OVERLOAD;
            wErrorID := wErrorID OR ERROR_CURRENT_OVERLOAD;
            bValid := FALSE;
            bError := TRUE;
            
        ERR_NOT_READY:
            (* Измерение не готово *)
            eStatus := STATUS_NOT_READY;
            wErrorID := wErrorID OR ERROR_NOT_READY;
            bValid := FALSE;
            bError := TRUE;
            
        ELSE
            (* Прочие неизвестные ошибки *)
            eStatus := STATUS_UNKNOWN;
            wErrorID := wErrorID OR ERROR_UNKNOWN;
            bValid := FALSE;
            bError := TRUE;
    END_CASE;
    
    (* Проверка на превышение максимально допустимого давления *)
    IF rPressureKPa > rMaxPressureKPa AND rMaxPressureKPa > 0.0 AND bValid THEN
        (* Выставляем ошибку превышения давления *)
        eStatus := STATUS_VALUE_ABOVE_MAX;
        wErrorID := wErrorID OR ERROR_VALUE_ABOVE_MAX;
        bValid := FALSE;
        bError := TRUE;
    END_IF;
END_IF;

(* Сброс ошибок по внешнему сигналу *)
IF bReset THEN
    eStatus := STATUS_OK;
    wErrorID := ERROR_NONE;
    bValid := TRUE;
    bError := FALSE;
END_IF;

(* Заполнение структуры для обратной совместимости *)
stDataInternal.rPressureKPa := rPressureValue;
stDataInternal.eStatus := eStatus;
stDataInternal.wErrorCode := wErrorID;
stDataInternal.bValid := bValid;