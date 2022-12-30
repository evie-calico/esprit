include "defines.inc"
include "format.inc"
include "hardware.inc"

section "crash handler", rom0
CrashHandler::
	xor a, a
	ldh [rIE], a
	ldh [rNR50], a
.waitVBlank
	ldh a, [rLY]
	cp a, SCRN_Y
	jr c, .waitVBlank
	xor a, a
	ldh [rLCDC], a

	ld hl, $8000
	ld bc, $2000
	xor a, a
	call MemSet
	ld a, 1
	ldh [rVBK], a
	ld hl, $8000
	ld bc, $2000
	xor a, a
	call MemSet
	ldh [rVBK], a

	; In the event of a crash we can't rely on hSystem being accurate,
	; so color is handled in a DMG-compatible way.
	ld a, BCPSF_AUTOINC
	ldh [rBCPS], a
	xor a, a
	ldh [rBCPD], a
	ld a, $58
	ldh [rBCPD], a

	ld a, BCPSF_AUTOINC | 6
	ldh [rBCPS], a
	ld a, $FF
	ldh [rBCPD], a
	ldh [rBCPD], a
	ld [wTextSrcPtr + 1], a
	inc a
	ld [wTextCharset], a
	ld [wTextCurPixel], a
	ld [wTextLetterDelay], a
	ld c, $10 * 2
	ld hl, wTextTileBuffer
	rst MemSetSmall
	ldh [rSCX], a
	ldh [rSCY], a

	ld a, SCRN_X
	lb bc, 1, $7F
	lb de, SCRN_Y_B, $90
	call TextInit

	pop hl ; Get the address we were called from.
	ld a, l
	ld [wfmt_xCrashString_pc], a
	ld a, h
	ld [wfmt_xCrashString_pc + 1], a
	ld a, [hl]
	ld [wfmt_xCrashString_code], a
	ld b, a
	inc a
	ld hl, xErrorCodes.ffString
	jr z, .foundError
	ld a, bank(xErrorCodes)
	rst SwapBank
	ld hl, xErrorCodes
.nextError
	ld a, b
	and a, a
	jr z, .foundError
	:
		ld a, [hli]
		inc a
		jr z, .invalidError
		dec a
		jr nz, :-
	dec b
	jr .nextError

.invalidError
	ld hl, null
.foundError
	ld a, bank(xErrorCodes)
	ld [wfmt_xCrashString_message], a
	ld a, l
	ld [wfmt_xCrashString_message + 1], a
	ld a, h
	ld [wfmt_xCrashString_message + 2], a

	ld hl, xCrashString
	ld b, bank(xCrashString)
	ld a, 1
	call PrintVWFText

	lb de, SCRN_X_B, SCRN_Y_B
	ld hl, $9821
	call TextDefineBox
	call ReaderClear
	ld a, bank(TextClear)
	rst SwapBank
	call TextClear
	call PrintVWFChar
	call DrawVWFChars

	ld a, LCDCF_ON
	ldh [rLCDC], a

	ei
.done
	halt
	jr .done

macro error_code ; name, message
	def \1 rb
	export \1
	db \2, "\n", 0
endm

section "Error Codes", romx
xErrorCodes:
	rsreset
	error_code UNIMPLEMENTED, "Unimplemented"
	error_code INVALID_INDEX, "Invalid Index"
.ffString db "PC out of bounds\n", 0
