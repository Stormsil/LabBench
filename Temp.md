(*========================================================================
    Название:    Типы данных для системы управления ТЭНом
    Автор:       
    Дата:        2025-01-27
    Версия:      1.0
    Описание:    Перечисления и структуры для ФБ управления ТЭНом
========================================================================*)

(* Перечисление режимов работы ТЭНа *)
TYPE E_HeaterMode :
(
    HEATER_MODE_OOS := 0,        (* Out of Service - выведен из эксплуатации *)
    HEATER_MODE_STOP := 1,       (* Остановлен *)
    HEATER_MODE_MANUAL := 2,     (* Ручной режим *)
    HEATER_MODE_AUTO := 3        (* Автоматический режим *)
);
END_TYPE

(* Перечисление режимов ТРМ10 *)
TYPE E_TRM10Mode :
(
    TRM10_STOP := 0,    (* Режим STOP *)
    TRM10_RUN := 1,     (* Режим RUN *)
    TRM10_MANUAL := 2   (* Режим MANUAL *)
);
END_TYPE

(* Перечисление состояний машины состояний *)
TYPE E_HeaterState :
(
    STATE_INIT := 0,
    STATE_OUT_OF_SERVICE := 1,
    STATE_READY := 2,
    STATE_STOP := 3,
    STATE_MANUAL := 4,
    STATE_AUTO := 5,
    STATE_AUTOTUNE := 6,
    STATE_ERROR := 7
);
END_TYPE

(* Перечисление ошибок *)
TYPE E_HeaterError :
(
    HEATER_NO_ERROR := 0,
    HEATER_ERR_COMM_TIMEOUT := 1,      (* Потеря связи с ТРМ10 *)
    HEATER_ERR_SENSOR_FAULT := 2,      (* Ошибка датчика температуры *)
    HEATER_ERR_OVERTEMP := 3,          (* Перегрев *)
    HEATER_ERR_LOOP_BREAK := 4,        (* Обрыв контура *)
    HEATER_ERR_TRM10_FAULT := 5,       (* Внутренняя ошибка ТРМ10 *)
    HEATER_ERR_AUTOTUNE_FAIL := 6,     (* Ошибка автонастройки *)
    HEATER_ERR_INVALID_MODE := 7,      (* Недопустимый режим работы *)
    HEATER_ERR_INTERLOCK := 8          (* Активна блокировка безопасности *)
);
END_TYPE

(* Структура настроек ПИД *)
TYPE ST_PIDSettings :
STRUCT
    rP : REAL := 10.0;              (* Полоса пропорциональности *)
    iI : INT := 100;                (* Интегральная постоянная, сек *)
    iD : INT := 25;                 (* Дифференциальная постоянная, сек *)
    iPeriod : INT := 2;             (* Период импульсов, сек *)
    rDeadBand : REAL := 0.5;        (* Зона нечувствительности *)
    rOutMin : REAL := 0.0;          (* Минимальная мощность, % *)
    rOutMax : REAL := 100.0;        (* Максимальная мощность, % *)
    rOutRate : REAL := 10.0;        (* Скорость изменения мощности, %/с *)
    rErrorPower : REAL := 0.0;      (* Мощность в режиме ошибки, % *)
    rStopPower : REAL := 0.0;       (* Мощность в режиме стоп, % *)
END_STRUCT
END_TYPE

(* Структура ограничений *)
TYPE ST_HeaterLimits :
STRUCT
    rMaxTemp : REAL := 40.0;        (* Максимальная температура *)
    rMinSetpoint : REAL := 0.0;     (* Минимальная уставка *)
    rMaxSetpoint : REAL := 40.0;    (* Максимальная уставка *)
    rMaxPower : REAL := 100.0;      (* Максимальная мощность *)
    iLBATime : INT := 300;          (* Время обнаружения обрыва контура, сек *)
    rLBABand : REAL := 5.0;         (* Зона обнаружения обрыва *)
    rSetpointBand : REAL := 1.0;    (* Зона достижения уставки *)
END_STRUCT
END_TYPE

(* Структура статуса ТЭНа *)
TYPE ST_HeaterStatus :
STRUCT
    xOutOfService : BOOL;           (* Выведен из эксплуатации *)
    xEnabled : BOOL;                (* Разрешен *)
    xRunning : BOOL;                (* В работе *)
    eMode : E_HeaterMode;           (* Текущий режим *)
    eState : E_HeaterState;         (* Текущее состояние *)
    rTemperature : REAL;            (* Температура *)
    rSetpoint : REAL;               (* Уставка *)
    rPower : REAL;                  (* Мощность *)
    xAtSetpoint : BOOL;             (* Достигнута уставка *)
    xAutotuning : BOOL;             (* Идет автонастройка *)
    xAutotuneDone : BOOL;           (* Автонастройка завершена *)
    tStateTime : TIME;              (* Время в текущем состоянии *)
END_STRUCT
END_TYPE

(* Структура диагностики *)
TYPE ST_HeaterDiag :
STRUCT
    xCommOK : BOOL;                 (* Связь в норме *)
    iCommErrors : INT;              (* Счетчик ошибок связи *)
    wTRM10Status : WORD;            (* Статус ТРМ10 *)
    eLastError : E_HeaterError;     (* Последняя ошибка *)
    sErrorText : STRING(80);        (* Текст ошибки *)
    dtLastError : DATE_AND_TIME;    (* Время последней ошибки *)
    dwRunCount : DWORD;             (* Счетчик включений *)
    tTotalRunTime : TIME;           (* Общее время работы *)
    tLastRunTime : TIME;            (* Время последнего запуска *)
END_STRUCT
END_TYPE

(* Структура статуса ТРМ10 *)
TYPE ST_TRM10Status :
STRUCT
    (* Расшифровка битов регистра статуса *)
    xSensorError : BOOL;            (* Бит 0: Ошибка датчика *)
    xFunctionError : BOOL;          (* Бит 2: Ошибка функции *)
    xInternalError : BOOL;          (* Бит 4: Внутренняя ошибка *)
    xManualMode : BOOL;             (* Бит 7: Ручной режим *)
    xStopMode : BOOL;               (* Бит 8: Режим стоп *)
    xLoopBreak : BOOL;              (* Бит 9: Обрыв контура *)
    xAutotuning : BOOL;             (* Бит 11: Идет автонастройка *)
    xAutotuneDone : BOOL;           (* Бит 12: Автонастройка завершена *)
    
    (* Текущие параметры *)
    rTemperature : REAL;            (* Измеренная температура *)
    rSetpoint : REAL;               (* Текущая уставка *)
    rPower : REAL;                  (* Выходная мощность *)
    eMode : E_TRM10Mode;            (* Режим работы *)
    
    (* Параметры ПИД *)
    rCurrentP : REAL;               (* Текущая полоса пропорциональности *)
    iCurrentI : INT;                (* Текущая интегральная постоянная *)
    iCurrentD : INT;                (* Текущая дифференциальная постоянная *)
END_STRUCT
END_TYPE

(* Структура команд для ТРМ10 *)
TYPE ST_TRM10Command :
STRUCT
    xEnable : BOOL;                 (* Разрешение работы *)
    eMode : E_TRM10Mode;            (* Требуемый режим *)
    rSetpoint : REAL;               (* Уставка *)
    rManualPower : REAL;            (* Ручная мощность *)
    xStartAutotune : BOOL;          (* Запуск автонастройки *)
    xReset : BOOL;                  (* Сброс прибора *)
    stPID : ST_PIDSettings;         (* Настройки ПИД *)
END_STRUCT
END_TYPE