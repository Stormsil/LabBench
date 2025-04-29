(*==============================================================================
    Название:    FB_FloatLevelSensorGroup
    Автор:       Инженер ПЛК
    Дата:        2025-04-26
    Версия:      1.0
    
    Описание:    Функциональный блок для группы поплавковых датчиков уровня.
                 Группа состоит из трех датчиков, расположенных на различных
                 уровнях в емкости высотой 500 мм:
                 - Нижний: 150 мм
                 - Средний: 250 мм
                 - Верхний: 350 мм
                 
                 Блок обрабатывает сигналы с датчиков, определяет текущий
                 уровень жидкости и проверяет корректность показаний.
==============================================================================*)
FUNCTION_BLOCK FB_FloatLevelSensorGroup
VAR_INPUT
    bLowLevelSensor: BOOL;      (* Сигнал с нижнего датчика (150 мм) *)
    bMidLevelSensor: BOOL;      (* Сигнал со среднего датчика (250 мм) *)
    bHighLevelSensor: BOOL;     (* Сигнал с верхнего датчика (350 мм) *)
    rTankHeightMM: REAL := 500.0; (* Высота емкости, мм *)
    bEnable: BOOL := TRUE;      (* Разрешение работы *)
    bReset: BOOL;               (* Сброс ошибок *)
END_VAR
VAR_OUTPUT
    stData: ST_FloatLevelGroup_Data; (* Структура с результатами *)
END_VAR
VAR
    (* Параметры датчиков *)
    rLowLevelHeightMM: REAL := 150.0;  (* Высота нижнего датчика, мм *)
    rMidLevelHeightMM: REAL := 250.0;  (* Высота среднего датчика, мм *)
    rHighLevelHeightMM: REAL := 350.0; (* Высота верхнего датчика, мм *)
    
    (* Внутренние переменные *)
    bValid: BOOL;                      (* Флаг валидности данных *)
    bSensorSequenceValid: BOOL;        (* Флаг валидности последовательности *)
END_VAR
VAR CONSTANT
    (* Битовая маска для кодов ошибок *)
    ERR_NONE: WORD := 16#0000;              (* Нет ошибок *)
    ERR_CONFIG: WORD := 16#0001;            (* Ошибка конфигурации *)
    ERR_INVALID_SEQUENCE: WORD := 16#0002;  (* Нарушена последовательность срабатывания *)
    ERR_WIRE_BREAK: WORD := 16#0004;        (* Обрыв линии или неисправность *)
    ERR_SENSOR_FAULT: WORD := 16#0008;      (* Неисправность датчика *)
END_VAR

(* ======================================================================== *)
(* Основная логика функционального блока                                    *)
(* ======================================================================== *)

(* Инициализация *)
stData.bLowLevelActive := FALSE;
stData.bMidLevelActive := FALSE;
stData.bHighLevelActive := FALSE;
stData.wErrorCode := ERR_NONE;
stData.bValid := FALSE;
bValid := FALSE;

(* Проверка конфигурации *)
IF rTankHeightMM <= 0.0 THEN
    (* Некорректно задана высота емкости *)
    stData.eStatus := STATUS_CONFIG_ERROR;
    stData.wErrorCode := stData.wErrorCode OR ERR_CONFIG;
    
ELSIF rLowLevelHeightMM <= 0.0 OR rMidLevelHeightMM <= 0.0 OR rHighLevelHeightMM <= 0.0 THEN
    (* Некорректно заданы высоты датчиков *)
    stData.eStatus := STATUS_CONFIG_ERROR;
    stData.wErrorCode := stData.wErrorCode OR ERR_CONFIG;
    
ELSIF rLowLevelHeightMM >= rMidLevelHeightMM OR rMidLevelHeightMM >= rHighLevelHeightMM THEN
    (* Нарушена последовательность высот датчиков *)
    stData.eStatus := STATUS_CONFIG_ERROR;
    stData.wErrorCode := stData.wErrorCode OR ERR_CONFIG;
    
ELSIF rHighLevelHeightMM >= rTankHeightMM THEN
    (* Верхний датчик выше высоты емкости *)
    stData.eStatus := STATUS_CONFIG_ERROR;
    stData.wErrorCode := stData.wErrorCode OR ERR_CONFIG;
    
ELSIF NOT bEnable THEN
    (* Блок отключен - возвращаем нулевые значения *)
    stData.eStatus := STATUS_OK;
    stData.rLevelEstimationMM := 0.0;
    stData.rLevelPercent := 0.0;
    stData.wErrorCode := ERR_NONE;
    stData.bValid := FALSE;
    
ELSE
    (* Нормальная работа - обработка сигналов датчиков *)
    
    (* Копируем состояния датчиков *)
    stData.bLowLevelActive := bLowLevelSensor;
    stData.bMidLevelActive := bMidLevelSensor;
    stData.bHighLevelActive := bHighLevelSensor;
    
    (* Проверка последовательности срабатывания датчиков *)
    (* Если верхний датчик активен, средний и нижний тоже должны быть активны *)
    (* Если средний датчик активен, нижний тоже должен быть активен *)
    bSensorSequenceValid := TRUE;
    
    IF stData.bHighLevelActive AND (NOT stData.bMidLevelActive OR NOT stData.bLowLevelActive) THEN
        (* Верхний датчик активен, но средний или нижний - нет *)
        bSensorSequenceValid := FALSE;
    ELSIF stData.bMidLevelActive AND NOT stData.bLowLevelActive THEN
        (* Средний датчик активен, но нижний - нет *)
        bSensorSequenceValid := FALSE;
    END_IF;
    
    IF NOT bSensorSequenceValid THEN
        (* Нарушена последовательность срабатывания датчиков *)
        stData.eStatus := STATUS_INVALID_SEQUENCE;
        stData.wErrorCode := stData.wErrorCode OR ERR_INVALID_SEQUENCE;
        bValid := FALSE;
    ELSE
        (* Последовательность корректна - определяем уровень *)
        bValid := TRUE;
        
        (* Устанавливаем базовый статус *)
        stData.eStatus := STATUS_OK;
        
        (* Оценка уровня на основе активных датчиков *)
        IF stData.bHighLevelActive THEN
            (* Все три датчика активны - высокий уровень *)
            stData.rLevelEstimationMM := rHighLevelHeightMM;
        ELSIF stData.bMidLevelActive THEN
            (* Активны нижний и средний датчики - средний уровень *)
            stData.rLevelEstimationMM := rMidLevelHeightMM;
        ELSIF stData.bLowLevelActive THEN
            (* Активен только нижний датчик - низкий уровень *)
            stData.rLevelEstimationMM := rLowLevelHeightMM;
        ELSE
            (* Ни один датчик не активен - уровень ниже нижнего датчика *)
            stData.rLevelEstimationMM := rLowLevelHeightMM / 2.0; (* Примерная оценка - половина высоты нижнего датчика *)
        END_IF;
        
        (* Расчет процентного значения от максимальной высоты *)
        IF rTankHeightMM > 0.0 THEN
            stData.rLevelPercent := (stData.rLevelEstimationMM / rTankHeightMM) * 100.0;
        ELSE
            stData.rLevelPercent := 0.0;
        END_IF;
    END_IF;
    
    (* Установка флага валидности *)
    stData.bValid := bValid;
END_IF;

(* Сброс ошибок по внешнему сигналу *)
IF bReset THEN
    stData.eStatus := STATUS_OK;
    stData.wErrorCode := ERR_NONE;
    stData.bValid := TRUE;
END_IF;