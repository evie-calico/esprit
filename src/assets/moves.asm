INCLUDE "entity.inc"

DEF percent EQUS "* $FF / 100"

MACRO move
SECTION "\2 Move", ROMX
\2::
	db MOVE_ACTION_\1
	db \6
	db \5
	db \4
	db \7
.name:: db \3, 0
ENDM

	;  | Type   | Identifier | Name      | Power | Range | Chance     | Cost |
	move ATTACK, xNibble,      "Nibble",       3,      1,  90 percent,     0
	move ATTACK, xScratch,     "Scratch",      8,      1, 100 percent,     0
	move ATTACK, xBite,        "Bite",        12,      1,  85 percent,     5
	move ATTACK, xPounce,      "Pounce",       8,      2,  85 percent,     5
	move HEAL,   xHeal,        "Heal",         5,      1,  60 percent,    20
	move POISON, xPoison,      "Poison",       0,      1, 100 percent,    20
