(*==============================================================================
    Название:    FB_FloatLevelSensorGroup
    Автор:       Редько А.
    Дата:        2025-04-26
    Версия:      1.1
    
    Описание:    Функциональный блок для группы поплавковых датчиков уровня.
                 Группа состоит из трех датчиков, расположенных на различных
                 уровнях в емкости высотой 500 мм:
                 - Нижний: 150 мм
                 - Средний: 250 мм
                 - Верхний: 350 мм
                 
                 Блок обрабатывает сигналы с датчиков, определяет текущий
                 уровень жидкости и проверяет корректность показаний.
                 
                 Реализован как level-controlled (LCon) блок
==============================================================================*)
FUNCTION_BLOCK FB_FloatLevelSensorGroup (* LCon *)
VAR_INPUT
    bEnable: BOOL := TRUE;      (* Разрешение работы *)
    bLowLevelSensor: BOOL;      (* Сигнал с нижнего датчика (150 мм) *)
    bMidLevelSensor: BOOL;      (* Сигнал со среднего датчика (250 мм) *)
    bHighLevelSensor: BOOL;     (* Сигнал с верхнего датчика (350 мм) *)
    rTankHeightMM: REAL := 500.0; (* Высота емкости, мм *)
    bReset: BOOL;               (* Сброс ошибок *)
END_VAR
VAR_OUTPUT
    bValid: BOOL;               (* Данные достоверны *)
    bError: BOOL;               (* Флаг ошибки *)
    wErrorID: WORD;             (* Код ошибки *)
    bLowLevelActive: BOOL;      (* Активен нижний датчик (150 мм) *)
    bMidLevelActive: BOOL;      (* Активен средний датчик (250 мм) *)
    bHighLevelActive: BOOL;     (* Активен верхний датчик (350 мм) *)
    eStatus: E_Inputs_Status;   (* Статус датчика *)
    rLevelEstimationMM: REAL;   (* Оценка текущего уровня в мм *)
    rLevelPercent: REAL;        (* Оценка уровня в процентах от максимального *)
END_VAR
VAR
    (* Параметры датчиков *)
    rLowLevelHeightMM: REAL := 150.0;  (* Высота нижнего датчика, мм *)
    rMidLevelHeightMM: REAL := 250.0;  (* Высота среднего датчика, мм *)
    rHighLevelHeightMM: REAL := 350.0; (* Высота верхнего датчика, мм *)
    
    (* Внутренние переменные *)
    bSensorSequenceValid: BOOL;        (* Флаг валидности последовательности *)
    stDataInternal: ST_FloatLevelGroup_Data; (* Внутренняя структура данных для обратной совместимости *)
END_VAR
VAR CONSTANT
    (* Битовая маска для кодов ошибок *)
    ERR_NONE: WORD := 16#0000;              (* Нет ошибок *)
    ERR_CONFIG: WORD := 16#0001;            (* Ошибка конфигурации *)
    ERR_INVALID_SEQUENCE: WORD := 16#0002;  (* Нарушена последовательность срабатывания *)
END_VAR

(* ======================================================================== *)
(* Основная логика функционального блока                                    *)
(* ======================================================================== *)

(* Инициализация *)
bLowLevelActive := FALSE;
bMidLevelActive := FALSE;
bHighLevelActive := FALSE;
wErrorID := ERR_NONE;
bValid := FALSE;
bError := FALSE;

(* Проверка конфигурации *)
IF rTankHeightMM <= 0.0 THEN
    (* Некорректно задана высота емкости *)
    eStatus := STATUS_CONFIG_ERROR;
    wErrorID := wErrorID OR ERR_CONFIG;
    bError := TRUE;
    
ELSIF rLowLevelHeightMM <= 0.0 OR rMidLevelHeightMM <= 0.0 OR rHighLevelHeightMM <= 0.0 THEN
    (* Некорректно заданы высоты датчиков *)
    eStatus := STATUS_CONFIG_ERROR;
    wErrorID := wErrorID OR ERR_CONFIG;
    bError := TRUE;
    
