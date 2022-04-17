; MIT License
;
; Copyright (c) 2018-2021 Eldred Habert and contributors
; Originally hosted at https://github.com/ISSOtm/rgbds-structs
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

	IF !DEF(STRUCTS_INC)
DEF STRUCTS_INC EQU 1

; Call with the expected RGBDS-structs version string to ensure your code
; is compatible with the INCLUDEd version of RGBDS-structs.
; Example: `rgbds_structs_version 2.0.0`
MACRO rgbds_structs_version ; version_string
	DEF CURRENT_VERSION EQUS "2,0,0"

	; Undefine `EXPECTED_VERSION` if it does not match `CURRENT_VERSION`
	DEF EXPECTED_VERSION EQUS STRRPL("\1", ".", ",")
	check_ver {EXPECTED_VERSION}, {CURRENT_VERSION}

	IF !DEF(EXPECTED_VERSION)
		FAIL STRCAT("RGBDS-structs version \1 is required, ", \
					"which is incompatible with current version ", \
					STRRPL("{CURRENT_VERSION}", ",", "."))
	ENDC

	PURGE CURRENT_VERSION, EXPECTED_VERSION
ENDM

; Checks whether trios of version components match.
; Used internally by `rgbds_structs_version`.
MACRO check_ver ; expected major, minor, patch, current major, minor, patch
	IF \1 != \4 || \2 > \5 || \3 > \6
		PURGE EXPECTED_VERSION
	ENDC
ENDM


; Begins a struct declaration.
MACRO struct ; struct_name
	IF DEF(STRUCT_NAME) || DEF(NB_FIELDS)
		FAIL "Please close struct definitions using `end_struct`"
	ENDC

	; Define two internal variables for field definitions
	DEF STRUCT_NAME EQUS "\1"
	DEF NB_FIELDS = 0

	; Initialize _RS to 0 for defining offset constants
	RSRESET
ENDM

; Ends a struct declaration.
MACRO end_struct
	; Define the number of fields and size in bytes
	DEF {STRUCT_NAME}_nb_fields EQU NB_FIELDS
	DEF sizeof_{STRUCT_NAME}    EQU _RS

	; Purge the internal variables defined by `struct`
	PURGE STRUCT_NAME, NB_FIELDS
ENDM


; Defines a field of N bytes.
MACRO bytes ; nb_bytes, field_name
	new_field \1, RB, \2
ENDM

; Defines a field of N*2 bytes.
MACRO words ; nb_words, field_name
	new_field \1, RW, \2
ENDM

; Defines a field of N*4 bytes.
MACRO longs ; nb_longs, field_name
	new_field \1, RL, \2
ENDM

; Defines a union
MACRO dunion ; field_name
	new_field 0, RB, \1
ENDM

; Defines EQUS strings pertaining to a struct's Nth field.
; Used internally by `new_field` and `dstruct`.
MACRO get_nth_field_info ; struct_name, field_id
	DEF STRUCT_FIELD      EQUS "\1_field{d:\2}"       ; prefix for other EQUS
	DEF STRUCT_FIELD_NAME EQUS "{STRUCT_FIELD}_name"  ; field's name
	DEF STRUCT_FIELD_TYPE EQUS "{STRUCT_FIELD}_type"  ; type ("B", "W", or "L")
	DEF STRUCT_FIELD_NBEL EQUS "{STRUCT_FIELD}_nb_el" ; number of elements
	DEF STRUCT_FIELD_SIZE EQUS "{STRUCT_FIELD}_size"  ; sizeof(type) * nb_el
ENDM

; Purges the variables defined by `get_nth_field_info`.
; Used internally by `new_field` and `dstruct`.
MACRO purge_nth_field_info
	PURGE STRUCT_FIELD
	PURGE STRUCT_FIELD_NAME
	PURGE STRUCT_FIELD_TYPE
	PURGE STRUCT_FIELD_NBEL
	PURGE STRUCT_FIELD_SIZE
ENDM

; Defines a field with a given RS type (`RB`, `RW`, or `RL`).
; Used internally by `bytes`, `words`, and `longs`.
MACRO new_field ; nb_elems, rs_type, field_name
	IF !DEF(STRUCT_NAME) || !DEF(NB_FIELDS)
		FAIL "Please start defining a struct, using `struct`"
	ENDC

	get_nth_field_info {STRUCT_NAME}, NB_FIELDS

	; Set field name
	DEF {STRUCT_FIELD_NAME} EQUS "\3"
	; Set field offset
	DEF {STRUCT_FIELD} \2 (\1)
	; Alias this in a human-comprehensible manner
	DEF {STRUCT_NAME}_\3 EQU {STRUCT_FIELD}
	; Compute field size
	DEF {STRUCT_FIELD_SIZE} EQU _RS - {STRUCT_FIELD}
	; Set properties
	DEF {STRUCT_FIELD_NBEL} EQU \1
	DEF {STRUCT_FIELD_TYPE} EQUS STRSUB("\2", 2, 1)

	purge_nth_field_info

	REDEF NB_FIELDS = NB_FIELDS + 1
