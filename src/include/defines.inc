IF !DEF(DEFINES_INC)
DEF DEFINES_INC EQU 1

DEF UP EQU 0
DEF RIGHT EQU 1
DEF DOWN EQU 2
DEF LEFT EQU 3

DEF SYSTEM_DMG EQU 0
DEF SYSTEM_CGB EQU 1
DEF SYSTEM_AGB EQU 2

RSRESET
DEF GAMESTATE_DUNGEON RB
DEF GAMESTATE_MENU RB
DEF GAMESTATE_MAP RB
DEF GAMESTATE_SCENE RB

RSRESET
DEF FLAG_FOREST_COMPLETE RB
DEF FLAG_FIELDS_COMPLETE RB
DEF FLAG_LAKE_COMPLETE RB
DEF FLAG_PLAINS_COMPLETE RB
DEF FLAG_CAVES_COMPLETE RB
DEF FLAG_GEMTREE_COMPLETE RB

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
