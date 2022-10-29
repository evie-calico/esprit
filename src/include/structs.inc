if !def(STRUCTS_INC)
def STRUCTS_INC equ 1
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
; FITNESS for A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE for ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

def STRUCTS_VERSION equs "2.0.0"
macro structs_assert
    assert (\1), "rgbds-structs {STRUCTS_VERSION} bug. Please report at https://github.com/ISSOtm/rgbds-structs, and share your code there!"
endm


; Call with the expected RGBDS-structs version string to ensure your code
; is compatible with the INCLUDEd version of RGBDS-structs.
; Example: `rgbds_structs_version 2.0.0`
macro rgbds_structs_version ; version_string
    def CURRENT_VERSION equs STRRPL("{STRUCTS_VERSION}", ".", ",")

    ; Undefine `EXPECTED_VERSION` if it does not match `CURRENT_VERSION`
    def EXPECTED_VERSION equs STRRPL("\1", ".", ",")
    check_ver {EXPECTED_VERSION}, {CURRENT_VERSION}

    if !def(EXPECTED_VERSION)
        fail "rgbds-structs version \1 is required, which is incompatible with current version {STRUCTS_VERSION}"
    endc

    purge CURRENT_VERSION, EXPECTED_VERSION
endm

; Checks whether trios of version components match.
; Used internally by `rgbds_structs_version`.
macro check_ver ; expected major, minor, patch, current major, minor, patch
    if (\1) != (\4) || (\2) > (\5) || (\3) > (\6)
        purge EXPECTED_VERSION
    endc
endm


; Begins a struct declaration.
macro struct ; struct_name
    if def(STRUCT_NAME) || def(NB_FIELDS)
        fail "Please close struct definitions using `end_struct`"
    endc

    ; Define two internal variables for field definitions
    def STRUCT_NAME equs "\1"
    def NB_FIELDS = 0
    def NB_NONALIASES = 0

    ; Initialize _RS to 0 for defining offset constants
    rsreset
endm

; Ends a struct declaration.
macro end_struct
    ; Define the number of fields and size in bytes
    def {STRUCT_NAME}_nb_fields equ NB_FIELDS
    def {STRUCT_NAME}_nb_nonaliases equ NB_NONALIASES
    def sizeof_{STRUCT_NAME}    equ _RS

    if def(STRUCTS_EXPORT_CONSTANTS)
        export {STRUCT_NAME}_nb_fields, sizeof_{STRUCT_NAME}
    endc

    ; Purge the internal variables defined by `struct`
    purge STRUCT_NAME, NB_FIELDS, NB_NONALIASES
endm


; Defines a field of N bytes.
def bytes equs "new_field rb,"
def words equs "new_field rw,"
def longs equs "new_field rl,"
def alias equs "new_field rb, 0,"

; Extends a new struct by an existing struct, effectively cloning its fields.
macro extends ; struct_type[, sub_struct_name]
    if !def(\1_nb_fields)
        fail "Struct \1 isn't defined!"
    endc
    if _NARG != 1 && _NARG != 2
        fail "Invalid number of arguments, expected 1 or 2"
    endc
    for FIELD_ID, \1_nb_fields
        def EXTENDS_FIELD equs "\1_field{d:FIELD_ID}"
        get_nth_field_info {STRUCT_NAME}, NB_FIELDS

        if _NARG == 1
            def {STRUCT_FIELD_NAME} equs "{{EXTENDS_FIELD}_name}"
        else
            def {STRUCT_FIELD_NAME} equs "\2_{{EXTENDS_FIELD}_name}"
        endc
        def {STRUCT_FIELD} rb {EXTENDS_FIELD}_size
        if def(STRUCTS_EXPORT_CONSTANTS)
            export {STRUCT_FIELD}
        endc
        def {STRUCT_NAME}_{{STRUCT_FIELD_NAME}} equ {STRUCT_FIELD}
        def {STRUCT_FIELD_SIZE} equ {EXTENDS_FIELD}_size
        def {STRUCT_FIELD_TYPE} equs "{{EXTENDS_FIELD}_type}"

        purge_nth_field_info

        def NB_FIELDS += 1
        if {EXTENDS_FIELD}_size != 0
            def NB_NONALIASES += 1
        endc
        purge EXTENDS_FIELD
    endr
endm


