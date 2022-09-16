INCLUDE "format.inc"

; Contains all formatted text in a central location

	format xStatusString, "[entity:name]: [u16:health]/[u16:maxHealth] HP[condition:hasStatus] - [str:status]"
	format xUsedMoveString, "[entity:user] used [str:move]!"
	format xDealtDamageString, "Dealt [u8:value] damage to [entity:target]!"
	format xHealedDamageString, "[entity:target] healed [u8:value] HP."
	format xGotPoisonedString, "[entity:target] was poisoned!"
	format xNotPoisonedString, "[entity:target]'s poison has faded."
	format xDefeatedString, "Defeated [entity:target]. Gained [u8:reward] xp."
	format xMissedString, "[str:user] missed!"
	format xGetItemString, "Picked up [str:name]."
	format xFullBagString, "Your bag is full."
	format xEnteredFloorString, "Entered floor [u8::wDungeonCurrentFloor]."
	format xPauseStatusString, "[entity:target]\nHP: [u16:health]/[u16:maxHealth]"
	format xLeveledUpString, "[entity:target]'s level increased to [u8:level]![condition:newMove] [entity:target] learned [str:moveName]."
	format xTooTiredString, "You're too tired to use that move."

	format xTiredStatus, "Tired"
