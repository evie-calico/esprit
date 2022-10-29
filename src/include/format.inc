if !def(TEXTFMT_INC)
def TEXTFMT_INC equ 1

include "res/charmap.inc"

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

macro format
	section "\1", romx
	\1::

	redef format_string equs \2

	rept strlen("{format_string}")
		; This check is *NOT* redundant, as the string may exhaust multiple characters per iteration.
		if strlen("{format_string}") == 0
			break
		endc

		def bracket = strin("{format_string}", "[")

		; If this is not currently a bracket, put it into the rom.
		if bracket == 0
			db "{format_string}"
			break
		elif bracket > 1
			db strsub("{format_string}", 1, bracket - 1)
		endc

		redef format_string equs strsub("{format_string}", bracket + 1)

		def split = strin("{format_string}", ":")
		def bracket = strin("{format_string}", "]")
		
		if !split
			fail "Format specifier without separator"
		endc
		
		if !bracket	
			fail "Unclosed format specifier"
		endc

		def type equs strsub("{format_string}", 1, split - 1)
		def arg equs strsub("{format_string}", split + 1, bracket - split - 1)
		def is_literal = strin("{arg}", ":")
		if is_literal
			redef arg equs strsub("{arg}", 2)
		else
			redef arg equs "wfmt_\1_{arg}"
		endc

		; Previously defined format variables will definitely be in scope since this
		; macro is what defines them. Global/literal labels may or may not be in scope,
		; but it's okay if they're not, this macro won't redundantly define them since
		; it only does the 'pushs/section/new label/pops' for non-literals.
		def is_reused = def({arg})

		for i, _FORMATTER_TYPE_COUNT
			if !def(_FORMATTER_TYPE{d:i})
				fail "Unknown format type: {type}"
			elif !strcmp("{type}", _FORMATTER_TYPE{d:i})
				db _FORMATTER_TYPE{d:i}_CODE
				dw {arg}
				def arg_size = _FORMATTER_TYPE{d:i}_ARG_SIZE
				break
			endc
		endr

		if arg_size && !is_literal && !is_reused
			pushs
				if !def(FORMAT_MEMORY_USAGE)
					def FORMAT_MEMORY_USAGE = 0
				endc

				def FORMAT_MEMORY_USAGE += arg_size

				section "{arg}", wram0
				{arg}:: ds arg_size
			pops
		endc

		redef format_string equs strsub("{format_string}", bracket + 1)

		purge type, arg, is_literal, is_reused, arg_size, split, bracket
	endr

	db 0
endm

macro format_report_usage
	if !def(FORMAT_MEMORY_USAGE)
		def FORMAT_MEMORY_USAGE = 0
	endc

	println "Memory allocated for format strings: {d:FORMAT_MEMORY_USAGE} bytes"
endm

macro add_type
    if !def(_FORMATTER_TYPE_COUNT)
        def _FORMATTER_TYPE_COUNT = 0
    endc

    def _FORMATTER_TYPE{d:_FORMATTER_TYPE_COUNT} equs "\1"
    def _FORMATTER_TYPE{d:_FORMATTER_TYPE_COUNT}_CODE equs "\2"
    def _FORMATTER_TYPE{d:_FORMATTER_TYPE_COUNT}_NARGS equ _NARG - 2
    def _FORMATTER_TYPE{d:_FORMATTER_TYPE_COUNT}_ARG_SIZE equ \3
    def _FORMATTER_TYPE_COUNT += 1
endm

    add_type "str",       TEXT_CALL_PTR,    3
    add_type "u8",        TEXT_U8,          1
    add_type "u16",       TEXT_U16,         2
    add_type "entity",    TEXT_ENTITY_NAME, 1
    add_type "condition", TEXT_RET_FALSE,   1

endc