; Defines equs strings pertaining to a struct's Nth field.
; Used internally by `new_field` and `dstruct`.
macro get_nth_field_info ; struct_name, field_id
    def STRUCT_FIELD      equs "\1_field{d:\2}"       ; prefix for other equs
    def STRUCT_FIELD_NAME equs "{STRUCT_FIELD}_name"  ; field's name
    def STRUCT_FIELD_TYPE equs "{STRUCT_FIELD}_type"  ; type ("b", "l", or "l")
    def STRUCT_FIELD_SIZE equs "{STRUCT_FIELD}_size"  ; sizeof(type) * nb_el
endm

; Purges the variables defined by `get_nth_field_info`.
; Used internally by `new_field` and `dstruct`.
def purge_nth_field_info equs "purge STRUCT_FIELD, STRUCT_FIELD_NAME, STRUCT_FIELD_TYPE, STRUCT_FIELD_SIZE"

; Defines a field with a given RS type (`rb`, `rw`, or `rl`).
; Used internally by `bytes`, `words`, and `longs`.
macro new_field ; rs_type, nb_elems, field_name
    if !def(STRUCT_NAME) || !def(NB_FIELDS)
        fail "Please start defining a struct, using `struct`"
    endc

    get_nth_field_info {STRUCT_NAME}, NB_FIELDS

    ; Set field name
    def {STRUCT_FIELD_NAME} equs "\3"
    ; Set field offset
    def {STRUCT_FIELD} \1 (\2)
    if def(STRUCTS_EXPORT_CONSTANTS)
        export {STRUCT_FIELD}
    endc
    ; Alias this in a human-comprehensible manner
    def {STRUCT_NAME}_\3 equ {STRUCT_FIELD}
    ; Compute field size
    def {STRUCT_FIELD_SIZE} equ _RS - {STRUCT_FIELD}
    ; Set properties
    def {STRUCT_FIELD_TYPE} equs strsub("\1", 2, 1)

    purge_nth_field_info

    def NB_FIELDS += 1
    if \2 != 0
        def NB_NONALIASES += 1
    endc
endm


; Strips whitespace from the left of a string.
; Used internally by `dstruct`.
macro lstrip ; string_variable
    for START_POS, 1, strlen("{\1}") + 1
        if !strin(" \t", strsub("{\1}", START_POS, 1))
            break
        endc
    endr
    redef \1 equs strsub("{\1}", START_POS)
    purge START_POS
endm

