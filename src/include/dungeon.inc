IF !DEF(DUNGEON_INC)
DEF DUNGEON_INC EQU 1

INCLUDE "structs.inc"

RSRESET
DEF TILE_CLEAR RB 1
DEF TILE_WALL RB 1

    struct Dungeon
        words 1, Tileset
        words 1, Palette
    end_struct

ENDC
