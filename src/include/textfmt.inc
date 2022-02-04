IF !DEF(TEXTFMT_INC)
DEF TEXTFMT_INC EQU 1

MACRO fmttable ; name, strings
    ASSERT _NARG > 0
    FOR I, _NARG
        dw .s{d:I}
    ENDR
    FOR I, _NARG
.s{d:I} db \1, "<END>"
    SHIFT
    ENDR
ENDM

ENDC
