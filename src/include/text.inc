IF !DEF(TEXTFMT_INC)
DEF TEXTFMT_INC EQU 1

INCLUDE "res/charmap.inc"

; This macro allows you to write simple, readable format strings in RGBASM

; Every format string needs a name:
; format xString

; To write plain text, simply use a quoted string:
; format xString, "Hello, world!"

; To insert a formatted variable, use the syntax: {type}:{name}
; format xString, "Hello, ", str:world
; This will generate a variable under the name `wfmt_{string name}_{variable name}`

; To re-use an existing global variable, use two colons:
; format xString, "Hello, ", str::GlobalWorld

; To re-use an existing format variable, use a colon followed by a <
; format xEcho, str:phrase, " ", str:<phrase, " ", str:<phrase, " ", str:<phrase

macro format
	redef id equs "\1"
	shift 1

	section "{id}", romx
	{id}::

	rept 65536
		if !_NARG
			break
		endc

		if charsub("\1", 1) == "\""
			db \1
		else
			def split = strin("\1", ":")
			if split
				redef type equs strsub("\1", 1, split - 1)
				redef arg equs strsub("\1", split + 1)

				def is_literal = strin("{arg}", ":")
				def is_reused = strin("{arg}", "<")
				
				if is_literal || is_reused
					redef arg equs strsub("{arg}", 2)
				endc

				if !is_literal
					redef arg equs "wfmt_{id}_{arg}"
				endc

				if !strcmp("{type}", "str")
					db TEXT_CALL_PTR
					dw {arg}
					def arg_size = 3
				elif !strcmp("{type}", "u8")
					db TEXT_U8
					dw {arg}
					def arg_size = 1
				elif !strcmp("{type}", "u16")
					db TEXT_U16
					dw {arg}
					def arg_size = 2
				elif !strcmp("{type}", "entity")
					db TEXT_ENTITY_NAME
					dw {arg}
					def arg_size = 1
				elif !strcmp("{type}", "condition")
					db TEXT_RET_FALSE
					dw {arg}
					def arg_size = 1
				endc

				if !is_literal && !is_reused
					pushs
						section "{arg}", wram0
						{arg}:: ds arg_size
					pops
				endc
			else
				fail "Unknown format \"\1\""
			endc
		endc

		shift 1
	endr

	db 0
endm

ENDC
