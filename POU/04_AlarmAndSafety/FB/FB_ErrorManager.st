(*==============================================================================
    Название:    FB_ErrorManager
    Автор:       
    Дата:        2025-04-28
    Версия:      1.0
    
    Описание:    Функциональный блок управления ошибками и блокировками
                 Обрабатывает ошибки различных категорий, управляет блокировками
                 оборудования и формирует сигналы для сигнальной лампы
==============================================================================*)
FUNCTION_BLOCK FB_ErrorManager
VAR_INPUT
    bResetAll: BOOL;                      (* Общий сброс всех ошибок *)
    bResetMeasurement: BOOL;              (* Сброс ошибок измерительной системы *)
    bResetPropValve: BOOL;                (* Сброс ошибок пропорционального клапана *)
    bResetEMValve: BOOL;                  (* Сброс ошибок электромагнитного клапана *)
    bResetPump1: BOOL;                    (* Сброс ошибок насоса 1 *)
    bResetPump2: BOOL;                    (* Сброс ошибок насоса 2 *)
END_VAR

VAR_OUTPUT
    bAnyError: BOOL;                      (* Флаг наличия любых ошибок *)
    bSystemBlocking: BOOL;                (* Флаг полной блокировки системы *)
    eLampMode: E_LampBlinkMode;           (* Режим работы сигнальной лампы *)
    dwActiveErrorMask: DWORD;             (* Битовая маска активных ошибок *)
    
    (* Блокировки устройств *)
    bPropValveBlocking: BOOL;             (* Блокировка пропорционального клапана *)
    bEMValveBlocking: BOOL;               (* Блокировка электромагнитного клапана *)
    bPump1Blocking: BOOL;                 (* Блокировка насоса 1 *)
    bPump2Blocking: BOOL;                 (* Блокировка насоса 2 *)
END_VAR

VAR
    (* Локальные переменные *)
    uiCounter: UINT;                      (* Счетчик для циклов *)
    bHasErrorCategory: ARRAY[0..4] OF BOOL; (* Флаги наличия ошибок по категориям *)
END_VAR

(* ======================================================================== *)
(* Основная логика функционального блока                                    *)
(* ======================================================================== *)

(* Обработка команд сброса ошибок *)
IF bResetAll THEN
    (* Сброс всех ошибок *)
    FOR uiCounter := 1 TO MAX_ERRORS DO
        gaBlockingErrors[uiCounter].bActive := FALSE;
    END_FOR;
ELSE
    (* Выборочный сброс ошибок *)
    IF bResetMeasurement THEN
        (* Сброс ошибок измерительной системы *)
        FOR uiCounter := 1 TO MAX_ERRORS DO
            IF gaBlockingErrors[uiCounter].eCategory = ERROR_MEASUREMENT THEN
                gaBlockingErrors[uiCounter].bActive := FALSE;
            END_IF;
        END_FOR;
    END_IF;
    
    IF bResetPropValve THEN
        (* Сброс ошибок пропорционального клапана *)
        FOR uiCounter := 1 TO MAX_ERRORS DO
            IF gaBlockingErrors[uiCounter].wDeviceID = PROP_VALVE_ID THEN
                gaBlockingErrors[uiCounter].bActive := FALSE;
            END_IF;
        END_FOR;
    END_IF;
    
    IF bResetEMValve THEN
        (* Сброс ошибок электромагнитного клапана *)
        FOR uiCounter := 1 TO MAX_ERRORS DO
            IF gaBlockingErrors[uiCounter].wDeviceID = EM_VALVE_ID THEN
                gaBlockingErrors[uiCounter].bActive := FALSE;
            END_IF;
        END_FOR;
    END_IF;
    
    IF bResetPump1 THEN
        (* Сброс ошибок насоса 1 *)
        FOR uiCounter := 1 TO MAX_ERRORS DO
            IF gaBlockingErrors[uiCounter].wDeviceID = PUMP1_ID THEN
                gaBlockingErrors[uiCounter].bActive := FALSE;
            END_IF;
        END_FOR;
    END_IF;
    
    IF bResetPump2 THEN
        (* Сброс ошибок насоса 2 *)
        FOR uiCounter := 1 TO MAX_ERRORS DO
            IF gaBlockingErrors[uiCounter].wDeviceID = PUMP2_ID THEN
                gaBlockingErrors[uiCounter].bActive := FALSE;
            END_IF;
        END_FOR;
    END_IF;
END_IF;

(* Сброс флагов *)
bAnyError := FALSE;
bSystemBlocking := FALSE;
dwActiveErrorMask := 0;
bPropValveBlocking := FALSE;
bEMValveBlocking := FALSE;
bPump1Blocking := FALSE;
bPump2Blocking := FALSE;

(* Сброс флагов категорий ошибок *)
FOR uiCounter := 0 TO 4 DO
    bHasErrorCategory[uiCounter] := FALSE;
END_FOR;

(* Обработка всех ошибок *)
FOR uiCounter := 1 TO MAX_ERRORS DO
    IF gaBlockingErrors[uiCounter].bActive THEN
        (* Ошибка активна *)
        bAnyError := TRUE;
        
        (* Установка бита в маске активных ошибок (только для первых 32 ошибок) *)
        IF uiCounter <= 32 THEN
            dwActiveErrorMask := dwActiveErrorMask OR SHL(DWORD#1, uiCounter-1);
        END_IF;
        
        (* Отметка категории ошибки *)
        bHasErrorCategory[ENUM_TO_DINT(gaBlockingErrors[uiCounter].eCategory)] := TRUE;
        
        (* Обработка блокировок *)
        CASE gaBlockingErrors[uiCounter].eBlockingLevel OF
            SYSTEM_BLOCKING:
                (* Полная блокировка системы *)
                bSystemBlocking := TRUE;
                
            DEVICE_BLOCKING:
                (* Блокировка конкретного устройства *)
                CASE gaBlockingErrors[uiCounter].wDeviceID OF
                    PROP_VALVE_ID:
                        bPropValveBlocking := TRUE;
                        
                    EM_VALVE_ID:
                        bEMValveBlocking := TRUE;
                        
                    PUMP1_ID:
                        bPump1Blocking := TRUE;
                        
                    PUMP2_ID:
                        bPump2Blocking := TRUE;
                END_CASE;
        END_CASE;
    END_IF;
END_FOR;

(* Определение режима работы сигнальной лампы *)
IF bAnyError THEN
    IF bHasErrorCategory[ENUM_TO_DINT(ERROR_MEASUREMENT)] THEN
        (* Ошибка измерения - быстрое мигание *)
        eLampMode := LAMP_FAST;
    ELSIF bHasErrorCategory[ENUM_TO_DINT(ERROR_COMMUNICATION)] THEN
        (* Ошибка связи - медленное мигание *)
        eLampMode := LAMP_SLOW;
    ELSIF bHasErrorCategory[ENUM_TO_DINT(ERROR_EQUIPMENT)] THEN
        (* Ошибка оборудования - постоянно горит *)
        eLampMode := LAMP_ON;
    ELSIF bHasErrorCategory[ENUM_TO_DINT(ERROR_PROCESS)] THEN
        (* Ошибка процесса - быстрое мигание *)
        eLampMode := LAMP_FAST;
    ELSE
        (* Неизвестная ошибка - постоянно горит *)
        eLampMode := LAMP_ON;
    END_IF;
ELSE
    (* Нет ошибок - лампа выключена *)
    eLampMode := LAMP_OFF;
END_IF;