ENDM


; Strips whitespace from the left of a string.
; Used internally by `dstruct`.
MACRO lstrip ; string_variable
	FOR START_POS, 1, STRLEN("{\1}") + 1
		IF STRCMP(STRSUB("{\1}", START_POS, 1), " ") && \
		   STRCMP(STRSUB("{\1}", START_POS, 1), "\t")
			BREAK
		ENDC
	ENDR
	REDEF \1 EQUS STRSUB("{\1}", START_POS)
	PURGE START_POS
ENDM

; Extends a new struct by an existing struct, effectively cloning its fields.
MACRO extends ; struct_type
	IF !DEF(\1_nb_fields)
		FAIL "Struct \1 isn't defined!"
	ENDC
	FOR FIELD_ID, \1_nb_fields
		; Grab relevant information on each field and define a new element with
		; them.
		get_nth_field_info \1, FIELD_ID
		DEF EXTENDS_NBEL EQU STRUCT_FIELD_NBEL
		DEF EXTENDS_TYPE EQUS STRCAT("R", "{{STRUCT_FIELD_TYPE}}")
		DEF EXTENDS_NAME EQUS "{{STRUCT_FIELD_NAME}}"
		purge_nth_field_info
		; Create a new field using tha gathered info.
		new_field EXTENDS_NBEL, {EXTENDS_TYPE}, {EXTENDS_NAME}
		PURGE EXTENDS_NBEL
		PURGE EXTENDS_TYPE
		PURGE EXTENDS_NAME
	ENDR
ENDM