; Allocates space for a struct in memory.
; If no further arguments are supplied, the space is allocated using `ds`.
; Otherwise, the data is written to memory using the appropriate types.
; For example, a struct defined with `bytes 1, Field1` and `words 3, Field2`
; could take four extra arguments, one byte then three words.
; Each such argument would have an equal sign between the name and value.
macro dstruct ; struct_type, instance_name[, ...]
    if !def(\1_nb_fields)
        fail "Struct \1 isn't defined!"
    elif _NARG != 2 && _NARG != 2 + \1_nb_nonaliases
        ; We must have either a RAM declaration (no data args)
        ; or a ROM one (RAM args + data args)
        fail strfmt("Expected 2 or %u args to `dstruct`, but got {d:_NARG}", 2 + \1_nb_nonaliases)
    endc

    ; RGBASM always expands macro args, so `if _NARG > 2 && strin("\3", "=")`
    ; would error out when there are only two args.
    ; Therefore, the condition is checked here (we can't nest the `if`s over
    ; there because that would require a duplicated `else`).
    def IS_NAMED_INSTANTIATION = 0
    if _NARG > 2
        redef IS_NAMED_INSTANTIATION = strin("\3", "=")
    endc

    if IS_NAMED_INSTANTIATION
        ; This is a named instantiation; translate that to an ordered one.
        ; This is needed because data has to be laid out in order, so some translation is needed anyway.
        ; And finally, I believe it's better to re-use the existing code at the cost of a single nested macro.

        for ARG_NUM, 3, _NARG + 1
            ; Remove leading whitespace to obtain something like ".name=value"
            ; (this enables a simple check for starting with a period)
            redef CUR_ARG equs "\<ARG_NUM>"
            lstrip CUR_ARG

            ; Ensure that the argument has a name and a value,
            ; separated by an equal sign
            def EQUAL_POS = strin("{CUR_ARG}", "=")
            if !EQUAL_POS
                fail "\"{CUR_ARG}\" is not a named initializer!"
            elif strcmp(strsub("{CUR_ARG}", 1, 1), ".")
                fail "\"{CUR_ARG}\" does not start with a period!"
            endc

            ; Find out which field the current argument is
            for FIELD_ID, \1_nb_fields
                if !strcmp(strsub("{CUR_ARG}", 2, EQUAL_POS - 2), "{\1_field{d:FIELD_ID}_name}")
                    if \1_field{d:FIELD_ID}_size == 0
                        fail "Cannot initialize an alias"
                    endc
                    break ; Match found!
                endc
            endr

            if FIELD_ID == \1_nb_fields
                fail "\"{CUR_ARG}\" does not match any member of \1"
            elif def(FIELD_{d:FIELD_ID}_INITIALIZER)
                fail "\"{CUR_ARG}\" conflicts with \"{FIELD_{d:FIELD_ID}_ARG}\""
            endc

            ; Save the argument to report in case a later argument conflicts with it
            def FIELD_{d:FIELD_ID}_ARG equs "{CUR_ARG}"

            ; Escape any commas in a multi-byte argument initializer so it can
            ; be passed as one argument to the nested ordered instantiation
            def FIELD_{d:FIELD_ID}_INITIALIZER equs STRRPL(strsub("{CUR_ARG}", EQUAL_POS + 1), ",", "\\,")
        endr
        purge ARG_NUM, CUR_ARG

        ; Now that we matched each named initializer to their order,
        ; invoke the macro again but without names
        def ORDERED_ARGS equs "\1, \2"
        for FIELD_ID, \1_nb_fields
            if \1_field{d:FIELD_ID}_size != 0
                redef ORDERED_ARGS equs "{ORDERED_ARGS}, {FIELD_{d:FIELD_ID}_INITIALIZER}"
                purge FIELD_{d:FIELD_ID}_ARG, FIELD_{d:FIELD_ID}_INITIALIZER
            endc
        endr
        purge FIELD_ID

        ; Do the nested ordered instantiation
        dstruct {ORDERED_ARGS} ; purges IS_NAMED_INSTANTIATION
        purge ORDERED_ARGS

    else
        ; This is an ordered instantiation, not a named one.

        ; Define the struct's root label
        \2::

        if def(STRUCT_SEPARATOR)
            def DSTRUCT_SEPARATOR equs "{STRUCT_SEPARATOR}"
        else
            def DSTRUCT_SEPARATOR equs "_"
        endc
        ; Define each field
        def ARG_NUM = 3
        for FIELD_ID, \1_nb_fields
            get_nth_field_info \1, FIELD_ID

            ; Define the label for the field
            \2_{{STRUCT_FIELD_NAME}}::

            if STRUCT_FIELD_SIZE != 0 ; Skip aliases
                ; Declare the space for the field
                if ARG_NUM <= _NARG
                    ; ROM declaration; use `db`, `dw`, or `dl`
                    d{{STRUCT_FIELD_TYPE}} \<ARG_NUM>
                    redef ARG_NUM = ARG_NUM + 1
                endc
                ; Add padding as necessary after the provided initializer
                ; (possibly all of it, especially for RAM use)
                if {STRUCT_FIELD_SIZE} < @ - \2_{{STRUCT_FIELD_NAME}}
                    fail strfmt("Initializer for %s is %u bytes, expected %u at most", "\2_{{STRUCT_FIELD_NAME}}", @ - \2_{{STRUCT_FIELD_NAME}}, {STRUCT_FIELD_SIZE})
                endc
                ds {STRUCT_FIELD_SIZE} - (@ - \2_{{STRUCT_FIELD_NAME}})
            endc

            purge_nth_field_info
        endr
        purge FIELD_ID, ARG_NUM, DSTRUCT_SEPARATOR

        ; Define instance's properties from struct's
        def \2_nb_fields equ \1_nb_fields
        def sizeof_\2    equ @ - (\2)
        structs_assert sizeof_\1 == sizeof_\2

        if def(STRUCTS_EXPORT_CONSTANTS)
            export \2_nb_fields, sizeof_\2
        endc

        purge IS_NAMED_INSTANTIATION
    endc
endm


; Allocates space for an array of structs in memory.
; Each struct will have the index appended to its name **as decimal**.
; For example: `dstructs 32, NPC, wNPC` will define `wNPC0`, `wNPC1`, and so on until `wNPC31`.
; This is a change from the previous version of rgbds-structs, where the index was uppercase hexadecimal.
; Does not support data declarations because I think each struct should be defined individually for that purpose.
macro dstructs ; nb_structs, struct_type, instance_name
    if _NARG != 3
        fail "`dstructs` only takes 3 arguments!"
    endc

    for STRUCT_ID, \1
        dstruct \2, \3{d:STRUCT_ID}
    endr
    purge STRUCT_ID
endm

endc
