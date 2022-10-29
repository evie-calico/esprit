section "Memory Copy Far", rom0
; Switches the bank before performing a copy.
; @param  b:  bank
; @param  c:  length
; @param de: destination
; @param hl: source
MemCopyFar::
	ldh a, [hCurrentBank]
	push af
	ld a, b
	rst SwapBank
.copy
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .copy
	pop af
	rst SwapBank
	ret

section "Current Bank", hram
hCurrentBank::
	ds 1
