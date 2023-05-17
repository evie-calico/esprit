/*

Dungeon Design:

When playing PMD2 for the first time, my favorite dungeon was the
Northern Desert, because when you first explore it the sandstorm and limited
items force you to carefully manage your health and inventory.
This is a big change from most of the dungeons in PMD, which also end up feeling
kinda bland and samey because they lack much variety besides the enemy types
(and technically items types too, but the variation is so poor that you'd never
notice).

With esprit, I pretty much want every level to be like Northern Desert.
Harsh, unforgiving, and with limited resources. A lot of the game's mechanics
revolve around this idea, like the lack of health regen and the limited inventory
size.
Dungeon design is obviously a big part of this balance: dungeons need to be long
enough to wear the player down, and provide just enough resources so that the player
isn't left with a surplus.

In addition, dungeons need to feel unique to keep the player interested in going on.
If enemies and items always feel the same, the game becomes one big dungeon with
a few breaks in between. Items and enemies should be appropriate for the setting
(no random fruits in caves or useful scarves lying around) and synergize with each
other (for example, when a poisonous snake is introduced, the dungeon also provides
poison heals)

Enemies aren't the only threats players can face within a dungeon. Using on_tick
functions, we can make dungeons that apply negative effects, like having capped
energy on the final floor as the party gets tired, or heatstroke that prevents
the party from restroing enery.

*/

include "defines.inc"
include "dungeon.inc"
include "entity.inc"

macro def_equs
    redef \1 equs "\2"
endm

macro try_purge
    rept _NARG
        if def(\1)
            purge \1
        endc
        shift 1
    endr
endm

macro _new_dungeon
    redef NAME equs "\1"
    redef TICK_FUNCTION equs "null"
    redef ALT_COLOR_TERMINALS equs "0"

    for i, DUNGEON_ITEM_COUNT
        try_purge ITEM{d:i}
    endr
    for i, DUNGEON_ENTITY_COUNT
        try_purge ENEMY{d:i}_LEVEL
        try_purge ENEMY{d:i}
    endr
endm

macro dungeon
    try_purge TILESET, TYPE, FLOORS, COMPLETION_TYPE, COMPLETION_ARG, MUSIC, TICK_FUNCTION

    _new_dungeon \1
endm

macro get_next_name
    if strin("{NAME}", "_part")
        def part equs strsub("{NAME}", strlen("{NAME}"))
        def part_value = part + 1
        redef NEXT_NAME equs strcat(strsub("{NAME}", 1, strlen("{NAME}") - 1), "{d:part_value}")
        purge part, part_value
    else
        redef NEXT_NAME equs strcat("{NAME}", "_part2")
    endc
endm

macro next_part
    get_next_name
    _new_dungeon {NEXT_NAME}

endm
macro tileset ; path
    def_equs TILESET, \1
endm

macro shape ; dungeon generation type
    def_equs TYPE, \1
endm

macro after_floor ; number, action, [arg]
    def_equs FLOORS, \1
    redef COMPLETION_TYPE equs strupr("\2")
    if !strcmp(strupr("\2"), "SWITCH")
        get_next_name
        def_equs COMPLETION_ARG, {NEXT_NAME}
    else
        def_equs COMPLETION_ARG, \3
    endc
endm

macro on_tick
    def_equs TICK_FUNCTION, \1
endm

macro music
    def_equs MUSIC, \1
endm

macro item
    for i, DUNGEON_ITEM_COUNT
        if !def(ITEM{d:i})
            def_equs ITEM{d:i}, \1
            break
        endc
    endr
    if i == DUNGEON_ITEM_COUNT
        fail "Each dungeon is limited to {d:DUNGEON_ITEM_COUNT} items"
    endc
endm

macro items_per_floor
    def_equs ITEM_COUNT, \1
endm

macro enemy ; name, level
    for i, DUNGEON_ENTITY_COUNT
        if !def(ENEMY{d:i})
            def_equs ENEMY{d:i}, \1
            def_equs ENEMY{d:i}_LEVEL, \2
            break
        endc
    endr
    if i == DUNGEON_ENTITY_COUNT
        fail "Each dungeon is limited to {d:DUNGEON_ENTITY_COUNT} enemies"
    endc
endm

macro use_floor_color_for_terminals
    def_equs ALT_COLOR_TERMINALS, 1
endm

macro end
    {NAME}:: dw .tileset, .palette

    for i, DUNGEON_ITEM_COUNT
        farptr ITEM{d:i}
    endr

    db DUNGEON_TYPE_{TYPE}, (FLOORS) + 1, (ITEM_COUNT)

    for i, DUNGEON_ENTITY_COUNT
        db ENEMY{d:i}_LEVEL
        farptr ENEMY{d:i}
    endr

    if DUNGEON_COMPLETION_{COMPLETION_TYPE} == DUNGEON_COMPLETION_EXIT
        db DUNGEON_COMPLETION_{COMPLETION_TYPE}
        db {COMPLETION_ARG}
        ; Padding for exit type
        db 0, 0
    else
        db DUNGEON_COMPLETION_{COMPLETION_TYPE}
        db bank({COMPLETION_ARG})
        db low({COMPLETION_ARG})
        db high({COMPLETION_ARG})
    endc


    dw {MUSIC}
    db bank({MUSIC})

    dw {TICK_FUNCTION}

    db {ALT_COLOR_TERMINALS}

    assert sizeof_Dungeon == 61
    .tileset incbin {TILESET}
endm

macro dungeon_palette
.palette
    redef BACKGROUND_RED equ \1
    redef BACKGROUND_GREEN equ \2
    redef BACKGROUND_BLUE equ \3
    rept 3
        rgb BACKGROUND_RED, BACKGROUND_GREEN, BACKGROUND_BLUE
        shift 3
        rgb \1, \2, \3
        shift 3
        rgb \1, \2, \3
        shift 3
        rgb \1, \2, \3
    endr
endm

macro dungeon_hex
.palette
    redef BACKGROUND equs "\1"
    shift 1
    rept 3
        hex {BACKGROUND}, \1, \2, \3
        shift 3
    endr
endm
