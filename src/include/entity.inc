IF !DEF(ENTITY_INC)
DEF ENTITY_INC EQU 1

INCLUDE "structs.inc"

DEF NB_ENTITIES EQU 8

    ; Constant data about an entity, such as graphics, moves, and stats.
    struct EntityData

    end_struct

    struct Entity
        bytes 1, Bank
        words 1, Data
        words 1, YPos
        words 1, XPos
    end_struct

ENDC
