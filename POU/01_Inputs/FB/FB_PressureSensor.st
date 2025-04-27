(*==============================================================================
    Название:    FB_PressureSensor
    Автор:       Редько А.
    Дата:        2025-04-25
    Версия:      1.1
    
    Описание:    Функциональный блок для датчиков давления.
                 
                 Данные получаются после масштабирования в конфигурации ПЛК.
                 Блок проверяет статус измерения, выполняет проверку на
                 превышение предельного значения и формирует структуру данных
                 с результатами.
                 
    Примечание:  Фильтрация и обработка статусов выполняется в конфигурации ПЛК
==============================================================================*)
FUNCTION_BLOCK FB_PressureSensor
VAR_INPUT
    rPressureKPa: REAL;         (* Давление в кПа (с аналогового входа после масштабирования) *)
    rMaxPressureKPa: REAL;      (* Максимально допустимое давление, кПа *)
    bEnable: BOOL := TRUE;      (* Разрешение работы *)
    bReset: BOOL;               (* Сброс ошибок *)
END_VAR

VAR_OUTPUT
    stData: ST_PressureSensor_Data;  (* Структура с результатами *)
END_VAR

VAR
    (* Системные переменные *)
    byStatus: BYTE;              (* Старший байт из переменной для анализа статуса *)
    bValid: BOOL;                 (* Флаг валидности данных *)
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
stData.rPressureKPa := rPressureKPa;  (* Сохраняем исходное значение *)
stData.wErrorCode := ERROR_NONE;
stData.bValid := FALSE;
bValid := FALSE;

(* Проверка конфигурации *)
IF rMaxPressureKPa <= 0.0 THEN
    (* Некорректно задано максимальное давление *)
    stData.eStatus := STATUS_CONFIG_ERROR;
    stData.wErrorCode := stData.wErrorCode OR ERROR_CONFIG;
    
ELSIF NOT bEnable THEN
    (* Блок отключен - возвращаем нулевые значения *)
    stData.eStatus := STATUS_OK;
    stData.rPressureKPa := 0.0;
    stData.wErrorCode := ERROR_NONE;
    stData.bValid := FALSE;
    
ELSE
    (* Нормальная работа - обработка данных и проверка ошибок *)
    
    (* Получение старшего байта для анализа статуса *)
    byStatus := DWORD_TO_BYTE(SHR(REAL_TO_DWORD(rPressureKPa) AND 16#FF000000, 24));

    (* Проверка статуса аналогового входа *)
    CASE byStatus OF
        ERR_NONE:
            (* Нормальные данные - статус OK *)
            stData.eStatus := STATUS_OK;
            bValid := TRUE;
            
        ERR_ABOVE_RANGE:
            (* Превышение диапазона аналогового входа *)
            stData.eStatus := STATUS_AI_ABOVE_RANGE;
            stData.wErrorCode := stData.wErrorCode OR ERROR_AI_ABOVE_RANGE;
            bValid := FALSE;
            
        ERR_BELOW_RANGE:
            (* Значение ниже диапазона аналогового входа *)
            stData.eStatus := STATUS_AI_BELOW_RANGE;
            stData.wErrorCode := stData.wErrorCode OR ERROR_AI_BELOW_RANGE;
            bValid := FALSE;
            
        ERR_VOLTAGE_BREAK:
            (* Обрыв линии датчика *)
            stData.eStatus := STATUS_WIRE_BREAK;
            stData.wErrorCode := stData.wErrorCode OR ERROR_WIRE_BREAK;
            bValid := FALSE;
            
        ERR_CURRENT_OVERLOAD:
            (* Перегрузка в канале измерения тока *)
            stData.eStatus := STATUS_CURRENT_OVERLOAD;
            stData.wErrorCode := stData.wErrorCode OR ERROR_CURRENT_OVERLOAD;
            bValid := FALSE;
            
        ERR_NOT_READY:
            (* Измерение не готово *)
            stData.eStatus := STATUS_NOT_READY;
            stData.wErrorCode := stData.wErrorCode OR ERROR_NOT_READY;
            bValid := FALSE;
            
        ELSE
            (* Прочие неизвестные ошибки *)
            stData.eStatus := STATUS_UNKNOWN;
            stData.wErrorCode := stData.wErrorCode OR ERROR_UNKNOWN;
            bValid := FALSE;
    END_CASE;
    
    (* Проверка на превышение максимально допустимого давления *)
    IF rPressureKPa > rMaxPressureKPa AND rMaxPressureKPa > 0.0 AND bValid THEN
        (* Выставляем ошибку превышения давления *)
        stData.eStatus := STATUS_VALUE_ABOVE_MAX;
        stData.wErrorCode := stData.wErrorCode OR ERROR_VALUE_ABOVE_MAX;
        bValid := FALSE;
    END_IF;
    
    (* Установка флага валидности *)
    stData.bValid := bValid;
END_IF;

(* Сброс ошибок по внешнему сигналу *)
IF bReset THEN
    stData.eStatus := STATUS_OK;
    stData.wErrorCode := ERROR_NONE;
    stData.bValid := TRUE;
END_IF;