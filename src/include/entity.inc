IF !DEF(ENTITY_INC)
DEF ENTITY_INC EQU 1

INCLUDE "structs.inc"

DEF NB_ALLIES EQU 3
DEF NB_ENEMIES EQU 5
DEF NB_ENTITIES EQU 8

    ; Constant data about an entity, such as graphics, moves, and stats.
    struct EntityData
        words 1, Graphics
    end_struct

    struct Entity
        ; Far pointer to a EntityData struct in ROM.
        bytes 1, Bank
        words 1, Data
        ; The current position of the entity's sprite, in 12.4 fixed-point.
        words 1, SpriteY
        words 1, SpriteX
        ; The entity's current position on a 16x16 tile grid.
        bytes 1, PosX
        bytes 1, PosY
        ; The entity's current and last direction, used to update graphics.
        bytes 1, Direction
        bytes 1, LastDirection
    end_struct

ENDC
