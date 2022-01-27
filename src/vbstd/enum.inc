;
; Enumeration macro pack for RGBDS
;
; Copyright 2021, Eievui
;
; This software is provided 'as-is', without any express or implied
; warranty.  In no event will the authors be held liable for any damages
; arising from the use of this software.
;
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
;
; 1. The origin of this software must not be misrepresented; you must not
;    claim that you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation would be
;    appreciated but is not required.
; 2. Altered source versions must be plainly marked as such, and must not be
;    misrepresented as being the original software.
; 3. This notice may not be removed or altered from any source distribution.
;

    IF !DEF(ENUM_INC)
DEF ENUM_INC EQU 1

; Start a new enumeration. Will warn if an unclosed enum is found.
; @ start_enum Name, [start], [step]
MACRO start_enum

    ; Check for arguments and unclosed enums.
    IF _NARG < 1
        FAIL "Expected at least 1 arg"
    ENDC
    IF DEF(ENUM_NAME)
        FAIL "{ENUM_NAME} unclosed! Close enums with `end_enum`"
    ENDC

    DEF ENUM_NAME EQUS "\1"

    ; Handle start position
    IF _NARG > 1
        RSSET \2
    ELSE
        RSRESET
    ENDC

    ; Handle step amount
    IF _NARG == 3
        DEF ENUM_STEP EQU \3
    ELSE
        DEF ENUM_STEP EQU 1
    ENDC
ENDM

; Add new values to the enumeration, one higher than the last.
; Will result in the constant "Name_Value". If multiple arguments are supplied
; they will all share a value.
; @ enum Value, [Value]...
MACRO enum
    IF !DEF(ENUM_NAME)
        FAIL "`enum` missing opening `start_enum`!"
    ENDC
    FOR i, _NARG
        IF i != 0
            RSSET _RS - ENUM_STEP
        ENDC
        DEF {ENUM_NAME}_\1 RB ENUM_STEP
        SHIFT
    ENDR

ENDM

; End an enumeration and clean up variables.
MACRO end_enum
    IF !DEF(ENUM_NAME)
        FAIL "`end_enum` missing opening `start_enum`!"
    ENDC
    PURGE ENUM_NAME
    PURGE ENUM_STEP
    RSRESET
ENDM

    ENDC
