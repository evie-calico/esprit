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
	move ATTACK,    xScratch,     "Scratch",         3,      1,    100%,     0, ; level 5
	move ATTACK,    xBite,        "Bite",            8,      1,     85%,    15, ; level 6
	move ATTACK,    xPounce,      "Pounce",          3,      2,     85%,    15, ; level 7
	; special
	move ATTACK,    xSlash,       "Slash",           8,      1,     70%,     0, ; level 10
	move ATTACK,    xCrunch,      "Crunch",         16,      1,     90%,    15, ; level 12
	move ATTACK,    xLunge,       "Lunge",          12,      2,    100%,    15, ; level 13
	; special

	; Luvui heal moves
	move TEND_WOUNDS, xTendWounds, "Tend",   16,      1,    100%,    30, ; level 8
	move TEND_WOUNDS, xSootheWounds,"Soothe",40,      1,    100%,    20,
	;move TEND_WOUNDS, xHealWounds, "Heal",   24,      1,    100%,    15,

	; Aris buff moves
	move ATK_BUFF,  xGrowl,       "Growl",          8,      1,    100%,    20,
	move ATK_BUFF,  xRoar,        "Roar",          24,      1,    100%,    20,

	; Enemy-only moves.
	; These may have extreme effects that the player shouldn't be able to access.
	move ATTACK,    xNibble,      "Nibble",          3,      1,     90%,     0,
	move ATTACK,    xClawBite,    "Claw Bite",      12,      1,     50%,    15,
	move HEAL,      xMoonlight,   "Moonlight",       8,      3,     50%,     0,
	move POISON,    xPoison,      "Poison",          0,      1,    100%,    20,
	move POISN_ATK, xPoisonFangs, "Poison Fangs",    8,      1,     50%,     0,
	move POISN_ATK, xPoisonBarbs, "Poison Barbs",    6,      1,    100%,     0,
	move POISN_ATK, xStingShot,   "Sting Shot",     12,      2,     20%,     0,
	move FLY,       xFly,         "Fly",             0,      3,    100%,     0,
