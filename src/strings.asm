include "format.inc"

; Contains all formatted text in a central location

	format xStatusString, "[entity:name]: [u16:health]/[u16:maxHealth] HP[condition:hasStatus] [color::2]-[color::3] [str:status]"
	format xPauseStatusString, "[entity:target]\nHP: [u16:health]/[u16:maxHealth]"

	format xUsedMoveString, "[entity:user] used [str:move]!"
	format xDealtDamageString, "Dealt [u8:value] damage to [entity:target]!"
	format xHealedDamageString, "[entity:target] healed [u8:value] HP."
	format xGotPoisonedString, "[entity:target] was poisoned!"
	format xNotPoisonedString, "[entity:target]'s poison has faded."

	format xLeveledUpString, "[entity:target]'s level increased to [u8:level]![condition:newMove] [entity:target] learned [str:moveName]."
	format xEnteredFloorString, "Floor [u8::wDungeonCurrentFloor]"
	format xDefeatedString, "Defeated [entity:target]. Gained [u8:reward] xp."
	format xTooTiredString, "You're too tired to use that move."
	format xMissedString, "[str:user] missed!"

	format xGetItemString, "Picked up [str:name]."
	format xFullBagString, "Your bag is full."

	format xTiredStatus, "Tired"
	format xPoisonedStatus, "Poisoned"

	format xSwitchedToManual, "Switched to manual mode."
	format xSwitchedToAutomatic, "Switched to automatic mode."

	format xCrashString, "Error [u8:code]\n[str:message]PC: [u16:pc] (decimal)\n\nPlease report this to:\nbugs@eievui.ml\n\n[jump::Version]"
