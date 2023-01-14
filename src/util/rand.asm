;
; Eievui - swapped bc, d with de, b
; I've also added a relatively efficient (and accurate) RandRange function.

;
; Pseudorandom number generator
;
; Copyright 2018 Damian Yerrick
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

section "rand_ram",wram0
randstate:: ds 4

section "rand",rom0

;;
; Generates a pseudorandom 16-bit integer in DE
; using the LCG formula from cc65 rand():
; x[i + 1] = x[i] * 0x01010101 + 0x31415927
; @param  a:  Rand high (higher entropy)
; @param  d:  Rand high (higher entropy)
; @param  e:  Rand low (lower entropy)
; @clobbers: b, hl
Rand::
	; Load bits 31-8 of the current value to DEA
	ld hl,randstate+3
	ld a,[hl-]
	ld d,a
	ld a,[hl-]
	ld e,a
	ld a,[hl-]  ; skip D; thanks ISSOtm for the idea
	; Used to load bits 7-0 to E.  Reading [HL] each time turned out
	; no slower and saved 1 byte.

	; Multiply by 0x01010101
	add [hl]
	ld b,a
	adc e
	ld e,a
	adc d
	ld d,a

	; Add 0x31415927 and write back
	ld a,[hl]
	add $27
	ld [hl+],a
	ld a,b
	adc $59
	ld [hl+],a
	ld a,e
	adc $41
	ld [hl+],a
	ld e,a
	ld a,d
	adc $31
	ld [hl],a
	ld d,a
	ret

; This calls Rand in a loop until it gets a valid result.

; @param h: low
; @param l: (high - low) (must be > 1)
; @return a: result
RandRange::
	; Compute the mask of `l`
	ld a, l
	srl a
	ld e, a
	ld d, high(.maskTable)
	ld a, [de]
	; increment L so that the function is inclusive
	; This benefits performance by making powers of two like [0, 15] always succeed.
.gotMask
	inc l
.tryAgain
	push af
	push hl
		call Rand ; a = d = high, e = low
	pop hl
	pop bc
	; mask out upper byte and verify it's valid.
	and a, b
	cp a, l
	jr c, .exit
	; repeat with lower byte (meaning of `a` here is swapped)
	ld a, b
	and a, e
	cp a, l
	jr nc, .tryAgain
.exit
	add a, h
	ret

align 8
.maskTable
	def mask = 3
	for i, 2, 128, 2
		if i > mask
			def mask <<= 1
			def mask |= 1
		endc
		db mask
	endr

/*
	; Compute the mask of `l`
	ld a, l
	ld c, 8
.getBits
	dec c
	rla
	jr nc, .getBits
	; Now that we've encountered the first bit, the remaining bits are in `e`.
	; Fill `a` with them.
	ld a, 3 ; we know there's at least one bit (a range of 0 or 1 is pointless)
	; after the first dec, c can only be up to 8.
	; However, we don't need to check for c == 0 because this loop is unrolled (it's implied by pc)
	rept 6
		dec c
		jr z, .done
		scf
		rla
	endr
.done
	; increment L so that the function is inclusive
	; This benefits performance by making powers of two like [0, 15] always succeed.
	inc l
.tryAgain
	push af
	push hl
		call Rand ; a = d = high, e = low
	pop hl
	pop bc
	; mask out upper byte and verify it's valid.
	and a, b
	cp a, l
	jr c, .exit
	; repeat with lower byte (meaning of `a` here is swapped)
	ld a, b
	and a, e
	cp a, l
	jr nc, .tryAgain
.exit
	add a, h
	ret
*/