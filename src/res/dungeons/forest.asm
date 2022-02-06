SECTION "Forest Dungeon", ROMX
xForestDungeon::
    dw .tileset
    dw .palette
.tileset INCBIN "res/tree_tiles.2bpp"
.palette
    db $C0, $50, $60
    db $58, $80, $38
    db $58, $00, $18
    db $20, $00, $00
