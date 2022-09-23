INCLUDE "entity.inc"

DEF percent EQUS "* $FF / 100"

MACRO move
SECTION "\2 Move", ROMX
\2::
	db MOVE_ACTION_\1
	IF STRIN("\6", "%")
		DEF PERCENT EQUS STRSUB("\6", 1, STRIN("\6", "%") - 1)
		db PERCENT * $FF / 100
		PURGE PERCENT
	ELSE
		db \6
	ENDC
	db \5
	db \4
	db \7
.name:: db \3, 0
ENDM

	;  | Type     | Identifier  | Name          | Power | Range | Chance  | Cost
	move ATTACK,    xNibble,      "Nibble",        3,      1,      90%,       0
	move ATTACK,    xScratch,     "Scratch",       8,      1,     100%,       0
	move ATTACK,    xBite,        "Bite",         12,      1,      85%,       5
	move ATTACK,    xPounce,      "Pounce",        8,      2,      85%,       5
	move HEAL,      xHeal,        "Heal",          5,      1,      60%,      20
	move POISON,    xPoison,      "Poison",        0,      1,     100%,      20
	move POISN_ATK, xPoisonFangs, "Poison Fangs",  8,      1,      50%,      10
