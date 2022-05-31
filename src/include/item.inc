IF !DEF(ITEM_INC)
DEF ITEM_INC EQU 1

INCLUDE "structs.inc"

DEF INVENTORY_SIZE EQU 8

RSRESET
DEF ITEM_NULL RB 1 ; An item that cannot be used.
DEF ITEM_HEAL RB 1 ; An item that restores health.
DEF ITEM_MAX RB 0

	struct Item
		words 1, Palette
		words 1, Graphics
		words 1, Name
		words 1, Description
		bytes 1, Type
	end_struct

	struct HealItem
		extends Item
		bytes 1, Strength
	end_struct

ENDC