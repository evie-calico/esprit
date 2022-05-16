IF !DEF(ITEM_INC)
DEF ITEM_INC EQU 1

INCLUDE "structs.inc"

RSRESET
DEF ITEM_NULL RB 1 ; An item that cannot be used.
DEF ITEM_HEAL RB 1 ; An item that restores health.

	struct Item
		words 1, Name
		words 1, Graphics
		words 1, Palette
		bytes 1, Type
	end_struct

	struct HealItem
		extends Item
		bytes 1, Strength
	end_struct

ENDC