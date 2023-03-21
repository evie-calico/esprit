include "dungeon.inc"
include "item.inc"

section "Pickup Item", rom0
; @param b: Item ID
; @return b: Item bank
; @return hl: Item pointer
; @return z: reset on success
; @clobbers bank
PickupItem::
	call GetDungeonItem
; @param b: Item bank
; @param hl: Item pointer
InventoryAddItem::
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

section "Inventory Remove Item", rom0
; @param a: Item index
InventoryRemoveItem::
	ld c, a
	add a, c
	add a, c
	add a, low(wInventory)
	ld l, a
	adc a, high(wInventory)
	sub a, l
	ld h, a
	ld d, h
	ld e, l
	inc hl
	inc hl
	inc hl
	jr .moveCondition
.move
	ld a, [hli]
	ld [de], a
	inc de
.moveCondition
	ld a, l
	cp a, low(wInventory + 3 * INVENTORY_SIZE)
	jr nz, .move
	ld a, h
	cp a, high(wInventory + 3 * INVENTORY_SIZE)
	jr nz, .move
	xor a, a
	ld [de], a
	ret

section "Inventory Use Item", rom0
; @param a: Item index
; @param b: Entity high byte
InventoryUseItem::
	ld c, a
	add a, c
	add a, c
	add a, low(wInventory)
	ld l, a
	adc a, high(wInventory)
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
	cp a, low(wInventory + 3 * INVENTORY_SIZE)
	jr nz, .move
	ld a, h
	cp a, high(wInventory + 3 * INVENTORY_SIZE)
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
	add a, low(.table - 2)
	ld e, a
	adc a, high(.table - 2)
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
	assert ITEM_HEAL == 1
	dw HealHandler
	assert ITEM_FATIGUE_HEAL == 2
	dw FatigueHealHandler
	assert ITEM_REVIVE == 3
	dw ReviveHandler
	assert ITEM_POISON_CURE == 4
	dw PoisonCureHandler
	assert ITEM_BLINK_TEAM == 5
	dw BlinkTeamHandler
	assert ITEM_PURE_BLINK_TEAM == 6
	dw PureBlinkTeamHandler
	assert ITEM_HEAL_HEATSTROKE == 7
	dw HealHeatstrokeHandler
	assert ITEM_MAX == 8

section "Heal Handler", rom0
; @param b: User pointer high byte
; @param hl: Heal data ptr
HealHandler:
	assert HealItem_Strength - sizeof_Item == 0
	ld e, [hl]
	jp HealEntity

section "Fatigue Heal Handler", rom0
; @param b: User pointer high byte
; @param hl: Heal data ptr
FatigueHealHandler:
	ld c, low(wEntity0_Fatigue)
	ld a, [bc]
	add a, 50
	cp a, 101
	jr c, :+
	ld a, 100
:
	ld [bc], a
	jp HealHandler

section "Revive Handler", rom0
; @param b: User pointer high byte
; @param hl: End of item data ptr
ReviveHandler:
	ld c, low(wEntity0_CanRevive)
	ld a, 1
	ld [bc], a
	ret

section "PoisonCureHandler", rom0
; @param b: User pointer high byte
; @param hl: End of item data ptr
PoisonCureHandler:
	ld c, low(wEntity0_PoisonTurns)
	xor a, a
	ld [bc], a
	jp HealHandler

section "BlinkTeamHandler", rom0

; @param b: User pointer high byte
; @param hl: Blink data ptr
PureBlinkTeamHandler:
	ld c, low(wEntity0_IsBlinkPure)
	ld a, 1
	ld [bc], a
	jr BlinkTeamHandler.hook

; @param b: User pointer high byte
; @param hl: Blink data ptr
BlinkTeamHandler:
	ld c, low(wEntity0_IsBlinkPure)
	xor a, a
	ld [bc], a
.hook
	assert BlinkItem_Length - sizeof_Item == 0
	ld l, [hl]
	ld h, 0
	push bc
	call RandRange ; 2..blink length
	add a, 2
	pop bc
	ld c, low(wEntity0_BlinkTurns)
	ld [bc], a
	ret

section "HealHeatstrokeHandler", rom0
; @param b: User pointer high byte
; @param hl: Blink data ptr
HealHeatstrokeHandler:
	ld c, low(wEntity0_IsHeatstroked)
	xor a, a
	ld [bc], a
	jp HealHandler
