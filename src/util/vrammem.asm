;
; vrammem.asm
; Memory functions which wait for VRAM access before writing.
;
; Copyright 2022, Evie M.
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

include "hardware.inc"

section "VRAM Memory Copy", rom0
; Waits for VRAM access before copying data.
; @param bc: length
; @param de: destination
; @param hl: source
VramCopy::
	dec bc
	inc b
	inc c
.loop:
	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, .loop

	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .loop
	dec b
	jr nz, .loop
	ret

section "VRAM Small Memory Copy", rom0
; Waits for VRAM access before copying data. Slightly faster than vmemcopy with
; less setup, but can only copy 256 bytes at a time.
; @param  c: length
; @param de: destination
; @param hl: source
VramCopySmall::
	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, VramCopySmall
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, VramCopySmall
	ret

section "VRAM Memory Set", rom0
; Waits for VRAM access before setting data.
; @param  d: source (is preserved)
; @param bc: length
; @param hl: destination
VramSet::
	inc b
	inc c
	jr .decCounter
.loadByte
	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, .loadByte

	ld a, d
	ld [hli], a
.decCounter
	dec c
	jr nz, .loadByte
	dec b
	jr nz, .loadByte
	ret

section "VRAM Memory Set Small", rom0
; Waits for VRAM access before setting data.
; @param  b: source (is preserved)
; @param  c: length
; @param hl: destination
VramSetSmall::
	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, VramSetSmall

	ld a, b
	ld [hli], a
	dec c
	jr nz, VramSetSmall
	ret
