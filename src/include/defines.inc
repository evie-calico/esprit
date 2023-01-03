if !def(DEFINES_INC)
def DEFINES_INC equ 1

def UP equ 0
def RIGHT equ 1
def DOWN equ 2
def LEFT equ 3

def SYSTEM_DMG equ 0
def SYSTEM_CGB equ 1
def SYSTEM_AGB equ 2

rsreset
def GAMESTATE_DUNGEON rb
def GAMESTATE_MENU rb
def GAMESTATE_MAP rb
def GAMESTATE_SCENE rb

rsreset
def FLAG_FOREST_COMPLETE rb
def FLAG_FIELDS_COMPLETE rb
def FLAG_LAKE_COMPLETE rb
def FLAG_PLAINS_COMPLETE rb
def FLAG_CAVES_COMPLETE rb
def FLAG_GEMTREE_COMPLETE rb

; Call a function in a foreign bank. Preserves the current bank, but can only
; be used from rom0
; @param:    target function
; @clobbers: a
macro bankcall
	assert _NARG == 1, "Expected 1 argument!"
	ldh a, [hCurrentBank]
	push af
	ld a, bank(\1)
	rst SwapBank
	call \1
	pop af
	rst SwapBank
endm

; Calls a function in a foreign bank. Preserves the current bank, and can be
; used from romx
; @param:    target function
; @clobbers: a, b, hl
macro farcall
	assert _NARG == 1, "Expected 1 argument!"
	ld b, bank(\1)
	ld hl, \1
	rst FarCall
endm

macro farptr
	if _NARG < 1
		ds 3
	else
		db bank(\1)
		dw \1
	endc
endm

macro rgb
	db \2, \1, \3
endm

macro hex
	rept _NARG
		db (($\1) >> 8) & $FF, (($\1) >> 16) & $FF, ($\1) & $FF
		shift 1
	endr
endm

macro rgb_lim
	rgb (\1) * 8, (\2) * 8, (\3) * 8
endm

macro fall
	assert _NARG == 1, "Expected 1 argument!"
	assert @ == \1, "Fallthrough to \1 failed!"
endm

macro lb
	assert -128 <= (\2) && (\2) <= 255, "Second argument to `lb` must be 8-bit!"
	assert -128 <= (\3) && (\3) <= 255, "Third argument to `lb` must be 8-bit!"
	ld \1, (((\2) << 8) & $FF00) | ((\3) & $FF)
endm

macro crash ; code
	rst Crash
	db \1
endm

macro todo
	if _NARG == 0
		crash UNIMPLEMENTED
	else
		crash \1, UNIMPLEMENTED
	endc
endm

endc
