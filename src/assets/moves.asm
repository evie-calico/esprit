INCLUDE "entity.inc"

DEF percent EQUS "* $FF / 100"

MACRO attack
SECTION "\1 Move", ROMX
x\1::
	db MOVE_ACTION_ATTACK
	db \4
	db \3
	db \2
	db \5
.name:: db "\1", 0
ENDM

MACRO heal
SECTION "\1 Move", ROMX
x\1::
	db MOVE_ACTION_HEAL
	db \4
	db \3
	db \2
	db \5
.name:: db "\1", 0
ENDM

	; type | Name | power | range |     chance | cost
	attack Nibble,      3,      1,  90 percent,     0
	attack Scratch,     8,      1, 100 percent,     0
	attack Bite,       12,      1,  85 percent,     5
	attack Pounce,      8,      2,  85 percent,     5
	heal   Heal,        5,      1,  60 percent,    20
