(*==============================================================================
    Название:    GVL_SCADA
    Автор:       Редько А.
    Дата:        2025-05-01
    Версия:      3.0
    
    Описание:    Глобальные переменные для интерфейса SCADA через OPC
                 - Оптимизированы типы данных для совместимости с OPC
                 - Используется явное управление режимами каждого устройства
                 - Heartbeat реализован как счетчик
                 
                 Структура именования:
                 - GVL_SCADA_in_* : переменные только для записи (SCADA -> ПЛК)
                 - GVL_SCADA_out_* : переменные только для чтения (ПЛК -> SCADA)
                 - GVL_SCADA_inout_* : переменные для чтения и записи
==============================================================================*)
VAR_GLOBAL
    (* ======== СИСТЕМНЫЕ ПЕРЕМЕННЫЕ ======== *)
    (* Системные команды (SCADA -> ПЛК) *)
    GVL_SCADA_in_System_ResetAllErrors: BOOL := FALSE;     (* Общий сброс всех ошибок *)
    
    (* Системные статусы (ПЛК -> SCADA) *)
    GVL_SCADA_out_System_Heartbeat: DWORD;                (* Счетчик Heartbeat, циклически увеличивается *)
    GVL_SCADA_out_System_CycleTime_ms: DINT;              (* Время цикла в мс *)
    GVL_SCADA_out_System_ErrorCode: WORD;                 (* Код ошибки системы *)
    GVL_SCADA_out_System_ErrorCount: DWORD;               (* Счетчик ошибок *)
    
    (* ======== ПРОПОРЦИОНАЛЬНЫЙ КРАН ======== *)
    (* Команды управления (SCADA -> ПЛК) *)
    GVL_SCADA_in_PropValve_Mode: DINT := 1;               (* Режим работы: 0=AUTO, 1=MANUAL, 2=DISABLED, 3=E_STOP *)
    GVL_SCADA_in_PropValve_SetPosition: REAL := 0.0;      (* Задание положения (0-100%) *)
    GVL_SCADA_in_PropValve_Reset: BOOL := FALSE;          (* Сброс ошибок *)
    
    (* Настройки (SCADA -> ПЛК) *)
    GVL_SCADA_in_PropValve_SafePosition: REAL := 0.0;     (* Безопасное положение (0-100%) *)
    GVL_SCADA_in_PropValve_CloseThreshold: REAL := 2.0;   (* Порог "закрыт" (%) *)
    GVL_SCADA_in_PropValve_OpenThreshold: REAL := 98.0;   (* Порог "открыт" (%) *)
    GVL_SCADA_in_PropValve_Deadband: REAL := 1.0;         (* Зона нечувствительности (%) *)
    GVL_SCADA_in_PropValve_PositionTimeout_ms: DINT := 8000; (* Таймаут позиционирования в мс *)
    GVL_SCADA_in_PropValve_StuckTimeout_ms: DINT := 5000;    (* Таймаут заклинивания в мс *)
    
    (* Текущие значения (ПЛК -> SCADA) *)
    GVL_SCADA_out_PropValve_ActualPosition: REAL;         (* Текущее положение (0-100%) *)
    GVL_SCADA_out_PropValve_TargetPosition: REAL;         (* Целевое положение (0-100%) *)
    GVL_SCADA_out_PropValve_Mode: DINT;                   (* Текущий режим: 0=AUTO, 1=MANUAL, 2=DISABLED, 3=E_STOP *)
    GVL_SCADA_out_PropValve_State: DINT;                  (* Состояние: 0=CLOSED, 1=OPENING, 2=OPEN, 3=CLOSING, 
                                                                         4=INTERMEDIATE, 5=REGULATING, 6=ERROR *)
    GVL_SCADA_out_PropValve_ErrorCode: WORD;              (* Код ошибки *)
    GVL_SCADA_out_PropValve_Valid: BOOL;                  (* Флаг достоверности данных *)
    GVL_SCADA_out_PropValve_Moving: BOOL;                 (* Флаг движения крана *)
    
    (* ======== ЭЛЕКТРОМАГНИТНЫЙ КЛАПАН ======== *)
    (* Команды управления (SCADA -> ПЛК) *)
    GVL_SCADA_in_EMValve_Mode: DINT := 1;                 (* Режим работы: 0=AUTO, 1=MANUAL, 2=DISABLED, 3=E_STOP *)
    GVL_SCADA_in_EMValve_Open: BOOL := FALSE;             (* Команда открытия в ручном режиме *)
    GVL_SCADA_in_EMValve_AutoOpen: BOOL := FALSE;         (* Команда от внешнего регулятора *)
    GVL_SCADA_in_EMValve_Reset: BOOL := FALSE;            (* Сброс счетчиков *)
    
    (* Настройки (SCADA -> ПЛК) *)
    GVL_SCADA_in_EMValve_WarningTime_ms: DINT := 900000;  (* Порог предупреждения в мс (15 мин) *)
    
    (* Текущие значения (ПЛК -> SCADA) *)
    GVL_SCADA_out_EMValve_IsOpen: BOOL;                   (* Текущее состояние *)
    GVL_SCADA_out_EMValve_Mode: DINT;                     (* Текущий режим: 0=AUTO, 1=MANUAL, 2=DISABLED, 3=E_STOP *)
    GVL_SCADA_out_EMValve_State: DINT;                    (* Состояние: 0=CLOSED, 1=OPEN, 2=LONG_OPERATION *)
    GVL_SCADA_out_EMValve_ContinuousOpTime_ms: DINT;      (* Время непрерывной работы в мс *)
    GVL_SCADA_out_EMValve_TotalOpTime_ms: DINT;           (* Общее время работы в мс *)
    GVL_SCADA_out_EMValve_WarningThreshold_ms: DINT;      (* Текущий порог предупреждения в мс *)
    
    (* ======== ДАТЧИКИ УРОВНЯ ======== *)
    (* Гидростатический датчик уровня КИЕ1 *)
    (* Настройки (SCADA -> ПЛК) *)
    GVL_SCADA_in_Level_KIE1_MaxLevelMM: REAL := 500.0;    (* Максимальный уровень, мм *)
    GVL_SCADA_in_Level_KIE1_Density: REAL := 1000.0;      (* Плотность жидкости, кг/м³ *)
    GVL_SCADA_in_Level_KIE1_LevelOffset: REAL := -1.0;    (* Смещение уровня, мм *)
    GVL_SCADA_in_Level_KIE1_Reset: BOOL := FALSE;         (* Сброс ошибок *)
    
    (* Текущие значения (ПЛК -> SCADA) *)
    GVL_SCADA_out_Level_KIE1_LevelMM: REAL;               (* Уровень в мм *)
    GVL_SCADA_out_Level_KIE1_LevelPercent: REAL;          (* Уровень в процентах *)
    GVL_SCADA_out_Level_KIE1_RawPressurePa: REAL;         (* Исходное давление в Па *)
    GVL_SCADA_out_Level_KIE1_Status: DINT;                (* Статус датчика *)
    GVL_SCADA_out_Level_KIE1_ErrorCode: WORD;             (* Код ошибки *)
    GVL_SCADA_out_Level_KIE1_Valid: BOOL;                 (* Достоверность данных *)
    
    (* Поплавковые датчики уровня *)
    (* Настройки (SCADA -> ПЛК) *)
    GVL_SCADA_in_FloatLevel_Reset: BOOL := FALSE;          (* Сброс ошибок *)
    
    (* Текущие значения (ПЛК -> SCADA) *)
    GVL_SCADA_out_FloatLevel_Low: BOOL;                   (* Состояние нижнего датчика *)
    GVL_SCADA_out_FloatLevel_Mid: BOOL;                   (* Состояние среднего датчика *)
    GVL_SCADA_out_FloatLevel_High: BOOL;                  (* Состояние верхнего датчика *)
    GVL_SCADA_out_FloatLevel_EstimationMM: REAL;          (* Оценка уровня в мм *)
    GVL_SCADA_out_FloatLevel_Percent: REAL;               (* Оценка уровня в процентах *)
    GVL_SCADA_out_FloatLevel_Status: DINT;                (* Статус датчиков *)
    GVL_SCADA_out_FloatLevel_ErrorCode: WORD;             (* Код ошибки *)
    GVL_SCADA_out_FloatLevel_Valid: BOOL;                 (* Достоверность данных *)
    
    (* ======== ДАТЧИКИ ДАВЛЕНИЯ ======== *)
    (* Общие настройки *)
    GVL_SCADA_in_Pressure_Reset: BOOL := FALSE;           (* Общий сброс ошибок датчиков давления *)
    
    (* Датчик в емкости КИЕ2 *)
    GVL_SCADA_in_Pressure_KIE2_MaxKPa: REAL := 200.0;     (* Максимальное давление, кПа *)
    GVL_SCADA_out_Pressure_KIE2_PressureKPa: REAL;        (* Давление в кПа *)
    GVL_SCADA_out_Pressure_KIE2_Status: DINT;             (* Статус датчика *)
    GVL_SCADA_out_Pressure_KIE2_ErrorCode: WORD;          (* Код ошибки *)
    GVL_SCADA_out_Pressure_KIE2_Valid: BOOL;              (* Достоверность данных *)
    
    (* Датчик в трубопроводе *)
    GVL_SCADA_in_Pressure_Pipe_MaxKPa: REAL := 300.0;     (* Максимальное давление, кПа *)
    GVL_SCADA_out_Pressure_Pipe_PressureKPa: REAL;        (* Давление в кПа *)
    GVL_SCADA_out_Pressure_Pipe_Status: DINT;             (* Статус датчика *)
    GVL_SCADA_out_Pressure_Pipe_ErrorCode: WORD;          (* Код ошибки *)
    GVL_SCADA_out_Pressure_Pipe_Valid: BOOL;              (* Достоверность данных *)
    
    (* Датчик перед насосом 1 *)
    GVL_SCADA_in_Pressure_PumpIn1_MaxKPa: REAL := 250.0;  (* Максимальное давление, кПа *)
    GVL_SCADA_out_Pressure_PumpIn1_PressureKPa: REAL;     (* Давление в кПа *)
    GVL_SCADA_out_Pressure_PumpIn1_Status: DINT;          (* Статус датчика *)
    GVL_SCADA_out_Pressure_PumpIn1_ErrorCode: WORD;       (* Код ошибки *)
    GVL_SCADA_out_Pressure_PumpIn1_Valid: BOOL;           (* Достоверность данных *)
    
    (* Датчик после насоса 1 *)
    GVL_SCADA_in_Pressure_PumpOut1_MaxKPa: REAL := 250.0; (* Максимальное давление, кПа *)
    GVL_SCADA_out_Pressure_PumpOut1_PressureKPa: REAL;    (* Давление в кПа *)
    GVL_SCADA_out_Pressure_PumpOut1_Status: DINT;         (* Статус датчика *)
    GVL_SCADA_out_Pressure_PumpOut1_ErrorCode: WORD;      (* Код ошибки *)
    GVL_SCADA_out_Pressure_PumpOut1_Valid: BOOL;          (* Достоверность данных *)
    
    (* Датчик перед насосом 2 *)
    GVL_SCADA_out_Pressure_PumpIn2_PressureKPa: REAL;     (* Давление в кПа *)
    GVL_SCADA_out_Pressure_PumpIn2_Status: DINT;          (* Статус датчика *)
    GVL_SCADA_out_Pressure_PumpIn2_ErrorCode: WORD;       (* Код ошибки *)
    GVL_SCADA_out_Pressure_PumpIn2_Valid: BOOL;           (* Достоверность данных *)
    
    (* Датчик после насоса 2 *)
    GVL_SCADA_out_Pressure_PumpOut2_PressureKPa: REAL;    (* Давление в кПа *)
    GVL_SCADA_out_Pressure_PumpOut2_Status: DINT;         (* Статус датчика *)
    GVL_SCADA_out_Pressure_PumpOut2_ErrorCode: WORD;      (* Код ошибки *)
    GVL_SCADA_out_Pressure_PumpOut2_Valid: BOOL;          (* Достоверность данных *)
    
    (* ======== РАСХОДОМЕРЫ ======== *)
    (* Общие настройки *)
    GVL_SCADA_in_Flow_Reset: BOOL := FALSE;               (* Общий сброс ошибок расходомеров *)
    
    (* Расходомер после насоса 1 *)
    GVL_SCADA_in_Flow_PumpOut1_Reset: BOOL := FALSE;      (* Сброс счетчика *)
    GVL_SCADA_out_Flow_PumpOut1_FlowLPM: REAL;            (* Расход в л/мин *)
    GVL_SCADA_out_Flow_PumpOut1_FlowM3H: REAL;            (* Расход в м³/ч *)
    GVL_SCADA_out_Flow_PumpOut1_TotalLiters: REAL;        (* Общий объем в литрах *)
    GVL_SCADA_out_Flow_PumpOut1_FrequencyHz: REAL;        (* Частота импульсов в Гц *)
    GVL_SCADA_out_Flow_PumpOut1_Status: DINT;             (* Статус датчика *)
    GVL_SCADA_out_Flow_PumpOut1_ErrorCode: WORD;          (* Код ошибки *)
    GVL_SCADA_out_Flow_PumpOut1_Valid: BOOL;              (* Достоверность данных *)
    
    (* Расходомер после насоса 2 *)
    GVL_SCADA_in_Flow_PumpOut2_Reset: BOOL := FALSE;      (* Сброс счетчика *)
    GVL_SCADA_out_Flow_PumpOut2_FlowLPM: REAL;            (* Расход в л/мин *)
    GVL_SCADA_out_Flow_PumpOut2_FlowM3H: REAL;            (* Расход в м³/ч *)
    GVL_SCADA_out_Flow_PumpOut2_TotalLiters: REAL;        (* Общий объем в литрах *)
    GVL_SCADA_out_Flow_PumpOut2_FrequencyHz: REAL;        (* Частота импульсов в Гц *)
    GVL_SCADA_out_Flow_PumpOut2_Status: DINT;             (* Статус датчика *)
    GVL_SCADA_out_Flow_PumpOut2_ErrorCode: WORD;          (* Код ошибки *)
    GVL_SCADA_out_Flow_PumpOut2_Valid: BOOL;              (* Достоверность данных *)
    
    (* Расходомер в трубопроводе *)
    GVL_SCADA_in_Flow_Pipe_Reset: BOOL := FALSE;          (* Сброс счетчика *)
    GVL_SCADA_out_Flow_Pipe_FlowLPM: REAL;                (* Расход в л/мин *)
    GVL_SCADA_out_Flow_Pipe_FlowM3H: REAL;                (* Расход в м³/ч *)
    GVL_SCADA_out_Flow_Pipe_TotalLiters: REAL;            (* Общий объем в литрах *)
    GVL_SCADA_out_Flow_Pipe_FrequencyHz: REAL;            (* Частота импульсов в Гц *)
    GVL_SCADA_out_Flow_Pipe_Status: DINT;                 (* Статус датчика *)
    GVL_SCADA_out_Flow_Pipe_ErrorCode: WORD;              (* Код ошибки *)
    GVL_SCADA_out_Flow_Pipe_Valid: BOOL;                  (* Достоверность данных *)
END_VAR