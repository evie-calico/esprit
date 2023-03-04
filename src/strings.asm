include "format.inc"

section "elipses", romx
xElipsesString:: db "<SET_DELAY><5>...<SET_DELAY><2><DELAY><30>", 0

; Contains all formatted text in a central location

	format xStatusString, "[entity::wStatusString.name]: [u16::wStatusString.health]/[u16::wStatusString.maxHealth] HP[str::wStatusString.status]"
	format xPauseStatusString, "[entity::wStatusString.name][str::wStatusString.status]\nHP: [u16::wStatusString.health]/[u16::wStatusString.maxHealth]"

	format xUsedMoveString, "[entity:user] used [str:move]!"
	format xDealtDamageString, "Dealt [u8:value] damage to [entity:target]!"
	format xHealedDamageString, "[entity:target] healed [u8:value] HP."
	format xGotPoisonedString, "[entity:target] was poisoned!"
	format xSomeoneBlinkedString, "[entity:target] blinked!"

	format xLeveledUpString, "[entity:target]'s level increased to [u8:level]![condition:newMove] [entity:target] learned [str:moveName]."
	format xEnteredFloorString, "Floor [u8::wDungeonCurrentFloor][condition:quicksave]\nYour progress has been saved."
	format xDefeatedString, "Defeated [entity::wDefeatCheckTarget]. Gained [u8:reward] xp."
	format xRevivedString, "[entity::wDefeatCheckTarget] was revived!"
	format xTooTiredString, "You're too tired to use that move."
	format xMissedString, "[str:user] missed!"

	format xGetItemString, "Picked up [str:name]."
	format xFullBagString, "Your bag is full."

	format xTiredStatus, " [color::2]-[color::3] Tired"
	format xPoisonedStatus, " [color::2]-[color::3] Poisoned"
	format xUnstableStatus, " [color::2]-[color::3] Unstable"
	format xCanReviveStatus, "[color::2]+[color::3]"

	format xSwitchedToManual, "Switched to manual mode."
	format xSwitchedToAutomatic, "Switched to automatic mode."

	format xCrashString, "Error [u8:code]\n[str:message]PC: [u16:pc] (decimal)\n\n[jump::Version]"

	format xNpcSayString, "<SET_VARIANT><2>| [str:name]|<RESTORE_VARIAN><BLANKS><1>: <SET_DELAY><2>[voice:voice][str:text]<SET_DELAY><0><WAIT><CLEAR>[voice::null]"
