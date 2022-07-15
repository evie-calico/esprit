INCLUDE "dungeon.inc"
INCLUDE "item.inc"

SECTION "Pickup Item", ROM0
; @param b: Item ID
; @return b: Item bank
; @return hl: Item pointer
; @return z: reset on success
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

SECTION "Inventory Use Item", ROM0
; @param a: Item index
; @param b: Entity high byte
InventoryUseItem::
	ld c, a
	add a, c
	add a, c
	add a, LOW(wInventory)
	ld l, a
	adc a, HIGH(wInventory)
	sub a, l
	ld h, a
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld d, [hl]
	ld e, a
	push bc
	push de
	ld d, h
	ld e, l
	dec de
	dec de
	inc hl
	jr .moveCondition
.move
	ld a, [hli]
	ld [de], a
	inc de
.moveCondition
	ld a, l
	cp a, LOW(wInventory + 3 * INVENTORY_SIZE)
	jr nz, .move
	ld a, h
	cp a, HIGH(wInventory + 3 * INVENTORY_SIZE)
	jr nz, .move
	xor a, a
	ld [de], a

	pop hl
	pop bc
	ld a, [hCurrentBank]
	push af
	ld a, c
	rst SwapBank
	ld a, Item_Type
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld a, [hli]
	add a, a
	jp z, BankReturn
	ld de, BankReturn
	push de ; Push a "return address" to restore the bank.
	add a, LOW(.table - 2)
	ld e, a
	adc a, HIGH(.table - 2)
	sub a, e
	ld d, a
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld d, a
	ld e, c
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
