(*==============================================================================
    Название:    FB_HydroLevelSensor
    Автор:       Редько А.
    Дата:        2025-04-25
    Версия:      1.1
    
    Описание:    Функциональный блок для гидростатического
                 датчика уровня.
                 
                 Входные сигналы получены после масштабирования в конфигурации ПЛК.
                 Блок пересчитывает давление в уровень жидкости (мм).
                 
==============================================================================*)
FUNCTION_BLOCK FB_HydroLevelSensor
VAR_INPUT
    rPressurePa: REAL;             (* Давление от датчика после масштабирования, Па *)
    rMaxAllowedLevelMM: REAL;      (* Максимально допустимый уровень, мм *)
    rDensity: REAL := 1000.0;      (* Плотность жидкости, кг/м³ *)
    rGravity: REAL := 9.81;        (* Ускорение свободного падения, м/с² *)
    rLevelOffset: REAL := 0.0;     (* Смещение уровня, мм (если датчик ниже дна) *)
    bEnable: BOOL := TRUE;         (* Разрешение работы *)
    bReset: BOOL;                  (* Сброс ошибок *)
END_VAR
VAR_OUTPUT
    stData: ST_HydroLevel_Data;    (* Структура с результатами *)
END_VAR
VAR
    (* Системные переменные *)
    byStatus: BYTE;                (* Старший байт из %IR - статус аналогового входа *)
    bValid: BOOL;                  (* Флаг валидности данных *)
    rCalculatedLevelMM: REAL;      (* Вычисленный уровень до проверок *)
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
    
    (* Битовая маска для кодов ошибок *)
    ERR_CONFIG: WORD := 16#0001;           (* Ошибка конфигурации *)
    ERR_LEVEL_ABOVE_MAX: WORD := 16#0002;  (* Превышение макс. допустимого уровня *)
    ERR_AI_ABOVE_RANGE: WORD := 16#0004;   (* Превышение диапазона аналогового входа *)
    ERR_AI_BELOW_RANGE: WORD := 16#0008;   (* Значение ниже диапазона аналогового входа *)
    ERR_WIRE_BREAK: WORD := 16#0010;       (* Обрыв линии датчика *)
    ERR_CURRENT_OVERLOAD_MASK: WORD := 16#0020; (* Перегрузка в канале измерения тока *)
    ERR_NOT_READY_MASK: WORD := 16#0040;   (* Измерение не готово *)
    ERR_UNKNOWN: WORD := 16#8000;          (* Неизвестная ошибка *)
END_VAR

(* ======================================================================== *)
(* Основная логика функционального блока                                    *)
(* ======================================================================== *)

(* Инициализация *)
stData.rRawPressurePa := rPressurePa;  (* Сохраняем исходное значение для диагностики *)
stData.wErrorCode := 0;
stData.bValid := FALSE;
bValid := FALSE;

(* Проверка конфигурации *)
IF rMaxAllowedLevelMM <= 0.0 THEN
    (* Некорректно задан максимальный допустимый уровень *)
    stData.eStatus := STATUS_CONFIG_ERROR;
    stData.wErrorCode := stData.wErrorCode OR ERR_CONFIG;
    
ELSIF rDensity <= 0.0 THEN
    (* Некорректно задана плотность жидкости *)
    stData.eStatus := STATUS_CONFIG_ERROR;
    stData.wErrorCode := stData.wErrorCode OR ERR_CONFIG;
    
ELSIF rGravity <= 0.0 THEN
    (* Некорректно задано ускорение свободного падения *)
    stData.eStatus := STATUS_CONFIG_ERROR;
    stData.wErrorCode := stData.wErrorCode OR ERR_CONFIG;
    
ELSIF NOT bEnable THEN
    (* Блок отключен - возвращаем нулевые значения *)
    stData.eStatus := STATUS_OK;
    stData.rLevelMM := 0.0;
    stData.rLevelPercent := 0.0;
    stData.wErrorCode := 0;
    stData.bValid := FALSE;
    
