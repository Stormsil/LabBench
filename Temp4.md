(*========================================================================
    Название:    FB_HeaterDiagnostics
    Автор:       
    Дата:        2025-01-27
    Версия:      1.0
    Описание:    Функциональный блок диагностики состояния ТЭНа
========================================================================*)

FUNCTION_BLOCK FB_HeaterDiagnostics
VAR_INPUT
    xEnable : BOOL;                 (* Разрешение диагностики *)
    xCommOK : BOOL;                 (* Связь с ТРМ10 в норме *)
    wTRM10Status : WORD;            (* Регистр статуса ТРМ10 *)
    eCurrentError : E_HeaterError;  (* Текущая ошибка *)
    xReset : BOOL;                  (* Сброс счетчиков *)
END_VAR

VAR_OUTPUT
    stDiag : ST_HeaterDiag;         (* Структура диагностики *)
END_VAR

VAR
    (* Внутренние переменные *)
    xCommOKOld : BOOL;              (* Предыдущее состояние связи *)
    eLastErrorOld : E_HeaterError;  (* Предыдущая ошибка *)
    tonCommTimeout : TON;           (* Таймер таймаута связи *)
    rtGetTime : RTC;                (* Получение системного времени *)
END_VAR

(* Сброс диагностики *)
IF xReset THEN
    stDiag.iCommErrors := 0;
    stDiag.eLastError := HEATER_NO_ERROR;
    stDiag.sErrorText := '';
    RETURN;
END_IF

(* Проверка разрешения *)
IF NOT xEnable THEN
    RETURN;
END_IF

(* Обновление состояния связи *)
stDiag.xCommOK := xCommOK;
stDiag.wTRM10Status := wTRM10Status;

(* Подсчет ошибок связи *)
IF NOT xCommOK AND xCommOKOld THEN
    stDiag.iCommErrors := stDiag.iCommErrors + 1;
END_IF

(* Обновление информации об ошибке *)
IF eCurrentError <> eLastErrorOld AND eCurrentError <> HEATER_NO_ERROR THEN
    stDiag.eLastError := eCurrentError;
    
    (* Получение времени ошибки *)
    rtGetTime();
    stDiag.dtLastError := rtGetTime.CDT;
    
    (* Формирование текста ошибки *)
    CASE eCurrentError OF
        HEATER_NO_ERROR:
            stDiag.sErrorText := 'Нет ошибок';
            
        HEATER_ERR_COMM_TIMEOUT:
            stDiag.sErrorText := 'Потеря связи с ТРМ10';
            
        HEATER_ERR_SENSOR_FAULT:
            stDiag.sErrorText := 'Ошибка датчика температуры';
            
        HEATER_ERR_OVERTEMP:
            stDiag.sErrorText := 'Превышение максимальной температуры!';
            
        HEATER_ERR_LOOP_BREAK:
            stDiag.sErrorText := 'Обрыв контура регулирования';
            
        HEATER_ERR_TRM10_FAULT:
            stDiag.sErrorText := 'Внутренняя ошибка ТРМ10';
            
        HEATER_ERR_AUTOTUNE_FAIL:
            stDiag.sErrorText := 'Ошибка автонастройки';
            
        HEATER_ERR_INVALID_MODE:
            stDiag.sErrorText := 'Недопустимый режим работы';
            
        HEATER_ERR_INTERLOCK:
            stDiag.sErrorText := 'Активна блокировка безопасности';
            
    ELSE
        stDiag.sErrorText := 'Неизвестная ошибка';
    END_CASE
END_IF

(* Сохранение предыдущих значений *)
xCommOKOld := xCommOK;
eLastErrorOld := eCurrentError;