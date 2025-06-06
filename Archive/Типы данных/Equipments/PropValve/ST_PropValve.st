(*==============================================================================
    Название:    ST_PropValve
    Автор:       Редько А.
    Дата:        2025-04-27
    Версия:      1.0
    
    Описание:    Основная структура данных пропорционального крана
==============================================================================*)
TYPE ST_PropValve :
STRUCT
    (* Основные данные о положении и состоянии *)
    rActualPosition: REAL;         (* Текущее положение (0-100%) *)
    rTargetPosition: REAL;         (* Целевое положение (0-100%) *)
    
    (* Статусы *)
    eMode: E_EquipmentMode;        (* Режим работы *)
    eState: E_PropValveState;      (* Состояние крана *)
    wErrorCode: WORD;              (* Код ошибки, битовая маска *)
    bValid: BOOL;                  (* Флаг достоверности данных *)
    bMoving: BOOL;                 (* Флаг движения *)
    
    (* Вложенные структуры *)
    stSettings: ST_PropValveSettings;  (* Настройки *)
    stCommands: ST_PropValveCommands;  (* Команды *)
END_STRUCT
END_TYPE