; Allocates space for a struct in memory.
; If no further arguments are supplied, the space is allocated using `ds`.
; Otherwise, the data is written to memory using the appropriate types.
; For example, a struct defined with `bytes 1, Field1` and `words 3, Field2`
; could take four extra arguments, one byte then three words.
; Each such argument would have an equal sign between the name and value.
MACRO dstruct ; struct_type, instance_name[, ...]
	IF !DEF(\1_nb_fields)
		FAIL "Struct \1 isn't defined!"
	ELIF _NARG != 2 && _NARG != 2 + \1_nb_fields
		; We must have either a RAM declaration (no data args)
		; or a ROM one (RAM args + data args)
		DEF EXPECTED_NARG = 2 + \1_nb_fields
		FAIL STRCAT("Invalid number of arguments, expected 2 or ", \
					"{d:EXPECTED_NARG} but got {d:_NARG}")
	ENDC

	; RGBASM always expands macro args, so `IF _NARG > 2 && STRIN("\3", "=")`
	; would error out when there are only two args.
	; Therefore, the condition is checked here (we can't nest the `IF`s over
	; there because that would require a duplicated `ELSE`).
	DEF IS_NAMED_INSTANTIATION = 0
	IF _NARG > 2
		REDEF IS_NAMED_INSTANTIATION = STRIN("\3", "=")
	ENDC

	IF IS_NAMED_INSTANTIATION
		; This is a named instantiation; translate that to an ordered one.
		; This is needed because data has to be laid out in order, so some
		; translation is needed anyway.
		; And finally, I believe it's better to re-use the existing code at
		; the cost of a single nested macro.

		FOR ARG_NUM, 3, _NARG + 1
			; Remove leading whitespace to obtain something like ".name=value"
			; (this enables a simple check for starting with a period)
			REDEF CUR_ARG EQUS "\<ARG_NUM>"
			lstrip CUR_ARG

			; Ensure that the argument has a name and a value,
			; separated by an equal sign
			DEF EQUAL_POS = STRIN("{CUR_ARG}", "=")
			IF !EQUAL_POS
				FAIL STRCAT("Argument #{d:ARG_NUM} (\<ARG_NUM>) does not ", \
							"contain an equal sign in this named instantiation")
			ELIF STRCMP(STRSUB("{CUR_ARG}", 1, 1), ".")
				FAIL STRCAT("Argument #{d:ARG_NUM} (\<ARG_NUM>) does not ", \
							"start with a period")
			ENDC

			; Find out which field the current argument is
			FOR FIELD_ID, \1_nb_fields
				IF !STRCMP(STRLWR(STRSUB("{CUR_ARG}", 2, EQUAL_POS - 2)), \
						   STRLWR("{\1_field{d:FIELD_ID}_name}"))
					BREAK ; Match found!
				ENDC
			ENDR

			IF FIELD_ID == \1_nb_fields
				FAIL STRCAT("Argument #{d:ARG_NUM} (\<ARG_NUM>) ", \
							"does not match any field of the struct")
			ELIF DEF(FIELD_{d:FIELD_ID}_INITIALIZER)
				FAIL STRCAT("Argument #{d:ARG_NUM} (\<ARG_NUM>) ", \
							"conflicts with #{d:FIELD_{d:FIELD_ID}_ARG_NUM} ", \
							"({FIELD_{d:FIELD_ID}_ARG})")
			ENDC

			; Save the argument number and value to report in case a
			; later argument conflicts with it
			DEF FIELD_{d:FIELD_ID}_ARG_NUM EQU ARG_NUM
			DEF FIELD_{d:FIELD_ID}_ARG EQUS "{CUR_ARG}"

			; Escape any commas in a multi-byte argument initializer so it can
			; be passed as one argument to the nested ordered instantiation
			DEF FIELD_{d:FIELD_ID}_INITIALIZER EQUS \
				STRRPL(STRSUB("{CUR_ARG}", EQUAL_POS + 1), ",", "\\,")
		ENDR
		PURGE ARG_NUM, CUR_ARG

		; Now that we matched each named initializer to their order,
		; invoke the macro again but without names
		DEF ORDERED_ARGS EQUS "\1, \2"
		FOR FIELD_ID, \1_nb_fields
			REDEF ORDERED_ARGS EQUS STRCAT("{ORDERED_ARGS}, ", \
										   "{FIELD_{d:FIELD_ID}_INITIALIZER}")
			PURGE FIELD_{d:FIELD_ID}_ARG_NUM
			PURGE FIELD_{d:FIELD_ID}_ARG
			PURGE FIELD_{d:FIELD_ID}_INITIALIZER
		ENDR
		PURGE FIELD_ID

		; Do the nested ordered instantiation
		dstruct {ORDERED_ARGS} ; purges IS_NAMED_INSTANTIATION
		PURGE ORDERED_ARGS

	ELSE
		; This is an ordered instantiation, not a named one.

		; Define the struct's root label
		\2::

		; Define instance's properties from struct's
		DEF \2_nb_fields EQU \1_nb_fields
		DEF sizeof_\2    EQU sizeof_\1

		; Define each field
		DEF ARG_NUM = 3
		FOR FIELD_ID, \1_nb_fields
			get_nth_field_info \1, FIELD_ID

			; Define the label for the field
			\2_{{STRUCT_FIELD_NAME}}::

			; Declare the space for the field
			IF ARG_NUM > _NARG
				; RAM declaration; use `DS`
				DS {STRUCT_FIELD_SIZE}
			ELSE
				; ROM declaration; use `DB`, `DW`, or `DL`
				IF !STRCMP("{{STRUCT_FIELD_TYPE}}", "B")
					; Multi-byte fields may be initialized with
					; a sequence of comma-separated bytes
					DS {STRUCT_FIELD_SIZE}, \<ARG_NUM>
				ELSE
					REPT STRUCT_FIELD_NBEL
						PRINT "STRUCT_FIELD_TYPE {STRUCT_FIELD_TYPE} {{STRUCT_FIELD_TYPE}}\n"
						D{{STRUCT_FIELD_TYPE}} \<ARG_NUM>
					ENDR
				ENDC
				REDEF ARG_NUM = ARG_NUM + 1
			ENDC

			purge_nth_field_info
		ENDR
		PURGE FIELD_ID, ARG_NUM

		PURGE IS_NAMED_INSTANTIATION
	ENDC
ENDM


; Allocates space for an array of structs in memory.
; Each struct will have the index appended to its name **as decimal**.
; For example: `dstructs 32, NPC, wNPC` will define
; wNPC0, wNPC1, and so on until wNPC31.
; This is a change from the previous version of RGBDS-structs,
; where the index was uppercase hexadecimal.
; Does not support data declarations because I think each struct should be
; defined individually for that purpose.
MACRO dstructs ; nb_structs, struct_type, instance_name
	FOR STRUCT_ID, \1
		dstruct \2, \3{d:STRUCT_ID}
	ENDR
	PURGE STRUCT_ID
ENDM

	ENDC
