(*==============================================================================
    Название:    FB_HydroLevelSensor
    Автор:       Редько А.
    Дата:        2025-04-25
    Версия:      1.2
    
    Описание:    Функциональный блок для гидростатического
                 датчика уровня.
                 
                 Входные сигналы получены после масштабирования в конфигурации ПЛК.
                 Блок пересчитывает давление в уровень жидкости (мм).
                 
                 Реализован как level-controlled (LCon) блок
==============================================================================*)
FUNCTION_BLOCK FB_HydroLevelSensor (* LCon *)
VAR_INPUT
    bEnable: BOOL := TRUE;         (* Разрешение работы *)
    rPressurePa: REAL;             (* Давление от датчика после масштабирования, Па *)
    rMaxAllowedLevelMM: REAL;      (* Максимально допустимый уровень, мм *)
    rDensity: REAL := 1000.0;      (* Плотность жидкости, кг/м³ *)
    rGravity: REAL := 9.81;        (* Ускорение свободного падения, м/с² *)
    rLevelOffset: REAL := 0.0;     (* Смещение уровня, мм (если датчик ниже дна) *)
    bReset: BOOL;                  (* Сброс ошибок *)
END_VAR
VAR_OUTPUT
    bValid: BOOL;                  (* Данные достоверны *)
    bError: BOOL;                  (* Флаг ошибки *)
    wErrorID: WORD;                (* Код ошибки *)
    rLevelMM: REAL;                (* Уровень в мм *)
    rLevelPercent: REAL;           (* Уровень в процентах от максимального *)
    rRawPressurePa: REAL;          (* Исходное значение давления *)
    eStatus: E_Inputs_Status;      (* Статус датчика *)
END_VAR
VAR
    (* Системные переменные *)
    byStatus: BYTE;                (* Старший байт из переменной для анализа статуса *)
    rCalculatedLevelMM: REAL;      (* Вычисленный уровень до проверок *)
    
    (* Структура для обратной совместимости *)
    stDataInternal: ST_HydroLevel_Data;
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
    ERROR_CONFIG: WORD := 16#0001;           (* Ошибка конфигурации *)
    ERROR_VALUE_ABOVE_MAX: WORD := 16#0002;  (* Превышение макс. допустимого уровня *)
    ERROR_AI_ABOVE_RANGE: WORD := 16#0004;   (* Превышение диапазона аналогового входа *)
    ERROR_AI_BELOW_RANGE: WORD := 16#0008;   (* Значение ниже диапазона аналогового входа *)
    ERROR_WIRE_BREAK: WORD := 16#0010;       (* Обрыв линии датчика *)
    ERROR_CURRENT_OVERLOAD_MASK: WORD := 16#0020; (* Перегрузка в канале измерения тока *)
    ERROR_NOT_READY_MASK: WORD := 16#0040;   (* Измерение не готово *)
    ERROR_UNKNOWN: WORD := 16#8000;          (* Неизвестная ошибка *)
END_VAR

(* ======================================================================== *)
(* Основная логика функционального блока                                    *)
(* ======================================================================== *)

(* Инициализация *)
rRawPressurePa := rPressurePa;  (* Сохраняем исходное значение для диагностики *)
wErrorID := 0;
bValid := FALSE;
bError := FALSE;

(* Проверка конфигурации *)
IF rMaxAllowedLevelMM <= 0.0 THEN
    (* Некорректно задан максимальный допустимый уровень *)
    eStatus := STATUS_CONFIG_ERROR;
    wErrorID := wErrorID OR ERROR_CONFIG;
    bError := TRUE;
    
ELSIF rDensity <= 0.0 THEN
    (* Некорректно задана плотность жидкости *)
    eStatus := STATUS_CONFIG_ERROR;
    wErrorID := wErrorID OR ERROR_CONFIG;
    bError := TRUE;
    
ELSIF rGravity <= 0.0 THEN
    (* Некорректно задано ускорение свободного падения *)
    eStatus := STATUS_CONFIG_ERROR;
    wErrorID := wErrorID OR ERROR_CONFIG;
    bError := TRUE;
    
ELSIF NOT bEnable THEN
    (* Блок отключен - возвращаем нулевые значения *)
    eStatus := STATUS_OK;
    rLevelMM := 0.0;
    rLevelPercent := 0.0;
    wErrorID := 0;
    bValid := FALSE;
    bError := FALSE;

ELSE
    (* Нормальная работа - обработка данных и проверка ошибок *)

    (* Получение старшего байта для анализа статуса *)
    byStatus := DWORD_TO_BYTE(SHR(REAL_TO_DWORD(rPressurePa) AND 16#FF000000, 24));

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
            wErrorID := wErrorID OR ERROR_CURRENT_OVERLOAD_MASK;
            bValid := FALSE;
            bError := TRUE;
            
        ERR_NOT_READY:
            (* Измерение не готово *)
            eStatus := STATUS_NOT_READY;
            wErrorID := wErrorID OR ERROR_NOT_READY_MASK;
            bValid := FALSE;
            bError := TRUE;
            
        ELSE
            (* Прочие неизвестные ошибки *)
            eStatus := STATUS_UNKNOWN;
            wErrorID := wErrorID OR ERROR_UNKNOWN;
            bValid := FALSE;
            bError := TRUE;
    END_CASE;
    
    (* Расчет уровня по гидростатической формуле: h = P / (ρ * g) *)
    (* Проверка деления на ноль *)
    IF rDensity * rGravity > 0.001 THEN
        (* Перевод метров в миллиметры (умножение на 1000) *)
        rCalculatedLevelMM := (rPressurePa / (rDensity * rGravity)) * 1000.0;
        
        (* Добавление смещения уровня (для коррекции положения датчика) *)
        rCalculatedLevelMM := rCalculatedLevelMM + rLevelOffset;
        
        (* Ограничение снизу нулем - уровень не может быть отрицательным *)
        rLevelMM := MAX(0.0, rCalculatedLevelMM);
        
        (* Расчет процентного значения от максимального уровня *)
        IF rMaxAllowedLevelMM > 0.0 THEN
            rLevelPercent := (rLevelMM / rMaxAllowedLevelMM) * 100.0;
        ELSE
            rLevelPercent := 0.0;
        END_IF;
    ELSE
        (* Ошибка деления на ноль из-за конфигурации *)
        rLevelMM := 0.0;
        rLevelPercent := 0.0;
        eStatus := STATUS_CONFIG_ERROR;
        wErrorID := wErrorID OR ERROR_CONFIG;
        bValid := FALSE;
        bError := TRUE;
    END_IF;
    
    (* Проверка на превышение максимально допустимого уровня емкости *)
    IF rLevelMM > rMaxAllowedLevelMM AND rMaxAllowedLevelMM > 0.0 THEN
        (* Выставляем ошибку превышения физического уровня *)
        eStatus := STATUS_VALUE_ABOVE_MAX;
        wErrorID := wErrorID OR ERROR_VALUE_ABOVE_MAX;
        bValid := FALSE;
        bError := TRUE;
    END_IF;
END_IF;

(* Сброс ошибок по внешнему сигналу *)
IF bReset THEN
    eStatus := STATUS_OK;
    wErrorID := 0;
    bValid := TRUE;
    bError := FALSE;
END_IF;

(* Заполнение структуры для обратной совместимости *)
stDataInternal.rLevelMM := rLevelMM;
stDataInternal.rLevelPercent := rLevelPercent;
stDataInternal.eStatus := eStatus;
stDataInternal.wErrorCode := wErrorID;
stDataInternal.bValid := bValid;
stDataInternal.rRawPressurePa := rRawPressurePa;