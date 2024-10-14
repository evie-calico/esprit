if !def(ITEM_INC)
def ITEM_INC equ 1

include "structs.inc"

; This must be less than the number of palettes.
def INVENTORY_SIZE equ 8

	enum ItemType
		; Cannot be used
		case Null
		; Restores health
		case Heal
			bytes 1, Health
		; Restores health and fatigue
		case FatigueHeal
			bytes 1, Fatigue
			bytes 1, Health
		; Revives the entity upon death
		case Revive
		; Cures poison and restores health
		case PoisonCure
			bytes 1, Health
		; Causes the party to blink after 1..N turns
		case BlinkTeam
			bytes 1, Delay
		; Causes the party to blink to the exit after 1..N turns
		case PureBlinkTeam
			bytes 1, Delay
		; Clears the `IsHeatstroked` flag.
		case HealHeatstroke
			bytes 1, Health
	end_enum

	struct Item
		words 1, Palette
		words 1, Graphics
		words 1, Name
		words 1, Description
		bytes 1, Type
	end_struct

endc