ELSE
    (* Нормальная работа - обработка данных и проверка ошибок *)
    
    (* Получение старшего байта для анализа статуса *)
    byStatus := DWORD_TO_BYTE(SHR(REAL_TO_DWORD(rPressurePa) AND 16#FF000000, 24));
    
    (* Проверка статуса аналогового входа *)
    CASE byStatus OF
        ERR_NONE:
            (* Нормальные данные - статус OK *)
            stData.eStatus := STATUS_OK;
            bValid := TRUE;
            
        ERR_ABOVE_RANGE:
            (* Превышение диапазона аналогового входа *)
            stData.eStatus := STATUS_AI_ABOVE_RANGE;
            stData.wErrorCode := stData.wErrorCode OR ERR_AI_ABOVE_RANGE;
            bValid := FALSE;
            
        ERR_BELOW_RANGE:
            (* Значение ниже диапазона аналогового входа *)
            stData.eStatus := STATUS_AI_BELOW_RANGE;
            stData.wErrorCode := stData.wErrorCode OR ERR_AI_BELOW_RANGE;
            bValid := FALSE;
            
        ERR_VOLTAGE_BREAK:
            (* Обрыв линии датчика *)
            stData.eStatus := STATUS_WIRE_BREAK;
            stData.wErrorCode := stData.wErrorCode OR ERR_WIRE_BREAK;
            bValid := FALSE;
            
        ERR_CURRENT_OVERLOAD:
            (* Перегрузка в канале измерения тока *)
            stData.eStatus := STATUS_CURRENT_OVERLOAD;
            stData.wErrorCode := stData.wErrorCode OR ERR_CURRENT_OVERLOAD_MASK;
            bValid := FALSE;
            
        ERR_NOT_READY:
            (* Измерение не готово *)
            stData.eStatus := STATUS_NOT_READY;
            stData.wErrorCode := stData.wErrorCode OR ERR_NOT_READY_MASK;
            bValid := FALSE;
            
        ELSE
            (* Прочие неизвестные ошибки *)
            stData.eStatus := STATUS_UNKNOWN;
            stData.wErrorCode := stData.wErrorCode OR ERR_UNKNOWN;
            bValid := FALSE;
    END_CASE;
    
    (* Расчет уровня по гидростатической формуле: h = P / (ρ * g) *)
    (* Проверка деления на ноль *)
    IF rDensity * rGravity > 0.001 THEN
        (* Перевод метров в миллиметры (умножение на 1000) *)
        rCalculatedLevelMM := (rPressurePa / (rDensity * rGravity)) * 1000.0;
        
        (* Добавление смещения уровня (для коррекции положения датчика) *)
        rCalculatedLevelMM := rCalculatedLevelMM + rLevelOffset;
        
        (* Ограничение снизу нулем - уровень не может быть отрицательным *)
        stData.rLevelMM := MAX(0.0, rCalculatedLevelMM);
        
        (* Расчет процентного значения от максимального уровня *)
        IF rMaxAllowedLevelMM > 0.0 THEN
            stData.rLevelPercent := (stData.rLevelMM / rMaxAllowedLevelMM) * 100.0;
        ELSE
            stData.rLevelPercent := 0.0;
        END_IF;
    ELSE
        (* Ошибка деления на ноль из-за конфигурации *)
        stData.rLevelMM := 0.0;
        stData.rLevelPercent := 0.0;
        stData.eStatus := STATUS_CONFIG_ERROR;
        stData.wErrorCode := stData.wErrorCode OR ERR_CONFIG;
        bValid := FALSE;
    END_IF;
    
    (* Проверка на превышение максимально допустимого уровня емкости *)
    IF stData.rLevelMM > rMaxAllowedLevelMM AND rMaxAllowedLevelMM > 0.0 AND bValid THEN
        (* Выставляем ошибку превышения физического уровня *)
        stData.eStatus := STATUS_LEVEL_ABOVE_MAX;
        stData.wErrorCode := stData.wErrorCode OR ERR_LEVEL_ABOVE_MAX;
        bValid := FALSE;
    END_IF;
    
    (* Установка флага валидности *)
    stData.bValid := bValid;
END_IF;

(* Сброс ошибок по внешнему сигналу *)
IF bReset THEN
    stData.eStatus := STATUS_OK;
    stData.wErrorCode := 0;
    stData.bValid := TRUE;
END_IF;