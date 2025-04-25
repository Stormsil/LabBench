(*==============================================================================
    Название:    FB_HydroLevelSensor
    Автор:       Редько А.
    Дата:        2025-04-24
    Версия:      1.0
    
    Описание:    Функциональный блок для гидростатического датчика уровня.
                 Преобразует давление в уровень, контролирует превышение максимума.
==============================================================================*)
FUNCTION_BLOCK FB_HydroLevelSensor
VAR_INPUT
    rPressurePa: REAL;             (* Давление от датчика, Па *)
    rMaxAllowedLevelMM: REAL;      (* Максимально допустимый уровень, мм *)
    rDensity: REAL := 1000.0;      (* Плотность жидкости, кг/м? *)
    rGravity: REAL := 9.81;        (* Ускорение свободного падения, м/с? *)
    rZeroOffset: REAL := 0.0;      (* Смещение нуля, Па *)
    rLevelOffset: REAL := 0.0;     (* Смещение уровня, мм (если датчик ниже дна) *)
    rDampingTime: REAL := 0.2;     (* Время демпфирования, с (0=без фильтрации) *)
    bEnable: BOOL := TRUE;         (* Разрешение работы *)
    bReset: BOOL;                  (* Сброс ошибок *)
END_VAR

VAR_OUTPUT
    stData: ST_HydroLevel_Data;    (* Структура с результатами *)
END_VAR

VAR
    (* Внутренние переменные *)
    rFilteredPressurePa: REAL;     (* Отфильтрованное значение давления *)
    bFirstScan: BOOL := TRUE;      (* Флаг первого цикла *)
    wInternalError: WORD;          (* Внутренний код ошибки *)
    rDampingFactor: REAL;          (* Коэффициент демпфирования *)
END_VAR

VAR CONSTANT
    (* Константы для битов ошибок *)
    ERROR_NONE: WORD := 16#0000;
    ERROR_ABOVE_RANGE: WORD := 16#0002;
    ERROR_WIRE_BREAK: WORD := 16#0004;
    ERROR_CONFIG: WORD := 16#0020;
END_VAR

(* ======================================================================== *)
(* Основная логика функционального блока                                    *)
(* ======================================================================== *)

(* Инициализация *)
wInternalError := ERROR_NONE;
stData.bValid := FALSE;

(* Проверка конфигурации *)
IF rMaxAllowedLevelMM <= 0.0 OR
   rDensity <= 0.0 OR
   rGravity <= 0.0 THEN
    
    stData.eStatus := STATUS_CONFIG_ERROR;
    wInternalError := ERROR_CONFIG;
    
ELSIF NOT bEnable THEN
    (* Блок отключен *)
    stData.eStatus := STATUS_OK;
    stData.rLevelMM := 0.0;
    stData.wErrorCode := ERROR_NONE;
    stData.bValid := FALSE;
    
ELSE
    (* Нормальная работа *)
    
    (* Проверка на обрыв линии *)
    IF rPressurePa < -1000.0 THEN (* Значение ниже допустимого для датчика *)
        stData.eStatus := STATUS_WIRE_BREAK;
        wInternalError := ERROR_WIRE_BREAK;
        rFilteredPressurePa := 0.0;
    ELSE
        (* Фильтрация входного сигнала *)
        IF bFirstScan THEN
            rFilteredPressurePa := rPressurePa;
        ELSIF rDampingTime <= 0.0 THEN
            (* Без фильтрации *)
            rFilteredPressurePa := rPressurePa;
        ELSE
            (* Расчет коэффициента демпфирования *)
            rDampingFactor := 0.1 / MAX(rDampingTime, 0.01);
            (* Фильтр нижних частот первого порядка *)
            rFilteredPressurePa := rFilteredPressurePa + 
                                  (rPressurePa - rFilteredPressurePa) * rDampingFactor;
        END_IF;
        
        (* Нормальный статус по умолчанию *)
        stData.eStatus := STATUS_OK;
    END_IF;
    
    (* Компенсация смещения нуля *)
    rFilteredPressurePa := rFilteredPressurePa - rZeroOffset;
    
    (* Расчет уровня по гидростатической формуле: h = P / (? * g) *)
    (* Проверка деления на ноль *)
    IF rDensity * rGravity > 0.001 THEN
        (* Перевод метров в миллиметры (умножение на 1000) *)
        stData.rLevelMM := (rFilteredPressurePa / (rDensity * rGravity)) * 1000.0;
    ELSE
        stData.rLevelMM := 0.0;
    END_IF;
    
    (* Добавление смещения уровня (для коррекции положения датчика) *)
    stData.rLevelMM := stData.rLevelMM + rLevelOffset;
    
    (* Ограничение только для минимального уровня *)
    stData.rLevelMM := MAX(0.0, stData.rLevelMM);
    
    (* Проверка на превышение максимально допустимого уровня емкости *)
    IF stData.rLevelMM > rMaxAllowedLevelMM AND rMaxAllowedLevelMM > 0.0 THEN
        stData.eStatus := STATUS_ABOVE_RANGE;
        wInternalError := ERROR_ABOVE_RANGE;
    END_IF;
    
    (* Валидация данных - уровень допустим, но при этом нет ошибок *)
    stData.bValid := (stData.eStatus = STATUS_OK);
END_IF;

(* Запись кода ошибки в выходную структуру *)
stData.wErrorCode := wInternalError;

(* Сброс ошибок *)
IF bReset THEN
    stData.eStatus := STATUS_OK;
    stData.wErrorCode := ERROR_NONE;
END_IF;

(* Сброс флага первого цикла *)
bFirstScan := FALSE;