(*========================================================================
    Название:    FB_TRM10_Control
    Автор:       
    Дата:        2025-01-27
    Версия:      1.0
    Описание:    Управление режимами работы ТРМ10 через Modbus
========================================================================*)

FUNCTION_BLOCK FB_TRM10_Control
VAR_INPUT
    xEnable : BOOL;                 (* Разрешение управления *)
    eCommandMode : E_TRM10Mode;     (* Требуемый режим *)
    rSetpoint : REAL;               (* Уставка температуры *)
    rManualPower : REAL;            (* Ручная мощность *)
    xStartAutotune : BOOL;          (* Запуск автонастройки *)
    xReset : BOOL;                  (* Сброс ТРМ10 *)
END_VAR

VAR_OUTPUT
    eActualMode : E_TRM10Mode;      (* Фактический режим *)
    xModeChanged : BOOL;            (* Режим изменен *)
    xReady : BOOL;                  (* Готов к управлению *)
END_VAR

VAR
    (* Внутренние переменные *)
    eCommandModeOld : E_TRM10Mode;  (* Предыдущая команда режима *)
    xStartAutotuneOld : BOOL;       (* Предыдущее состояние автонастройки *)
    xResetOld : BOOL;               (* Предыдущее состояние сброса *)
    tonModeDelay : TON;             (* Задержка смены режима *)
    iStep : INT;                    (* Шаг последовательности *)
END_VAR

(* Проверка разрешения *)
IF NOT xEnable THEN
    (* Сброс управления *)
    MB_TRM_ControlMode_WR := 0;    (* STOP *)
    MB_TRM_Autotune_WR := 0;       (* OFF *)
    xReady := FALSE;
    iStep := 0;
    RETURN;
END_IF

(* Чтение текущего режима *)
eActualMode := WORD_TO_INT(MB_TRM_ControlMode_RD);

(* Последовательность управления режимом *)
CASE iStep OF
    0: (* Ожидание команды *)
        xReady := TRUE;
        
        (* Проверка изменения режима *)
        IF eCommandMode <> eCommandModeOld THEN
            iStep := 10;
        END_IF
        
        (* Проверка запуска автонастройки *)
        IF xStartAutotune AND NOT xStartAutotuneOld THEN
            iStep := 20;
        END_IF
        
        (* Проверка сброса *)
        IF xReset AND NOT xResetOld THEN
            iStep := 30;
        END_IF
        
    10: (* Изменение режима *)
        MB_TRM_ControlMode_WR := INT_TO_WORD(eCommandMode);
        tonModeDelay(IN := TRUE, PT := T#500ms);
        
        IF tonModeDelay.Q THEN
            tonModeDelay(IN := FALSE);
            xModeChanged := TRUE;
            iStep := 0;
        END_IF
        
    20: (* Запуск автонастройки *)
        (* Сначала переводим в STOP *)
        IF eActualMode <> TRM10_STOP THEN
            MB_TRM_ControlMode_WR := INT_TO_WORD(TRM10_STOP);
            tonModeDelay(IN := TRUE, PT := T#500ms);
            
            IF tonModeDelay.Q THEN
                tonModeDelay(IN := FALSE);
                iStep := 21;
            END_IF
        ELSE
            iStep := 21;
        END_IF
        
    21: (* Запуск автонастройки из режима STOP *)
        MB_TRM_Autotune_WR := 1; (* RUN *)
        tonModeDelay(IN := TRUE, PT := T#500ms);
        
        IF tonModeDelay.Q THEN
            tonModeDelay(IN := FALSE);
            iStep := 0;
        END_IF
        
    30: (* Сброс прибора *)
        MB_TRM_Reset_WR := 1;
        tonModeDelay(IN := TRUE, PT := T#1s);
        
        IF tonModeDelay.Q THEN
            tonModeDelay(IN := FALSE);
            MB_TRM_Reset_WR := 0;
            iStep := 0;
        END_IF
        
END_CASE

(* Запись уставки и мощности независимо от шага *)
IF xEnable THEN
    (* Ограничение и запись уставки *)
    MB_TRM_Setpoint_WR := rSetpoint;
    
    (* Ограничение и запись ручной мощности *)
    IF rManualPower < 0.0 THEN
        MB_TRM_OutputPower_WR := 0.0;
    ELSIF rManualPower > 100.0 THEN
        MB_TRM_OutputPower_WR := 100.0;
    ELSE
        MB_TRM_OutputPower_WR := rManualPower;
    END_IF
END_IF

(* Сброс флага изменения режима *)
IF xModeChanged THEN
    xModeChanged := FALSE;
END_IF

(* Сохранение предыдущих значений *)
eCommandModeOld := eCommandMode;
xStartAutotuneOld := xStartAutotune;
xResetOld := xReset;