ELSIF rLowLevelHeightMM >= rMidLevelHeightMM OR rMidLevelHeightMM >= rHighLevelHeightMM THEN
    (* Нарушена последовательность высот датчиков *)
    eStatus := STATUS_CONFIG_ERROR;
    wErrorID := wErrorID OR ERR_CONFIG;
    bError := TRUE;
    
ELSIF rHighLevelHeightMM >= rTankHeightMM THEN
    (* Верхний датчик выше высоты емкости *)
    eStatus := STATUS_CONFIG_ERROR;
    wErrorID := wErrorID OR ERR_CONFIG;
    bError := TRUE;
    
ELSIF NOT bEnable THEN
    (* Блок отключен - возвращаем нулевые значения *)
    eStatus := STATUS_OK;
    rLevelEstimationMM := 0.0;
    rLevelPercent := 0.0;
    wErrorID := ERR_NONE;
    bValid := FALSE;
    bError := FALSE;
    
ELSE
    (* Нормальная работа - обработка сигналов датчиков *)
    
    (* Копируем состояния датчиков *)
    bLowLevelActive := bLowLevelSensor;
    bMidLevelActive := bMidLevelSensor;
    bHighLevelActive := bHighLevelSensor;
    
    (* Проверка последовательности срабатывания датчиков *)
    (* Если верхний датчик активен, средний и нижний тоже должны быть активны *)
    (* Если средний датчик активен, нижний тоже должен быть активен *)
    bSensorSequenceValid := TRUE;
    
    IF bHighLevelActive AND (NOT bMidLevelActive OR NOT bLowLevelActive) THEN
        (* Верхний датчик активен, но средний или нижний - нет *)
        bSensorSequenceValid := FALSE;
    ELSIF bMidLevelActive AND NOT bLowLevelActive THEN
        (* Средний датчик активен, но нижний - нет *)
        bSensorSequenceValid := FALSE;
    END_IF;
    
    IF NOT bSensorSequenceValid THEN
        (* Нарушена последовательность срабатывания датчиков *)
        eStatus := STATUS_INVALID_SEQUENCE;
        wErrorID := wErrorID OR ERR_INVALID_SEQUENCE;
        bValid := FALSE;
        bError := TRUE;
    ELSE
        (* Последовательность корректна - определяем уровень *)
        bValid := TRUE;
        bError := FALSE;
        
        (* Устанавливаем базовый статус *)
        eStatus := STATUS_OK;
        
        (* Оценка уровня на основе активных датчиков *)
        IF bHighLevelActive THEN
            (* Все три датчика активны - высокий уровень *)
            rLevelEstimationMM := rHighLevelHeightMM;
        ELSIF bMidLevelActive THEN
            (* Активны нижний и средний датчики - средний уровень *)
            rLevelEstimationMM := rMidLevelHeightMM;
        ELSIF bLowLevelActive THEN
            (* Активен только нижний датчик - низкий уровень *)
            rLevelEstimationMM := rLowLevelHeightMM;
        ELSE
            (* Ни один датчик не активен - уровень ниже нижнего датчика *)
            rLevelEstimationMM := rLowLevelHeightMM / 2.0; (* Примерная оценка - половина высоты нижнего датчика *)
        END_IF;
        
        (* Расчет процентного значения от максимальной высоты *)
        IF rTankHeightMM > 0.0 THEN
            rLevelPercent := (rLevelEstimationMM / rTankHeightMM) * 100.0;
        ELSE
            rLevelPercent := 0.0;
        END_IF;
    END_IF;
END_IF;

(* Сброс ошибок по внешнему сигналу *)
IF bReset THEN
    eStatus := STATUS_OK;
    wErrorID := ERR_NONE;
    bValid := TRUE;
    bError := FALSE;
END_IF;

(* Для обратной совместимости заполняем структуру stDataInternal *)
stDataInternal.bLowLevelActive := bLowLevelActive;
stDataInternal.bMidLevelActive := bMidLevelActive;
stDataInternal.bHighLevelActive := bHighLevelActive;
stDataInternal.eStatus := eStatus;
stDataInternal.rLevelEstimationMM := rLevelEstimationMM;
stDataInternal.rLevelPercent := rLevelPercent;
stDataInternal.wErrorCode := wErrorID;
stDataInternal.bValid := bValid;