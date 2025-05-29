(*========================================================================
    Название:    FB_HeaterRuntime
    Автор:       
    Дата:        2025-01-27
    Версия:      1.0
    Описание:    Функциональный блок учета времени работы ТЭНа
========================================================================*)

FUNCTION_BLOCK FB_HeaterRuntime
VAR_INPUT
    xEnable : BOOL;                 (* Разрешение счета *)
    xRunning : BOOL;                (* ТЭН работает *)
    xReset : BOOL;                  (* Сброс счетчиков *)
END_VAR

VAR_OUTPUT
    dwRunCount : DWORD;             (* Количество включений *)
    tTotalRunTime : TIME;           (* Общее время работы *)
    tCurrentRunTime : TIME;         (* Время текущего запуска *)
    tLastRunTime : TIME;            (* Время последнего запуска *)
END_VAR

VAR
    (* Внутренние переменные *)
    xRunningOld : BOOL;             (* Предыдущее состояние *)
    tonRunTime : TON;               (* Таймер времени работы *)
    tStartTime : TIME;              (* Время начала работы *)
    tAccumulatedTime : TIME;        (* Накопленное время *)
END_VAR

(* Сброс счетчиков *)
IF xReset THEN
    dwRunCount := 0;
    tTotalRunTime := T#0s;
    tCurrentRunTime := T#0s;
    tLastRunTime := T#0s;
    tAccumulatedTime := T#0s;
    xRunningOld := FALSE;
    RETURN;
END_IF

(* Проверка разрешения *)
IF NOT xEnable THEN
    tonRunTime(IN := FALSE);
    tCurrentRunTime := T#0s;
    xRunningOld := FALSE;
    RETURN;
END_IF

(* Детектирование фронта включения *)
IF xRunning AND NOT xRunningOld THEN
    (* Новое включение *)
    dwRunCount := dwRunCount + 1;
    tStartTime := TIME();
    tonRunTime(IN := FALSE);
    tonRunTime(IN := TRUE, PT := T#24h);
END_IF

(* Детектирование фронта выключения *)
IF NOT xRunning AND xRunningOld THEN
    (* Выключение - сохраняем время последнего запуска *)
    tLastRunTime := tCurrentRunTime;
    tAccumulatedTime := tAccumulatedTime + tCurrentRunTime;
    tTotalRunTime := tAccumulatedTime;
END_IF

(* Обновление текущего времени работы *)
IF xRunning THEN
    tonRunTime(IN := TRUE, PT := T#24h);
    tCurrentRunTime := tonRunTime.ET;
ELSE
    tonRunTime(IN := FALSE);
    tCurrentRunTime := T#0s;
END_IF

(* Обновление общего времени работы *)
IF xRunning THEN
    tTotalRunTime := tAccumulatedTime + tCurrentRunTime;
END_IF

(* Сохранение предыдущего состояния *)
xRunningOld := xRunning;