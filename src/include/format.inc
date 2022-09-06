IF !DEF(TEXTFMT_INC)
DEF TEXTFMT_INC EQU 1

INCLUDE "res/charmap.inc"

; This macro allows you to write simple, readable format strings in RGBASM

; Every format string needs a name:
; format xString

; To write plain text, simply use a quoted string:
; format xString, "Hello, world!"

; To insert a formatted variable, use the syntax: [type:name]
; format xString, "Hello, [str:world]"
; This will generate a variable under the name `wfmt_{string name}_{variable name}`

; To re-use an existing global variable, use two colons:
; format xString, "Hello, [str::GlobalWorld]"

; To re-use an existing format variable, use a colon followed by a <
; format xEcho, "[str:phrase] [str:<phrase] [str:<phrase] [str:<phrase]"

macro format
	section "\1", romx
	\1::

	redef format_string equs \2

	rept 65536
		if strlen("{format_string}") == 0
			break
		endc

		def bracket = strin("{format_string}", "[")

		; If this is not currently a bracket, put it into the rom.
		if bracket == 0
			db "{format_string}", 0
			break
		elif bracket > 1
			def literal equs strsub("{format_string}", 1, bracket - 1)
			db "{literal}"
			purge literal
		endc

		redef format_string equs strsub("{format_string}", bracket + 1)

		def split = strin("{format_string}", ":")
		def bracket = strin("{format_string}", "]")
		
		if !split
			fail "Format specifier without seperator"
		endc
		
		if !bracket	
			fail "Unclosed format specifier"
		endc

		def type equs strsub("{format_string}", 1, split - 1)
		def arg equs strsub("{format_string}", split + 1, bracket - split - 1)
		def is_literal = strin("{arg}", ":")
		def is_reused = strin("{arg}", "<")
		
		if is_literal || is_reused
			redef arg equs strsub("{arg}", 2)
		endc

		if !is_literal
			redef arg equs "wfmt_\1_{arg}"
		endc

		for i, 65536
			if !def(_FORMATTER_TYPE{d:i})
				fail "Unknown format type: {type}"
			endc

			if !strcmp("{type}", _FORMATTER_TYPE{d:i})
				_FORMATTER_TYPE{d:i}_CONTENTS
				break
			endc
		endr

		if arg_size && !is_literal && !is_reused
			pushs
				section "{arg}", wram0
				{arg}:: ds arg_size
			pops
		endc

		redef format_string equs strsub("{format_string}", bracket + 1)

		purge type, arg, is_literal, is_reused, arg_size, split, bracket
	endr
endm

def _FORMATTER_TYPE_COUNT = 0

macro add_type
	def _FORMATTER_TYPE{d:_FORMATTER_TYPE_COUNT} equs "\1"
	def _FORMATTER_TYPE{d:_FORMATTER_TYPE_COUNT}_CONTENTS equs "\2"
	def _FORMATTER_TYPE_COUNT += 1
ENDM

	add_type "str", \
		db TEXT_CALL_PTR \n\
		dw \{arg\} \n\
		def arg_size = 3

	add_type "u8", \
		db TEXT_U8 \n\
		dw \{arg\} \n\
		def arg_size = 1

	add_type "u16", \
		db TEXT_U16 \n\
		dw \{arg\} \n\
		def arg_size = 2

	add_type "entity", \
		db TEXT_ENTITY_NAME \n\
		dw \{arg\} \n\
		def arg_size = 1

	add_type "condition", \
		db TEXT_RET_FALSE \n\
		dw \{arg\} \n\
		def arg_size = 1

ENDC
