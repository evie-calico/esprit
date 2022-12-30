/*
Super simple regex written in rgbasm
This is only for *extremely simple* parsing.
It is not a complete regex implementation.

Supported features:
- character matching (including . for "any", [], and [^])
- repetition with *, +, ?, and {n,m}
- captures
- escapes

How to use:
	regex rx, s[, captures]

The library will simply throw a warning if the regex string does not match.
The real use of this macro are *captures*.
Anything within parenthesis in the regex will be placed into the capture variable provided.

For example:
	regex "He(l+)o, world!", "Hellllllllllom world!", Ls
	println "{Ls}"

Outputs:
	llllllllll

Multiple capture groups can be used by passing in additional arguments:
	regex "([Hh]el+o), world(!?)", "Helo, world!", hello, exclaimation
	println "world, {hello}{exclamation}"

Outputs:
	world, Helo!
*/

def MATCH_MODE_NONE equ 0
def MATCH_MODE_MATCH equ 1
def MATCH_MODE_DONT equ 2
def MATCH_MODE_ANY equ 3

macro _match ; char
	if capturing
		redef {capture{d:active_capture}} equs strcat("{{capture{d:active_capture}}}", \1)
	endc
endm

macro popchars ; s, nb
	redef \1 equs strsub("{\1}", 1 + (\2))
endm

macro regex ; rx, s, [captures]
	def _source_rx equs \1
	def _rx equs \1
	def _source_s equs \2
	def _s equs \2
	def captures = _NARG - 2

	shift 2
	for i, captures
		redef capture{d:i} equs "\1"
		redef \1 equs ""
		shift 1
	endr

	def capturing = 0
	def active_capture = 0

	rept strlen("{_rx}")
		; A loop may exhaust multiple characters, so check again here.
		if strlen("{_rx}") == 0
			break
		endc

		def match_mode = MATCH_MODE_NONE
		redef matchables equs ""
		redef next_char equs strsub("{_rx}", 1, 1)

		if !strcmp("{next_char}", ".")
			def match_mode = MATCH_MODE_ANY
		elif !strcmp("{next_char}", "(")
			def capturing = 1
		elif !strcmp("{next_char}", ")")
			def active_capture += 1
			def capturing = 0
		elif !strcmp("{next_char}", "\\")
			popchars _rx, 1
			redef matchables equs strsub("{_rx}", 1, 1)
			def match_mode = MATCH_MODE_MATCH
		elif !strcmp("{next_char}", "[")
			popchars _rx, 1
			if strsub("{_rx}", 1, 1) == "^"
				def match_mode = MATCH_MODE_DONT
			else
				def match_mode = MATCH_MODE_MATCH
			endc

			rept strlen("{_rx}")
				redef next_char equs strsub("{_rx}", 1, 1)
				if !strcmp("{next_char}", "]")
					break
				endc
				popchars _rx, 1
				redef matchables equs strcat("{matchables}", "{next_char}")
			endr
		else
			redef matchables equs "{next_char}"
			def match_mode = MATCH_MODE_MATCH
		endc

		if match_mode
			redef at_least equs "1"
			redef at_most equs "1"
			def matches = 0

			popchars _rx, 1
			redef next_char equs strsub("{_rx}", 1, 1)

			if !strcmp("{next_char}", "*")
				redef at_least equs "0"
				redef at_most equs "$FF"
				popchars _rx, 1
			elif !strcmp("{next_char}", "+")
				redef at_least equs "1"
				redef at_most equs "$FF"
				popchars _rx, 1
			elif !strcmp("{next_char}", "?")
				redef at_least equs "0"
				redef at_most equs "1"
				popchars _rx, 1
			elif !strcmp("{next_char}", "\{");}
				def end_brace = strin("{_rx}", "\}")
				if !end_brace
					fail "Unclosed curly brace in regex: /{_source_rx}/"
				endc
				redef brace equs strsub("{_rx}", 2, end_brace - 2)
				if !strlen("{brace}")
					fail "Curly brace is empty in regex: /{_source_rx}/"
				endc
				def comma = strin("{brace}", ",")
				if !comma ; {n}
					redef at_least equs "{brace}"
					redef at_most equs "{brace}"
				elif comma == 1 ; {,n}
					redef at_least equs "0"
					redef at_most equs strsub("{brace}", comma + 1)
				elif comma == strlen("{brace}") ; {n,}
					redef at_least equs strsub("{brace}", 1, comma - 1)
					redef at_most equs "$FF"
				else
					redef at_least equs strsub("{brace}", 1, comma - 1)
					redef at_most equs strsub("{brace}", comma + 1)
				endc
				popchars _rx, strlen("{brace}") + 2
			endc

			rept at_most
				def passed = 0
				if !strlen("{_s}")
					break
				endc

				redef next_match equs strsub("{_s}", 1, 1)
				
				if match_mode == MATCH_MODE_ANY \
					|| match_mode == MATCH_MODE_MATCH && strin("{matchables}", "{next_match}") \
					|| match_mode == MATCH_MODE_DONT && !strin("{matchables}", "{next_match}")
					_match "{next_match}"
					def passed = 1
					def matches += 1
				endc

				if !passed
					break
				endc

				popchars _s, 1
			endr

			if matches < at_least
				warn "regex /{_source_rx}/ does not match \"{_source_s}\" (at /{_rx}/ : \"{_s}\") (expected one of: {matchables})"
			endc
		endc

		popchars _rx, 1
	endr

	if strlen("{_s}")
		warn "regex /{_source_rx}/ does not match \"{_source_s}\" (exhausted regex at /{_rx}/ : \"{_s}\")"
	endc

	purge _rx, _s, _source_rx, _source_s, captures, next_char, match_mode
endm
