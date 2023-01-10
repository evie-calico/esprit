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
; @param l: (high - low) (exclusive)
; @return a: adjusted value
; @return cy: set upon success
; @preserves b, c, d
RandRange::
	push hl
		call Rand
	pop hl
	ld b, d
	call .verify
	ret c
	ld b, e
	call .verify
	jr nc, RandRange
	ret

; @param b: rand
; @param h: low
; @param l: (high - low) (exclusive)
; @return a: adjusted value
; @return cy: set upon success
; @preserves b, c, d
.verify
	ld a, l
	ld c, 9
.getBits
	dec c
	rla
	jr nc, .getBits
	; Now that we've encountered the first bit, the remaining bits are in `e`.
	; Fill `a` with them.
	ld a, 0
	rla
.fillBits
	dec c
	jr z, .done
	scf
	rla
	jr .fillBits
.done
	and a, b ; mask the input by the mod mask
	cp a, l
	ret nc
	add a, h
	scf
	ret
