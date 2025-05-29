(*========================================================================
    Название:    FB_HeaterStateMachine
    Автор:       
    Дата:        2025-01-27
    Версия:      1.0
    Описание:    Машина состояний для управления ТЭНом
========================================================================*)

FUNCTION_BLOCK FB_HeaterStateMachine
VAR_INPUT
    xEnable : BOOL;                 (* Разрешение работы *)
    eCommandMode : E_HeaterMode;    (* Требуемый режим работы *)
    xInterlockActive : BOOL;        (* Активна блокировка *)
    xCommOK : BOOL;                 (* Связь в норме *)
    xTRM10Ready : BOOL;             (* ТРМ10 готов *)
    xAutotuneComplete : BOOL;       (* Автонастройка завершена *)
    xAutotuneFailed : BOOL;         (* Ошибка автонастройки *)
    xError : BOOL;                  (* Общая ошибка *)
    xReset : BOOL;                  (* Сброс ошибок *)
END_VAR

VAR_OUTPUT
    eState : E_HeaterState;         (* Текущее состояние *)
    eMode : E_HeaterMode;           (* Текущий режим *)
    xStateChanged : BOOL;           (* Состояние изменилось *)
    tStateTime : TIME;              (* Время в текущем состоянии *)
    xAllowRun : BOOL;               (* Разрешение работы *)
    xAllowAutotune : BOOL;          (* Разрешение автонастройки *)
END_VAR

VAR
    (* Внутренние переменные *)
    eStateOld : E_HeaterState;      (* Предыдущее состояние *)
    tonStateTime : TON;             (* Таймер времени состояния *)
    xInitDone : BOOL;               (* Инициализация выполнена *)
END_VAR

(* Инициализация при первом вызове *)
IF NOT xInitDone THEN
    eState := STATE_INIT;
    eMode := HEATER_MODE_OOS;
    xInitDone := TRUE;
END_IF

(* Детектирование изменения состояния *)
xStateChanged := (eState <> eStateOld);
IF xStateChanged THEN
    tonStateTime(IN := FALSE);
END_IF

(* Счетчик времени в текущем состоянии *)
tonStateTime(IN := TRUE, PT := T#24h);
tStateTime := tonStateTime.ET;

(* Машина состояний *)
CASE eState OF
    STATE_INIT:
        (* Инициализация *)
        IF xEnable THEN
            eState := STATE_READY;
        END_IF
        
    STATE_OUT_OF_SERVICE:
        (* Выведен из эксплуатации *)
        eMode := HEATER_MODE_OOS;
        xAllowRun := FALSE;
        xAllowAutotune := FALSE;
        
        IF eCommandMode <> HEATER_MODE_OOS THEN
            eState := STATE_READY;
        END_IF
        
    STATE_READY:
        (* Готов к работе *)
        xAllowRun := FALSE;
        xAllowAutotune := FALSE;
        
        (* Проверка перехода в OOS *)
        IF eCommandMode = HEATER_MODE_OOS THEN
            eState := STATE_OUT_OF_SERVICE;
        (* Проверка ошибок *)
        ELSIF xError OR NOT xCommOK THEN
            eState := STATE_ERROR;
        (* Проверка разрешения и режима *)
        ELSIF xEnable AND NOT xInterlockActive THEN
            CASE eCommandMode OF
                HEATER_MODE_STOP:
                    eState := STATE_STOP;
                HEATER_MODE_MANUAL:
                    eState := STATE_MANUAL;
                HEATER_MODE_AUTO:
                    eState := STATE_AUTO;
            END_CASE
        END_IF
        
    STATE_STOP:
        (* Режим СТОП *)
        eMode := HEATER_MODE_STOP;
        xAllowRun := FALSE;
        xAllowAutotune := TRUE;
        
        (* Проверка условий перехода *)
        IF NOT xEnable THEN
            eState := STATE_READY;
        ELSIF eCommandMode = HEATER_MODE_OOS THEN
            eState := STATE_OUT_OF_SERVICE;
        ELSIF xError OR NOT xCommOK THEN
            eState := STATE_ERROR;
        ELSIF xInterlockActive THEN
            eState := STATE_ERROR;
        ELSIF eCommandMode = HEATER_MODE_MANUAL AND xTRM10Ready THEN
            eState := STATE_MANUAL;
        ELSIF eCommandMode = HEATER_MODE_AUTO AND xTRM10Ready THEN
            eState := STATE_AUTO;
        END_IF
        
    STATE_MANUAL:
        (* Ручной режим *)
        eMode := HEATER_MODE_MANUAL;
        xAllowRun := TRUE;
        xAllowAutotune := FALSE;
        
        (* Проверка условий перехода *)
        IF eCommandMode = HEATER_MODE_OOS THEN
            eState := STATE_OUT_OF_SERVICE;
        ELSIF xError OR NOT xCommOK OR xInterlockActive THEN
            eState := STATE_ERROR;
        ELSIF eCommandMode = HEATER_MODE_STOP THEN
            eState := STATE_STOP;
        ELSIF eCommandMode = HEATER_MODE_AUTO THEN
            eState := STATE_AUTO;
        END_IF
        
    STATE_AUTO:
        (* Автоматический режим *)
        eMode := HEATER_MODE_AUTO;
        xAllowRun := TRUE;
        xAllowAutotune := FALSE;
        
        (* Проверка условий перехода *)
        IF eCommandMode = HEATER_MODE_OOS THEN
            eState := STATE_OUT_OF_SERVICE;
        ELSIF xError OR NOT xCommOK OR xInterlockActive THEN
            eState := STATE_ERROR;
        ELSIF eCommandMode = HEATER_MODE_STOP THEN
            eState := STATE_STOP;
        ELSIF eCommandMode = HEATER_MODE_MANUAL THEN
            eState := STATE_MANUAL;
        END_IF
        
    STATE_AUTOTUNE:
        (* Автонастройка *)
        eMode := HEATER_MODE_AUTO;
        xAllowRun := TRUE;
        xAllowAutotune := TRUE;
        
        (* Проверка условий перехода *)
        IF xAutotuneComplete THEN
            eState := STATE_AUTO;
        ELSIF xAutotuneFailed THEN
            eState := STATE_STOP;
        ELSIF xError OR NOT xCommOK OR xInterlockActive THEN
            eState := STATE_ERROR;
        END_IF
        
    STATE_ERROR:
        (* Состояние ошибки *)
        xAllowRun := FALSE;
        xAllowAutotune := FALSE;
        
        (* Проверка условий выхода из ошибки *)
        IF eCommandMode = HEATER_MODE_OOS THEN
            eState := STATE_OUT_OF_SERVICE;
        ELSIF xReset AND NOT xError AND xCommOK AND NOT xInterlockActive THEN
            eState := STATE_READY;
        END_IF
        
END_CASE

(* Специальная обработка запуска автонастройки *)
IF eState = STATE_STOP AND xAllowAutotune AND xEnable THEN
    (* Здесь будет проверка условий для автонастройки *)
    (* Реализуется в главном ФБ *)
END_IF

(* Сохранение предыдущего состояния *)
eStateOld := eState;