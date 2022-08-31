SECTION "Memory Copy", ROM0

; Copies a certain amount of bytes from one location to another. Destination and
; source are both offset by length, in case you want to copy to or from multiple
; places.
; @param bc: length
; @param de: destination
; @param hl: source
MemCopy::
	dec bc
	inc b
	inc c
.loop:
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .loop
	dec b
	jr nz, .loop
	ret

SECTION "Memory Set", ROM0

; Overwrites a certain amount of bytes with a single byte. Destination is offset
; by length, in case you want to overwrite with different values.
; @param  a: source (is preserved)
; @param bc: length
; @param hl: destination
MemSet::
	inc b
	inc c
	jr .decCounter
.loadByte
	ld [hli],a
.decCounter
	dec c
	jr nz, .loadByte
	dec b
	jr nz, .loadByte
	ret
