MACRO get_npc_alias
	IF STRSUB("\1", 1, 1) == "\""
		IF !STRCMP(\1, "player")
			db 0
		ELIF !STRCMP(\1, "partner")
			db 1
		ELIF !STRCMP(\1, "self")
			db -1
		ELSE
			FAIL "Undefined npc name \1. Valid options are: player, partner, or self"
		ENDC
	ELSE
		db \1
	ENDC
ENDM

MACRO npc_move
	db script_npc_move_BYTECODE
	get_npc_alias \1
	dw \3, \2
ENDM

MACRO npc_set_frame
	db script_npc_set_frame_BYTECODE
	get_npc_alias \1
	db \2
ENDM