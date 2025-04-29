(*==============================================================================
    Название:    FB_LampController
    Автор:       
    Дата:        2025-04-28
    Версия:      1.0
    
    Описание:    Функциональный блок управления сигнальной лампой
                 Генерирует сигналы для различных режимов работы лампы
==============================================================================*)
FUNCTION_BLOCK FB_LampController
VAR_INPUT
    eMode: E_LampBlinkMode;               (* Режим работы лампы *)
    bEnable: BOOL := TRUE;                (* Разрешение работы *)
END_VAR

VAR_OUTPUT
    bOutput: BOOL;                        (* Выходной сигнал *)
END_VAR

VAR
    (* Таймеры для различных режимов мигания *)
    tonSlow: TON;                         (* Таймер медленного мигания (1 Гц) *)
    tonFast: TON;                         (* Таймер быстрого мигания (4 Гц) *)
    
    (* Состояния для различных режимов *)
    bSlowState: BOOL;                     (* Состояние медленного мигания *)
    bFastState: BOOL;                     (* Состояние быстрого мигания *)
END_VAR

VAR CONSTANT
    (* Константы времени для различных режимов *)
    T_SLOW: TIME := T#500MS;              (* Период для медленного мигания - 1 Гц *)
    T_FAST: TIME := T#125MS;              (* Период для быстрого мигания - 4 Гц *)
END_VAR

(* ======================================================================== *)
(* Основная логика функционального блока                                    *)
(* ======================================================================== *)

(* Генерация сигналов для различных режимов мигания *)
(* Медленное мигание - 1 Гц *)
tonSlow(IN := NOT tonSlow.Q, PT := T_SLOW);
IF tonSlow.Q THEN
    bSlowState := NOT bSlowState;
END_IF;

(* Быстрое мигание - 4 Гц *)
tonFast(IN := NOT tonFast.Q, PT := T_FAST);
IF tonFast.Q THEN
    bFastState := NOT bFastState;
END_IF;

(* Выбор режима мигания *)
IF bEnable THEN
    CASE eMode OF
        LAMP_OFF:
            bOutput := FALSE;
            
        LAMP_ON:
            bOutput := TRUE;
            
        LAMP_SLOW:
            bOutput := bSlowState;
            
        LAMP_FAST:
            bOutput := bFastState;
            
        ELSE
            (* По умолчанию - выключено *)
            bOutput := FALSE;
    END_CASE;
ELSE
    (* При отключенном блоке - выходной сигнал выключен *)
    bOutput := FALSE;
END_IF;