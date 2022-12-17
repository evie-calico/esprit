include "entity.inc"

def percent equs "* $FF / 100"

macro move
section "\2 Move", romx
\2::
	db MOVE_ACTION_\1
	if strin("\6", "%")
		def PERCENT equs strsub("\6", 1, strin("\6", "%") - 1)
		db PERCENT * $FF / 100
		purge PERCENT
	else
		db \6
	endc
	db \5
	db \4
	db \7

assert STRLEN(\3) <= MOVE_MAXIMUM_LENGTH
.name:: db \3, 0
endm

	;  | Type     | Identifier  | Name          | Power | Range | Chance  | Cost
	move ATTACK,    xNibble,      "Nibble",        3,      1,      90%,       0
	move ATTACK,    xScratch,     "Scratch",       8,      1,     100%,       0
	move ATTACK,    xBite,        "Bite",         12,      1,      85%,       5
	move ATTACK,    xPounce,      "Pounce",        8,      2,      85%,       5
	move HEAL,      xHeal,        "Heal",          5,      1,      60%,      20
	move POISON,    xPoison,      "Poison",        0,      1,     100%,      20
	move POISN_ATK, xPoisonFangs, "Poison Fangs",  8,      1,      50%,      10
