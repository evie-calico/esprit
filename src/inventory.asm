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

SECTION "Item Handler Lookup", ROM0
; @param b: User pointer high byte
; @param hl: pointer to item type
ItemHandlerLookup:
	ld a, [hli]
	add a, a
	ret z
	add a, LOW(.table - 2)
	ld e, a
	adc a, HIGH(.table - 2)
	sub a, e
	ld d, a
	push de
	ret
.table
	ASSERT ITEM_HEAL == 1
	dw HealHandler
	ASSERT ITEM_MAX == 2

SECTION "Heal Handler", ROM0
; @param b: User pointer high byte
; @param hl: Heal data ptr
HealHandler:
	ASSERT HealItem_Strength - sizeof_Item == 0
	ld e, [hl]
	jp HealEntity

SECTION FRAGMENT "dungeon BSS", WRAM0
wInventory::
	ds 3 * INVENTORY_SIZE
.end::