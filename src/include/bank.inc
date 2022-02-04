IF !DEF(BANK_INC)
DEF BANK_INC EQU 1

; Call a function in a foreign bank. Preserves the current bank, but can only
; be used from ROM0
; @param:    target function
; @clobbers: a
MACRO bankcall
    ASSERT _NARG == 1, "Expected 1 argument!"
    ldh a, [hCurrentBank]
    push af
    ld a, BANK(\1)
    rst SwapBank
    call \1
    pop af
    rst SwapBank
ENDM

; Calls a function in a foreign bank. Preserves the current bank, and can be
; used from ROMX
; @param:    target function
; @clobbers: a, b, hl
MACRO farcall
    ASSERT _NARG == 1, "Expected 1 argument!"
    ld b, BANK(\1)
    ld hl, \1
    rst FarCall
ENDM

MACRO farptr
    db BANK(\1)
    dw \1
ENDM

ENDC
