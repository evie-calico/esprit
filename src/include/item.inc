if !def(ITEM_INC)
def ITEM_INC equ 1

include "structs.inc"

def INVENTORY_SIZE equ 8

rsreset
def ITEM_NULL rb 1 ; An item that cannot be used.
def ITEM_HEAL rb 1 ; An item that restores health.
def ITEM_FATIGUE_HEAL rb 1 ; An item that restores health and fatigue.
def ITEM_MAX rb 0

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

endc