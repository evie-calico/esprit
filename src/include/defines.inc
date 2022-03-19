IF !DEF(DEFINES_INC)
DEF DEFINES_INC EQU 1

DEF UP EQU 0
DEF RIGHT EQU 1
DEF DOWN EQU 2
DEF LEFT EQU 3

MACRO rgb
    db \2, \1, \3
ENDM

MACRO rgb_lim
    rgb (\1) * 8, (\2) * 8, (\3) * 8
ENDM

MACRO fall
    ASSERT _NARG == 1, "Expected 1 argument!"
    ASSERT @ == \1, "Fallthrough to \1 failed!"
ENDM

MACRO lb
    assert -128 <= (\2) && (\2) <= 255, "Second argument to `lb` must be 8-bit!"
    assert -128 <= (\3) && (\3) <= 255, "Third argument to `lb` must be 8-bit!"
    ld \1, (((\2) << 8) & $FF00) | ((\3) & $FF)
ENDM

ENDC
