IF !DEF(BANK_INC)
DEF BANK_INC EQU 1

; Call a function in a foreign bank. Clobbers A.
MACRO bankcall
    ASSERT _NARG == 1, "Expected 1 argument!"
    ld a, BANK(\1)
    rst SwapBank
    call \1
ENDM

ENDC
