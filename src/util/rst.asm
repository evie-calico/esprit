include "hardware.inc"

section "Null", rom0[$0000]
null::
	db 0
Stub::
	ret

section "Call HL", rom0[$0008]
; Used to call the address pointed to by `hl`. Mapped to `rst $08` or `rst CallHL`
CallHL::
	jp hl

section "Memcopy Small", rom0[$0010]
; A slightly faster version of memcopy that requires less setup but can only do
; up to 256 bytes. Destination and source are both offset by length, in case
; you want to copy to or from multiple places
; @param  c: length
; @param de: destination
; @param hl: source
MemCopySmall::
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, MemCopySmall
	ret

section "Memset Small", rom0[$0018]
; A slightly faster version of memset that requires less setup but can only do
; up to 256 bytes. Destination and source are both offset by length, in case
; you want to copy to or from multiple places
; @param  a: source (is preserved)
; @param  c: length
; @param hl: destination
MemSetSmall::
	ld [hli], a
	dec c
	jr nz, MemSetSmall
	ret

section "Swap Bank", rom0[$0020 - 1]
BankReturn::
	pop af
; Sets rROMB0 and hCurrentBank to `a`
; @param a: Bank
SwapBank::
	assert @ == $20
	ldh [hCurrentBank], a
	ld [rROMB0], a
	ret

section "rand8", rom0[$0028]
; @returns a: random value
Rand8::
	push hl
	push de
	call Rand
	pop de
	pop hl
	ret

section "Crash", rom0[$0038]
Crash::
	jp CrashHandler
