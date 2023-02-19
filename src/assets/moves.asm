include "entity.inc"
include "regex.inc"

def percent equs "* $FF / 100"

macro move
section "\2 Move", romx
\2::
	db MOVE_ACTION_\1
	regex "([^%]+)(%?)", "\6", value, percent
	if strlen("{percent}")
		db value * 255 / 100
	else
		db value
	endc
	db \5
	db \4
	db \7

assert STRLEN(\3) <= MOVE_MAXIMUM_LENGTH
.name:: db \3, 0
endm

	;  | Type     | Identifier  | Name          | Power | Range | Chance | Cost
	move ATTACK,    xScratch,     "Scratch",         8,      1,    100%,     0,
	move ATTACK,    xBite,        "Bite",           12,      1,     85%,    15,
	move ATTACK,    xPounce,      "Pounce",          8,      2,     85%,    15,
	move HEAL,      xHeal,        "Heal",            5,      1,     60%,    20,
	; Enemy-only moves.
	; These may have extreme effects that the player shouldn't be able to access.
	move ATTACK,    xNibble,      "Nibble",          3,      1,     90%,     0,
	move ATTACK,    xClawBite,    "Claw Bite",      12,      1,     50%,    15,
	move HEAL,      xMoonlight,   "Moonlight",       8,      3,     50%,     0,
	move POISON,    xPoison,      "Poison",          0,      1,    100%,    20,
	move POISN_ATK, xPoisonFangs, "Poison Fangs",    8,      1,     50%,     0,
	move POISN_ATK, xPoisonBarbs, "Poison Barbs",    6,      1,    100%,     0,
	move FLY,       xFly,         "Fly",             0,      3,    100%,     0,
