INCLUDE "dungeon.inc"
INCLUDE "item.inc"

SECTION "Pickup Item", ROM0
; @param b: Item ID
; @return b: Item bank
; @return hl: Item pointer
; @return z: true on success
; @clobbers bank
PickupItem::
	call GetDungeonItem
	; pointer to far pointer to item in de
	ld de, wInventory
	ld c, INVENTORY_SIZE
.findSpace
	ld a, [de]
	and a, a
	jr z, .found
	inc de
	inc de
	inc de
	dec c
	jr nz, .findSpace
	; Z is set, signalling failure.
	ret

.found
	; Copy item farpointer into the inventory
	ld a, b
	ld [de], a
	inc de
	ld a, l
	ld [de], a
	inc de
	ld a, h
	ld [de], a
	; Set NZ
	xor a, a
	inc a
	ret

SECTION FRAGMENT "dungeon BSS", WRAM0
wInventory::
	ds 3 * INVENTORY_SIZE