INCLUDE "include/hardware.inc" ; Bread & butter: check.
INCLUDE "include/hUGE.inc" ; Get the note constants.

section "fortissimo", rom0

	rev_Check_hardware_inc 4.2

; Some terminology notes:
; - An "order" is a table of pointers to "patterns".
; - A "pattern" is a series of up to 64 "rows".
; - A "table" is a subpattern
;
; "TODO: loose" means that this `hli` could be used as an optimisation point

; PREVIEW_MODE is defined when assembling for hUGETracker.
; hUGETracker contains a Game Boy emulator (the "G" in "UGE"), and it relies on some cooperation
; from the driver to signal key updates.
; This goes both ways, though: don't try to run PREVIEW_MODE code outside of hUGETracker!

MACRO No ; For "empty" entries in the JR tables.
	ret
	ds 1
ENDM

IF DEF(PREVIEW_MODE)
	DEF TAKE_REG_SNAPSHOT equs "db $f4" ; Signal tracker to take a snapshot of audio regs (for VGM export).
	DEF REFRESH_ORDER equs "db $fc" ; Signal tracker to re-read the order index.
	DEF REFRESH_ROW equs "db $fd" ; Signal tracker to re-read the row index.

	WARN "CAUTION: Using fortISSimO inside hUGETracker itself is experimental.\n\tPlease report any issues to\n\t>>> https://github.com/ISSOtm/fortISSimO/issues <<<"

	SECTION "Sound Driver", ROM0
ELSE
	DEF TAKE_REG_SNAPSHOT equs ""
	DEF REFRESH_ORDER equs ""
	DEF REFRESH_ROW equs ""
ENDC

; Note: SDCC's linker is crippled by the lack of alignment support.
; So we can't assume any song data nor RAM variables are aligned, as useful as that would be.
;
; SDCC calling conventions: https://sdcc.sourceforge.net/doc/sdccman.pdf#subsubsection.4.3.5.1

_hUGE_StartSong:: ; C interface.
; @param de: Pointer to the "song descriptor" to load.
StartSong::
	rst SwapBank
	ld b, a
	ldh a, [hSongBank]
	cp a, b
	ld a, b
	jr nz, .force
	ld hl, 17 ; offset of routines in hUGE struct
	add hl, de
	ld a, [wRoutines]
	cp a, [hl]
	ld a, b
	jr nz, .force
	ld a, [wRoutines + 1]
	inc hl
	cp a, [hl]
	ret z
	; Set song bank
	ld a, b
.force::
	ldh [hSongBank], a
	rst SwapBank

	ld a, $77
	ldh [rNR50], a

	ld hl, hUGE_LoadedWaveID
	ld a, hUGE_NO_WAVE
	ld [hli], a

	xor a ; Begin by not touching any channels until a note first plays on them.
	ldh [hAllowedChannels], a

	; Set arpeggio state to something.
	assert hUGE_LoadedWaveID + 1 == wArpState
	inc a ; ld a, 1
	ld [hli], a

	assert wArpState + 1 == wRowTimer
	; a = 1
	ld [hli], a ; The next tick will switch to a new row.

	assert wRowTimer + 1 == wTicksPerRow
	ld a, [de]
	ld [hli], a
	inc de

	assert wTicksPerRow + 1 == wLastPatternIdx
	; TODO: pointing to a single byte is a bit silly
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	inc de
	ld a, [bc]
	; TODO: have tracker do this
	sub 2
	ld [hli], a

	; TODO: change the order around to make loading this more efficient
	ld a, [de]
	ld [wCH1.order], a
	inc de
	ld a, [de]
	ld [wCH1.order + 1], a
	inc de
	ld a, [de]
	ld [wCH2.order], a
	inc de
	ld a, [de]
	ld [wCH2.order + 1], a
	inc de
	ld a, [de]
	ld [wCH3.order], a
	inc de
	ld a, [de]
	ld [wCH3.order + 1], a
	inc de
	ld a, [de]
	ld [wCH4.order], a
	inc de
	ld a, [de]
	ld [wCH4.order + 1], a
	; No `inc de` because the loop pre-increments

	assert wLastPatternIdx + 1 == wDutyInstrs
	assert wDutyInstrs + 2 == wWaveInstrs
	assert wWaveInstrs + 2 == wNoiseInstrs
	assert wNoiseInstrs + 2 == wRoutines
	assert wRoutines + 2 == wWaves
	ld c, 2 + 2 + 2 + 2 + 2
.copyPointers
	inc de
	ld a, [de]
	ld [hli], a
	dec c
	jr nz, .copyPointers

IF DEF(PREVIEW_MODE)
	assert wWaves + 2 == loop_order
	inc hl ; TODO: does `loopPatterns` need to be init'd?
	assert loop_order + 1 == wOrderIdx
ELSE
	assert wWaves + 2 == wOrderIdx
ENDC

IF DEF(PREVIEW_MODE)
	inc hl ; The tracker writes the starting order instead.
	assert wOrderIdx == current_order
ELSE
	; Orders begin at 0.
	xor a
	ld [hli], a
ENDC
	assert wOrderIdx + 1 == wPatternIdx
	inc hl ; No need to init that, it will be set from `wForceRow`.
	assert wPatternIdx + 1 == wForceRow
	assert PATTERN_LENGTH == 1 << 6, "Pattern length must be a power of 2"
IF DEF(PREVIEW_MODE)
	ld a, [row]
	or -PATTERN_LENGTH
ELSE
	ld a, -PATTERN_LENGTH
ENDC
	ld [hli], a ; Begin by forcing row 0.

	; Time to init the channels!
	assert wForceRow + 1 == wCH1
	ld c, 4
.initChannel
	assert wCH1 == wCH1.order ; The order pointer was already written above
	inc hl ; Skip order pointer.
	inc hl
	; All of these don't need to be init'd.
	assert wCH1.order + 2 == wCH1.fxParams
	assert wCH1.fxParams + 1 == wCH1.instrAndFX
	assert wCH1.instrAndFX + 1 == wCH1.note
	assert wCH1.note + 1 == wCH1.subPattern
	inc hl ; Skip FX params.
	inc hl ; Skip instrument/FX byte.
	inc hl ; Skip note ID.

	; To ensure that nothing bad happens if a note isn't played on the first row, set the subpattern
	; pointer to NULL.
	xor a
	ld [hli], a
	ld [hli], a
	assert wCH1.subPattern + 2 == wCH1.subPatternRow
	; Although strictly speaking, init'ing the subpattern row is unnecessary, it's still read before
	; the NULL check is performed; doing this silences any spurious "uninit'd RAM read" exceptions.
	ld [hli], a
	assert wCH1.subPatternRow + 1 == wCH1.ctrlMask
	; Same as above.
	ld [hli], a
	; Then, we have the 4 channel-dependent bytes
	; (period + (porta target / vib counter) / LFSR width + polynom + padding); they don't need init.
	ld a, l
	add a, 4
	ld l, a
	adc a, h
	sub l
	ld h, a
	assert wCH1.ctrlMask + 5 == wCH2

	dec c ; Are we done?
	jr nz, .initChannel
	ret


_hUGE_TickSound:: ; C interface.
TickMusic::
	; Disable all muted channels.
	ld hl, hMutedChannels
	ld a, [hli]
	assert hMutedChannels + 1 == hAllowedChannels
	cpl
	and [hl]
	ld [hl], a

	ld hl, wArpState
	dec [hl]
	jr nz, :+
	ld [hl], 3
:
	inc hl
	assert wArpState + 1 == wRowTimer

	; Check if we should switch to a new row, or just update "continuous" effects.
	dec [hl]
	jp nz, ContinueFx


	;; This is the first tick; switch to the next row, and reload all pointers.

	; Reload delay.
	ld a, [wTicksPerRow]
	ld [hli], a ; TODO: loose

	; Check if there is a row or pattern break, and act accordingly:
	; Pattern break + row break at the same time must switch to row R on pattern P!
	; But row break on last row must not change the pattern.

	; Switch to next row.
	ld hl, wForceRow
	ld a, [hld]
	assert wForceRow - 1 == wPatternIdx
	and a
	jr nz, .forceRow
	inc [hl]
	jr nz, .samePattern
	; Reload index.
	assert PATTERN_LENGTH == 1 << 6, "Pattern length must be a power of 2"
	ld [hl], -PATTERN_LENGTH ; pow2 is required to be able to mask off these two bits.
IF DEF(PREVIEW_MODE)
	; If looping is enabled, don't switch patterns.
	ld a, [loop_order]
	and a
	jr nz, .samePattern
ENDC
	; Switch to next patterns.
	dec hl
	assert wPatternIdx - 1 == wOrderIdx
	ld a, [wLastPatternIdx]
	sub [hl]
	jr z, .wrapOrders ; Reached end of orders, start again from the beginning.
	ld a, [hl]
	assert ORDER_WIDTH == 2
	inc a
	inc a
.wrapOrders
	ld [hli], a
	REFRESH_ORDER
	assert wOrderIdx + 1 == wPatternIdx
	db $FE ; cp <ld [hl], a>
.forceRow
	ld [hl], a
.samePattern
	; Compute the offset into the pattern.
	ld a, [hli]
	assert PATTERN_LENGTH == 1 << 6, "Pattern length must be a power of 2"
	and PATTERN_LENGTH - 1
	ld b, a
	inc a ; Plus two 'cause we read rows backwards. TODO: have the tracker do this, but it requires reworking the subpattern code as well!
	add a, a
	add a, b
	ld b, a
	; Reset the "force row" byte.
	assert wPatternIdx + 1 == wForceRow
	xor a
	ld [hli], a


	;; Play new rows.

	; Note that all of these functions leave b untouched all the way until CH4's `ReadRow`!

	assert wForceRow + 1 == wCH1.order
	; ld hl, wCH1.order
	call ReadRow
	ld hl, wCH1.instrAndFX
	ld e, hUGE_CH1_MASK
	ld c, LOW(rNR10)
	call nz, PlayDutyNote

	ld hl, wCH2.order
	call ReadRow
	ld hl, wCH2.instrAndFX
	ld e, hUGE_CH2_MASK
	ld c, LOW(rNR21 - 1) ; NR20 doesn't exist.
	call nz, PlayDutyNote

	ld hl, wCH3.order
	call ReadRow
	call nz, PlayWaveNote

	ld hl, wCH4.order
	call ReadRow
	call nz, PlayNoiseNote


	;; Process tick 0 FX and subpatterns.

	ld de, wCH1.fxParams
	ld c, hUGE_CH1_MASK
	call RunTick0Fx
	ld hl, wCH1.ctrlMask
	ld c, hUGE_CH1_MASK
	call TickSubpattern

	ld de, wCH2.fxParams
	ld c, hUGE_CH2_MASK
	call RunTick0Fx
	ld hl, wCH2.ctrlMask
	ld c, hUGE_CH2_MASK
	call TickSubpattern

	ld de, wCH3.fxParams
	ld c, hUGE_CH3_MASK
	call RunTick0Fx
	ld hl, wCH3.ctrlMask
	ld c, hUGE_CH3_MASK
	call TickSubpattern

	ld de, wCH4.fxParams
	ld c, hUGE_CH4_MASK
	call RunTick0Fx
	ld hl, wCH4.ctrlMask
	ld c, hUGE_CH4_MASK
	assert @ == TickSubpattern ; fallthrough


; @param hl: Pointer to the channel's "control mask".
; @param c:  The channel's mask (the CHx_MASK constant).
; @destroy a bc de hl (potentially)
TickSubpattern:
	; TODO: change the way it's generated to eliminate `.subPatternRow`.
	ld a, [hld] ; Read the "control mask".
	res 7, a ; We don't want to retrigger the channel.
	ld b, a
	assert wCH1.ctrlMask - 1 == wCH1.subPatternRow
	ld a, [hl]
	ld e, a
	add a, 3 ; Switch to next row.
	ld [hld], a
	assert wCH1.subPatternRow - 2 == wCH1.subPattern ; 16-bit variable.
	; Add the row offset to the subpattern base pointer.
	ld a, [hld]
	ld d, a
	or [hl]
	ret z ; Return if subpattern pointer is NULL (no subpattern).
	ld a, [hld]
	assert wCH1.subPattern - 1 == wCH1.note
	push hl ; Save pointer to current note.
	add a, e
	ld e, a ; Can't write directly to l, as we need to deref hl just below.
	adc a, d
	sub e
	ld d, [hl] ; Cache the current base note. (Must be done here because d is used above.)
	ld h, a
	ld l, e
	; Check if the channel is muted; if so, don't write to NRxy.
	ldh a, [hAllowedChannels]
	and c
	jr z, .noNoteOffset
	; Apply the note offset, if any.
	ld a, [hl]
	res 7, a ; That's the fifth "jump" bit, see further below.
	assert LAST_NOTE <= 128 ; Otherwise the above clears an important bit.
	cp LAST_NOTE
	jr nc, .noNoteOffset
	; Treat the "note" byte as an offset from the base note.
	sub LAST_NOTE / 2 ; Go from "unsigned range" to "signed range".
	add a, d ; Add base note (cached above).
	bit 3, c
	assert hUGE_CH4_MASK == 1 << 3
	jr nz, .ch4
	; Compute the note's period.
	add a, a
	add a, LOW(PeriodTable)
	ld e, a
	adc a, HIGH(PeriodTable)
	sub e
	ld d, a
	; Compute the pointer to NRx3, bit twiddling courtesy of @calc84maniac.
	push bc ; Preserve the channel mask.
	; a = 1 (CH1), 2 (CH2), or 4 (CH3).
	xor $11  ; 10, 13, 15
	add a, c ; 11, 15, 19
	cp LOW(rNR23)
	adc a, c ; 13, 18, 1D
	ld c, a
	; Write the period, together with the control mask.
	ld a, [de]
	ldh [c], a
	inc c
	ld a, [de]
	or b ; Add the "control" bits.
	ldh [c], a
	pop bc ; Retrieve the channel mask.
.noNoteOffset

	pop de ; Retrieve pointer to note byte.
	; The "instrument" bits are repurposed as a "jump target" instead (to avoid taking up the FX slot).
	; However, a fifth bit is required to address all 32 rows, and that's the note's 7th bit.
	ld a, [hli]
	rlca ; Shift bit 7 into bit 0
	ld b, [hl] ; Read the row's FX byte.
	inc hl
	xor b
	and 1
	xor b
	and $F1 ; Discard the remaining 3 bits.
	jr z, .noJump
	swap a ; The instrument bits (low 4) are in bits 4–7, and the fifth bit is in bit 0, so swap the nibbles.
	dec a ; Rows are 0-based.
	push hl ; TODO: belch.
	; Rows are 3 bytes each.
	ld l, a
	add a, a
	add a, l
	; Jump to the selected row.
	ld hl, wCH1.subPatternRow - wCH1.note
	add hl, de
	ld [hl], a
	pop hl
.noJump

	; Play the row's FX.
	ld a, b ; Read the FX/instr byte again.
	and $0F ; Keep the FX bits only.
	ld b, [hl] ; Read the row's FX params.
	add a, a
	add a, LOW(.fxPointers)
	ld l, a
	adc a, HIGH(.fxPointers)
	sub l
	ld h, a
	; Deref the pointer, and jump to it.
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl

.ch4
	call GetNoisePolynom
	ld d, a
	ld a, [wCH4.lfsrWidth]
	or d
	ldh [rNR43], a
	ld a, b
	ldh [rNR44], a
	jr .noNoteOffset

.fxPointers ; TODO: the "known `ret`s" should never be followed, runtime assert that
	dw FxArpeggio
	dw FxPortaUp
	dw FxPortaDown
	dw KnownRet ; No tone porta
	dw SubpatternFxVibrato
	dw FxSetMasterVolume
	dw FxCallRoutine
	dw KnownRet ; No note delay
	dw FxSetPanning
	dw FxChangeTimbre
	dw FxVolumeSlide
	dw KnownRet ; No pos jump
	dw FxSetVolume
	dw KnownRet ; No pattern break
	dw KnownRet ; No note cut
	dw KnownRet ; This would reset the row timer, and you DEFINITELY don't want that.


; @param hl: Pointer to the channel's order pointer.
; @param b:  Offset into the current patterns.
; @return hl:   Pointer to the channel's period (1, 2, 3) / polynom (4).
; @return c:    New row's instrument/FX byte.
; @return d:    New row's note index.
; @return zero: If set, the note should not be played.
; @destroy e a
ReadRow:
	; Compute the pointer to the current pattern.
	ld a, [wOrderIdx] ; TODO: cache this in a reg across calls?
	add a, [hl]
	ld e, a
	inc hl
	ld a, [hli]
	adc a, 0
	ld d, a
	assert wCH1.order + 2 == wCH1.fxParams
	; Compute the pointer to the current row.
	ld a, [de]
	add a, b
	ld c, a
	inc de
	ld a, [de]
	adc a, 0
	ld d, a
	ld e, c
	; Read the row into the channel's data.
	; The rows are read backwards so that we finish with the note ID in a (more useful than FX params).
	ld a, [de]
	ld [hli], a
	dec de
	assert wCH1.fxParams + 1 == wCH1.instrAndFX
	ld a, [de]
	ld [hli], a
	ld c, a
	dec de
	assert wCH1.instrAndFX + 1 == wCH1.note
	ld a, [de]
	ld d, a
	; If the row is a rest, don't play it.
	cp ___
	ret z
	ld [hli], a ; Only write the note back if it's not a rest.
	; TODO: runtime assert that a < LAST_NOTE
	; If the FX is a tone porta or a note delay, don't play the note yet.
	ld a, c
	assert FX_NOTE_DELAY == FX_TONE_PORTA | $04, "Difference between note delay (${x:FX_NOTE_DELAY}) and tone porta (${x:FX_TONE_PORTA}) must be a single bit"
	and $0F & ~$04
	cp FX_TONE_PORTA
	ret

; Starts playing a new note on the channel, writing back its period to the channel's struct.
; @param a:  ID of the note to play.
; @param c:  LOW(rNRx3)
; @param hl: Pointer to the channel's `.period`.
; @destroy c de hl a
def PlayNewNote equs "PlayDutyNote.playNewNote"

; @param c:  LOW(rNRx0)
; @param e:  The channel's bit mask in the muted/allowed channel bytes.
; @param d:  The channel's note ID.
; @param hl: Pointer to the channel's fx/instrument byte.
; @destroy c de hl a
PlayDutyNote:
	; If the channel is inhibited, don't perform any writes.
	ld a, [hMutedChannels]
	and e
	ret nz

	; Let's roll!
	push de ; Save the note index for later.
	; First, apply the instrument.
	ld a, [hli]
	inc hl
	assert wCH1.instrAndFX + 2 == wCH1.subPattern
	and $F0 ; Keep the instrument bits.
	jr z, .noInstr
	; Compute the instrument pointer.
	sub $10 ; Instrument IDs are 1-based.
	; Pulse instruments are 6 bytes each, and we currently have the index times 16; scale it down a bit.
	; TODO: assert that this is the case!
	rra ; *8 now.
	rra ; *4 now.
	ld d, a
	rra ; *2 now.
	add a, d ; *2 + *4 = *6, perfect!
	ld d, a
	; If the channel is not inhibited, allow it to be used by FX as well.
	; We can't do this earlier because of register pressure.
	ldh a, [hAllowedChannels]
	or e
	ldh [hAllowedChannels], a
	; Resume computing the instrument pointer.
	ld a, [wDutyInstrs]
	add a, d
	ld e, a
	ld a, [wDutyInstrs + 1]
	adc a, 0
	ld d, a
	; Perform the instrument's writes.
	ld a, [de] ; Sweep.
	ldh [c], a
	inc c
	inc de
	ld a, [de] ; Duty & length.
	ldh [c], a
	inc c
	inc de
	ld a, [de] ; Volume & envelope.
	ldh [c], a
	inc de
	ld a, [de] ; Subpattern pointer.
	ld [hli], a
	inc de
	ld a, [de]
	ld [hli], a
	assert wCH1.subPattern + 2 == wCH1.subPatternRow
	inc de
	xor a ; Subpattern row counter.
	ld [hli], a
	assert wCH1.subPatternRow + 1 == wCH1.ctrlMask
	ld a, [de] ; NRx4 mask.
.writeCtrlMask
	ld [hli], a
	assert wCH1.ctrlMask + 1 == wCH1.period
	inc c ; Skip NRx2.

	; Next, apply the note.
	pop af ; Retrieve the note ID (from d to a).
	;; NOTE: aliased as `PlayNewNote`; if modifying this, please check the documentation accordingly.
	; (An alias is used to keep `.noInstr` below as a local label.)
.playNewNote
	; Compute a pointer to the note's period.
	add a, a
	add a, LOW(PeriodTable)
	ld e, a
	adc a, HIGH(PeriodTable)
	sub e
	ld d, a
	; Write it.
	ld a, [de] ; LOW(Period).
	ld [hli], a
	ldh [c], a
	inc c ; Skip NRx3.
	inc de
	ld a, [de] ; HIGH(Period).
	ld [hld], a
	dec hl
	assert wCH1.period - 1 == wCH1.ctrlMask
	or [hl] ; OR the "control bits" with the period's high bits.
	ldh [c], a
	ret

.noInstr
	inc c ; Skip NRx0.
	inc c ; Skip NRx1.
	inc hl ; Skip subpattern pointer.
	inc hl
	inc hl ; Skip subpattern row counter.
	; Remove trigger bit from ctrl mask.
	ld a, [hl]
	res 7, a
	jr .writeCtrlMask


; @param d: The channel's note ID.
; @destroy c de hl a
PlayWaveNote:
	; If the channel is inhibited, don't perform any writes.
	ld a, [hMutedChannels]
	and hUGE_CH3_MASK
	ret nz

	; First, apply the instrument.
	ld a, [wCH3.instrAndFX]
	and $F0 ; Keep the instrument bits.
	ld hl, wCH3.ctrlMask
	jr z, .noWaveInstr
	; Compute the instrument pointer.
	sub $10 ; Instrument IDs are 1-based.
	; Wave instruments are 6 bytes each, and we currently have the index times 16; scale it down a bit.
	; TODO: assert that this is the case!
	rra ; *8 now.
	rra ; *4 now.
	ld e, a
	rra ; *2 now.
	add a, e ; *2 + *4 = *6, perfect!
	ld e, a
	ld hl, wWaveInstrs
	ld a, [hli]
	add a, e
	ld e, a
	adc a, [hl]
	sub e
	ld h, a
	ld l, e
	; If the channel is not inhibited, allow it to be used by FX as well.
	ldh a, [hAllowedChannels]
	or hUGE_CH3_MASK
	ldh [hAllowedChannels], a
	; Perform the instrument's writes.
	ld a, [hli] ; Length.
	ldh [rNR31], a
	ld a, [hli] ; Volume & envelope.
	ldh [rNR32], a
	ld a, [hli] ; Read wave ID for later. TODO: move it last!
	ld e, a
	ld a, [hli] ; Subpattern pointer.
	ld [wCH3.subPattern], a
	ld a, [hli]
	ld [wCH3.subPattern + 1], a
	xor a ; Subpattern row counter.
	ld [wCH3.subPatternRow], a
	ld a, [hl] ; NRx4 mask.
	ld [wCH3.ctrlMask], a
	; Check if a new wave must be loaded.
	ld a, [hUGE_LoadedWaveID]
	cp e
	call nz, LoadWave
	db $21 ; ld hl, <res 7, [hl]> ; This is OK because HL does not get used below.
.noWaveInstr
	res 7, [hl] ; If no instrument, remove trigger bit from control mask.

	; Next, apply the note.
	ld a, d ; Retrieve the note ID.
	; Compute a pointer to the note's period.
	add a, a
	add a, LOW(PeriodTable)
	ld e, a
	adc a, HIGH(PeriodTable)
	sub e
	ld d, a
	; Careful—triggering CH3 while it's reading wave RAM can corrupt it.
	; We first kill the channel, and re-enable it, which has it enabled but not playing.
	ld hl, rNR30
	ld [hl], l ; This has bit 7 reset, killing the channel.
	ld [hl], h ; This has bit 7 set, re-enabling the channel.
	; Write it.
	ld hl, wCH3.period
	ld a, [de] ; LOW(Period).
	ld [hli], a
	inc de
	ldh [rNR33], a
	ld a, [de] ; HIGH(Period).
	ld [hld], a
	dec hl
	assert wCH3.period - 1 == wCH3.ctrlMask
	or [hl] ; OR the "control bits" with the period's high bits.
	ldh [rNR34], a
	ret

; @param d: The channel's note ID.
; @destroy c de hl a
PlayNoiseNote:
	; If the channel is inhibited, don't perform any writes.
	ld a, [hMutedChannels]
	and hUGE_CH4_MASK
	ret nz

	; First, apply the instrument.
	ld a, [wCH4.instrAndFX]
	and $F0 ; Keep the instrument bits.
	ld hl, wCH4.ctrlMask
	jr z, .noNoiseInstr
	; Compute the instrument pointer.
	sub $10 ; Instrument IDs are 1-based.
	; Noise instruments are 6 bytes each, and we currently have the index times 16; scale it down a bit.
	; TODO: assert that this is the case!
	; TODO: 2 of those bytes are unused! This would also simplify the code below (3b/3c).
	rra ; *8 now.
	rra ; *4 now.
	ld e, a
	rra ; *2 now.
	add a, e ; *2 + *4 = *6, perfect!
	ld e, a
	ld hl, wNoiseInstrs
	ld a, [hli]
	add a, e
	ld e, a
	adc a, [hl]
	sub e
	ld h, a
	ld l, e
	; If the channel is not inhibited, allow it to be used by FX as well.
	ldh a, [hAllowedChannels]
	or hUGE_CH4_MASK
	ldh [hAllowedChannels], a
	; Perform the instrument's writes.
	ld a, [hli] ; Volume & envelope.
	ldh [rNR42], a
	ld a, [hli] ; Subpattern pointer.
	ld [wCH4.subPattern], a
	ld a, [hli]
	ld [wCH4.subPattern + 1], a
	xor a ; Subpattern row counter.
	ld [wCH4.subPatternRow], a
	ld a, [hl] ; LFSR width & length bit & length.
	and $3F ; Only keep the length bits.
	ldh [rNR41], a
	; What follows is a somewhat complicated dance that saves 1 cycle over loading from [hl] then
	; ANDing the desired bit twice. Totally worth it, if only because it looks cool af.
	xor [hl] ; Only keep the other two bits (bits 7 and 6).
	rlca ; LFSR width is in bit 0 and carry now.
	srl a ; LFSR width is in carry, and a contains only the length enable in bit 6.
	set 7, a ; Set trigger bit.
	ld [wCH4.ctrlMask], a
	sbc a, a ; All bits are LFSR width now.
	and AUD4POLY_7STEP
	ld [wCH4.lfsrWidth], a
	db $DC ; call c, <res 7, [hl]>
.noNoiseInstr
	res 7, [hl] ; If no instrument, remove trigger bit from control mask.

	; Next, apply the note.
	ld a, d
	call GetNoisePolynom
	ld hl, wCH4.polynom
	ld [hld], a
	assert wCH4.polynom - 1 == wCH4.lfsrWidth
	or [hl] ; The polynom's bit 3 is always reset. (TODO: runtime assert this?)
	ldh [rNR43], a
	dec hl
	assert wCH4.lfsrWidth - 1 == wCH4.ctrlMask
	ld a, [hl]
	ldh [rNR44], a
	ret


; @param e: The ID of the wave to load.
; @destroy hl a
LoadWave:
	; Compute a pointer to the wave.
	ld a, e
.waveInA
	ld [hUGE_LoadedWaveID], a
	swap a ; TODO: it would be more useful if this was already multiplied by 16
	ld hl, wWaves
	add a, [hl]
	inc hl
	ld h, [hl]
	ld l, a
	adc a, h
	sub l
	ld h, a
	; Load the wave.
	xor a
	ldh [rNR30], a ; Disable CH3's DAC while loading wave RAM.
	; TODO: should we remove CH3 from NR51 to improve GBA quality?
	FOR OFS, 0, 16
		ld a, [hli]
		ldh [_AUD3WAVERAM + OFS], a
	ENDR
	ld a, AUD3ENA_ON
	ldh [rNR30], a ; Re-enable CH3's DAC.
	ret


; @param de: Pointer to the channel's FX params.
; @param c:  The channel's ID (0 for CH1, 1 for CH2, etc.)
; @destroy a bc de hl (potentially)
RunTick0Fx:
	ld a, [de]
	ld b, a
	inc de
	assert wCH1.fxParams + 1 == wCH1.instrAndFX
	ld a, [de]
	and $0F ; Strip instrument bits.
	add a, a ; Each entry in the table is 2 bytes.
	add a, LOW(Tick0Fx)
	ld l, a
	adc a, HIGH(Tick0Fx)
	sub l
	ld h, a
	assert wCH1.instrAndFX + 1 == wCH1.note
	inc de
	; WARNING: `NoteCutTick0Trampoline` assumes that it's jumped to with `a == h`.
	jp hl


; All of the FX functions follow the same calling convention:
; @param de: Pointer to the channel's note byte.
; @param c:  The channel's mask (the CHx_MASK constant).
; @param b:  The FX's parameters.
; @destroy a bc de hl (potentially)

; First, FX code that only runs on tick 0.

FxChangeTimbre2: ; These are jumped to by `FxChangeTimbre` below.
.ch1
	ld a, b
	ldh [rNR11], a
	ret
.ch2
	ld a, b
	ldh [rNR21], a
	ret
.ch3
	ld a, b
	call LoadWave.waveInA
	; We now need to retrigger the channel, since we needed to stop it to reload the wave.
	ld hl, wCH3.period + 1
	ld a, [hld] ; It's annoying that these bits are there, but that's how it is.
	dec hl
	assert wCH3.period + 1 - 2 == wCH3.ctrlMask
	or [hl]
	or $80
	ldh [rNR34], a
	ret


FxTonePortaSetup:
	; TODO: runtime assert that CH4 is not the target.
	; Setup portion: get the target period.
	ld a, [de]
	; Compute the target period from the note ID.
	add a, a
	add a, LOW(PeriodTable)
	ld l, a
	adc a, HIGH(PeriodTable)
	sub l
	ld h, a
	ld a, [hli]
	ld b, [hl]
	; Write it.
	ld hl, wCH1.portaTarget - wCH1.note
	add hl, de
	ld [hli], a
	ld [hl], b
KnownRet:
	ret


; Must not alter its params so that it can be used in `SubpatternFxVibrato` (or that one must `push`).
FxResetVibCounter:
	ld hl, wCH1.vibratoCounter - wCH1.note
	add hl, de
	ld [hl], b ; Write the counter and the offset (will be applied when the counter underflows).
	ret


; This one is slightly out of order so it can `jr FxChangeTimbre2.chX`.

; For CH1 and CH2, this is written as-is to NRx1;
; for CH3, this is the ID of the wave to load;
; for CH4, this is the new LFSR width bit to write to NR43.
FxChangeTimbre:
	; Don't touch the channel if not allowed to.
	ldh a, [hAllowedChannels]
	and c
	ret z
	; Dispatch.
	rra
	jr c, FxChangeTimbre2.ch1
	rra
	jr c, FxChangeTimbre2.ch2
	rra
	jr c, FxChangeTimbre2.ch3
.ch4
	; Keep the polynom bits, but replace the LFSR width bit.
	ldh a, [rNR43]
	and ~AUD4POLY_7STEP ; Reset the LFSR width bit.
	; TODO: runtime assert that this is $00 or AUD4POLY_STEP
	or b
	ldh [rNR43], a
	ret


FxSetMasterVolume:
	ld a, b ; Read the FX's params.
	ldh [rNR50], a
	ret


FxSetPanning:
	ld a, b ; Read the FX's params.
	ldh [rNR51], a
	ret


; FxChangeTimbre is a bit above.


FxPatternBreak:
	ld hl, wOrderIdx
	ld a, [hl]
	add a, 2
	ld [hli], a
	ASSERT wOrderIdx + 2 == wForceRow
	inc hl
	ld [hl], b
	ret


FxVolumeSlide:
	; Don't touch the channel if not allowed to.
	ldh a, [hAllowedChannels]
	and c
	ret z
	; TODO: runtime assert that CH3 is not the target
	; Compute a pointer to the volume register.
	; Doing it this way, courtesy of @nitro2k01, is smaller and faster.
	; a = 1 for CH1, 2 for CH2, 8 for CH4.
	xor 2 ; 3, 0, A
	inc a ; 4, 1, B
	xor 4 ; 0, 5, F
	add a, LOW(rNR12)
	ld c, a
	; Prepare the FX params.
	ld a, b
	; $F0 appears quite a few times, cache it in a register.
	ld b, $F0
	and b ; "Up" part.
	ld h, a ; "Up" stored in the *upper* byte.
	ld a, b
	swap a ; "Down" part.
	and b
	ld l, a ; "Down" part stored in the *lower* byte.
	; Make volume adjustments.
	ldh a, [c]
	and b ; Keep only the current volume bits.
	sub l
	jr nc, :+
	xor a ; Clamp.
:
	add a, h
	jr nc, :+
	ld a, b ; Clamp.
:
	; TODO: this only needs to apply when a = 0, which is equivalent to clamping... or Z on the `sub`.
	or AUDENV_UP ; Ensure that writing $00 does *not* kill the channel (reduces pops).
.applyVolume
	ldh [c], a ; Yes, this kills the envelope, but we must retrigger, which sounds bad with envelope anyway.
	; Speaking of, retrigger the channel.
	inc c ; LOW(rNRx3)
	inc c ; LOW(rNRx4)
	; CH4 doesn't have a period, so this'll read garbage;
	; however, this is OK, because the lower 3 bits are ignored by the hardware register anyway.
	; We only need to mask off the upper bits which might be set.
	ld hl, wCH1.period + 1 - wCH1.note
	add hl, de ; Go to the period's high byte
	ldh a, [c]
	xor [hl]
	and AUDHIGH_LENGTH_ON ; Preserve that bit.
	xor [hl]
	or AUDHIGH_RESTART ; Retrigger the channel.
	ldh [c], a
	ret


; The jump table is in the middle of the functions so that backwards `jr`s can be used as well as forwards.
Tick0Fx:
	jr FxArpeggio
	No porta up
	No porta down
	jr FxTonePortaSetup
	jr FxResetVibCounter
	jr FxSetMasterVolume
	jr FxCallRoutine
	No note delay
	jr FxSetPanning
	jr FxChangeTimbre
	jr FxVolumeSlide
	jr FxPosJump
	jr FxSetVolume
	jr FxPatternBreak
	jr NoteCutTick0Trampoline
FxSetSpeed:
	ld a, b
	ld [wTicksPerRow], a
	; We want the new tempo to take effect immediately; so, we must reload the timer as well.
	; This is easy to do, since we are on tick 0.
	ld [wRowTimer], a
	ret


FxPosJump:
	; Writing to `orderIdx` directly is safe, because it is only read by `ReadRow`,
	; all calls to which happen before any FX processing. (The rows are cached in RAM.)
	ld hl, wOrderIdx
	ld a, b
	ld [hli], a
	; Set the necessary bits to make this non-zero;
	; if a row is already being forced, this keeps it, but will select row 0 otherwise.
	inc hl
	assert wOrderIdx + 2 == wForceRow
	assert LOW(-PATTERN_LENGTH) == $C0 ; Set the corresponding bits.
	set 7, [hl]
	set 6, [hl]
	ret


FxSetVolume:
	; Don't touch the channel if not allowed to.
	ldh a, [hAllowedChannels]
	and c
	ret z
	cp hUGE_CH3_MASK
	jr z, .ch3
	; Compute a pointer to the volume register.
	; Doing it this way, courtesy of @nitro2k01, is smaller and faster.
	; a = 1 for CH1, 2 for CH2, 8 for CH4.
	xor 2 ; 3, 0, A
	inc a ; 4, 1, B
	xor 4 ; 0, 5, F
	add a, LOW(rNR12)
	ld c, a
	; FIXME: hUGEDriver preserves envelope bits for pulse channels, but not for CH4;
	;        according to Coffee Bat, the envelope bits should be preserved if B's lower nibble
	;        (post-`swap`) is non-zero. Decide on a behaviour, and implement it.
	ld a, b
	and $0F
	jr nz, .overwriteEnvelope
	ldh a, [c]
	and $0F ; Preserve the envelope bits.
	; TODO: this might end up killing the channel.
.overwriteEnvelope
	or b
	jr FxVolumeSlide.applyVolume ; Apply volume and retrigger channel.

.ch3
	; "Quantize" the more finely grained volume control down to one of 4 values.
	; FIXME: this is not very linear
	ld a, b
	cp 10 << 4
	jr nc, .one
	cp 5 << 4
	jr nc, .two
	and $F0 ; Discard the envelope bits (which are irrelevant to CH3).
	jr z, .done ; Zero maps to zero.
.three:
	ld a, AUD3LEVEL_25
	jr .done
.two:
	ld a, AUD3LEVEL_50
	db $DC ; call c, <ld a, AUD3LEVEL_100>
.one:
	ld a, AUD3LEVEL_100
.done:
	ldh [rAUD3LEVEL], a
	; CH3 doesn't need a retrigger after writing to NR32.
	ret


; Finally, the effects that run the same regardless of first tick or not

FxArpeggio:
	; `000` is an empty row, even on CH4. Make it do nothing, as it would glitch out on CH4.
	ld a, b
	and a
	ret z
	; Don't touch the channel if not allowed to.
	ldh a, [hAllowedChannels]
	and c
	ret z
	; TODO: runtime assert that CH4 is not the target
	; Compute the pointer to NRx3, bit twiddling courtesy of @calc84maniac.
	; a = 1 (CH1), 2 (CH2), or 4 (CH3).
	xor $11  ; 10, 13, 15
	add a, c ; 11, 15, 19
	cp LOW(rNR23)
	adc a, c ; 13, 18, 1D
	ld c, a
	; Pick an offset from the base note.
	ld a, [wArpState]
	dec a
	jr z, .noOffset ; arpState == 1
	dec a
	ld a, b ; Read FX params.
	jr z, .useY ; arpState == 2
	swap a
.useY
	and $0F ; Only keep the selected offset.
.noOffset
	; Add the offset (b & $0F) to the base note.
	ld l, a
	ld a, [de]
	add a, l
	; Play this note.
	ld hl, wCH1.period - wCH1.note
	add hl, de
	jp PlayNewNote


FxCallRoutine:
	; Compute pointer to the routine.
	ld a, b
	add a, LOW(wRoutines)
	ld l, a
	adc a, HIGH(wRoutines)
	sub l
	ld h, a
	; Deref the pointer, and call it.
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl


; This is a hack to be able to reach `FxNoteCut` from the "tick 0" table.
NoteCutTick0Trampoline:
	; The function we're jumping to computes the current tick count (counting upwards; our row timer
	; instead ticks downwards for performance's sake), and then cuts the note if on the specified tick.
	; Since we are here, we are on tick 0, so that's what we need `a` to be equal to.
	; For performance's but moreso size's sake (we're very space-bound here), we can't afford a
	; `xor a`.
	; Instead, we rely on this function being called with `a == h` (from `RunTick0Fx`), and jumps to
	; a `sub h`, which is then used as the tick count.
	; This is madness, yes, but this is also efficient, and helps compensate the trampoline's
	; performance penalty.
	jp FxNoteCut.computeTick


; And these FX are "continuous" only.

FxPortaUp:
	; Don't touch the channel if not allowed to.
	ldh a, [hAllowedChannels]
	and c
	ret z
	; TODO: runtime assert that CH4 is not the target
	; Compute the pointer to NRx3, bit twiddling courtesy of @calc84maniac.
	; a = 1 (CH1), 2 (CH2), or 4 (CH3).
	xor $11  ; 10, 13, 15
	add a, c ; 11, 15, 19
	cp LOW(rNR23)
	adc a, c ; 13, 18, 1D
	ld c, a
	; Cache control mask for writing to NRx4.
	ld hl, wCH1.ctrlMask - wCH1.note
	add hl, de
	ld a, [hli]
	assert wCH1.ctrlMask + 1 == wCH1.period
	res 7, a ; Remove trigger bit.
	ld e, a
	; Add param to period, writing it back & to NRx3/4.
	ld a, [hl]
	add a, b
	ld [hli], a
	ldh [c], a
	inc c
	ld a, 0
	adc a, [hl]
	ld [hl], a
	or e ; Add control mask.
	ldh [c], a
	ret


FxPortaDown:
	; Don't touch the channel if not allowed to.
	ldh a, [hAllowedChannels]
	and c
	ret z
	; TODO: runtime assert that CH4 is not the target
	; Compute the pointer to NRx3, bit twiddling courtesy of @calc84maniac.
	; a = 1 (CH1), 2 (CH2), or 4 (CH3).
	xor $11  ; 10, 13, 15
	add a, c ; 11, 15, 19
	cp LOW(rNR23)
	adc a, c ; 13, 18, 1D
	ld c, a
	; Cache control mask for writing to NRx4.
	ld hl, wCH1.ctrlMask - wCH1.note
	add hl, de
	ld a, [hli]
	assert wCH1.ctrlMask + 1 == wCH1.period
	res 7, a ; Remove trigger bit.
	ld e, a
	; Add param to period, writing it back & to NRx3/4.
	ld a, [hl]
	sub b
	ld [hli], a
	ldh [c], a
	inc c
	sbc a, a
	add a, [hl]
	ld [hl], a
	or e ; Add control mask.
	ldh [c], a
	ret


; The jump table is in the middle of the functions so that backwards `jr`s can be used as well as forwards.
ContinuousFx:
	jr FxArpeggio
	jr FxPortaUp
	jr FxPortaDown
	jr FxTonePorta
	jr FxVibrato
	No set master volume
	jr FxCallRoutine
	jr FxNoteDelay
	No set panning
	No set duty cycle
	No volume slide
	No pos jump
	No set volume
	No pattern break
	jr FxNoteCut
	ret ; No set speed.


; Tone porta is a bit below, so that it's closer to `FxTonePorta2`.


SubpatternFxVibrato:
	call FxResetVibCounter
	; fallthrough
FxVibrato:
	; Don't touch the channel if not allowed to.
	ldh a, [hAllowedChannels]
	and c
	ret z
	; TODO: runtime assert that CH4 is not the target
	; Compute the pointer to NRx3, bit twiddling courtesy of @calc84maniac.
	; a = 1 (CH1), 2 (CH2), or 4 (CH3).
	xor $11  ; 10, 13, 15
	add a, c ; 11, 15, 19
	cp LOW(rNR23)
	adc a, c ; 13, 18, 1D
	ld c, a
	; Tick the vibrato.
	ld hl, wCH1.vibratoCounter - wCH1.note
	add hl, de
	ld a, [hl]
	sub $10 ; Decrement the counter in the upper 4 bits. TODO: it would be nicer to increment instead, then the upper nibble is already 0.
	jr nc, .noUnderflow
	and $0F ; Only keep the low 4 bits (the offset to be applied).
	xor b ; Reload the counter, and toggle the offset.
	ld [hld], a
	assert wCH1.vibratoCounter - 1 == wCH1.period + 1
	xor b ; Get back the previous value (the offset to be applied).
	ld e, a
	ld d, [hl] ; Read HIGH(period).
	dec hl
	ld a, [hld] ; Read LOW(period).
	assert wCH1.period - 1 == wCH1.ctrlMask
	add a, e
	ldh [c], a
	inc c
	ld a, 0
	adc a, d
	or [hl] ; Add the control bits.
	res 7, a ; Don't retrigger the note.
	ldh [c], a
	ret

.noUnderflow
	ld [hl], a
	ret


; This is only half of the logic. The other half is in `FxTonePorta2`.
FxTonePorta:
	; Don't touch the channel if not allowed to.
	ldh a, [hAllowedChannels]
	and c
	ret z
	; TODO: runtime assert that CH4 is not the target
	; Compute the pointer to NRx3, bit twiddling courtesy of @calc84maniac.
	; a = 1 (CH1), 2 (CH2), or 4 (CH3).
	xor $11  ; 10, 13, 15
	add a, c ; 11, 15, 19
	cp LOW(rNR23)
	adc a, c ; 13, 18, 1D
	ld c, a
	; Load the target period.
	ld hl, wCH1.portaTarget + 1 - wCH1.note
	add hl, de
	ld a, [hld]
	ld d, a
	ld a, [hld]
	ld e, a
	assert wCH1.period == wCH1.portaTarget - 2
	; TODO: I don't like that `push`, can we do better?
	dec hl
	push hl ; Save the pointer to LOW(period).
	ld a, [hli]
	ld h, [hl]
	; Compute the delta between `current` and `target`.
	sub e
	ld l, a
	ld a, h
	sbc a, d
	ld h, a
	; Move the (signed) delta towards 0.
	add a, a ; What's the sign of `delta`?
	ld a, l
	jr c, FxTonePorta2.goUp ; `current` < `target`
	sub b
	ld l, a
	ld a, h
	sbc a, 0
	jr FxTonePorta2.checkOverflow


FxNoteDelay:
	; Should the note start now?
	ld a, [wRowTimer]
	ld e, a ; How many ticks are remaining.
	ld a, [wTicksPerRow]
	sub e ; How many ticks have elapsed.
	cp b
	ret nz ; Wait until the time is right.
	; All of the "play note" functions expect the note param in d, so let's begin with that.
	ld h, d ; The "duty" code path needs to save `de`, though.
	ld a, [de] ; Read the note byte.
	ld d, a
	; Dispatch.
	bit 3, c
	jp nz, PlayNoiseNote
	bit 2, c
	jp nz, PlayWaveNote
	; The duty function expects a few more params.
	ld l, e ; The high byte of the note pointer was already transferred above.
	dec hl
	assert wCH1.note - 1 == wCH1.instrAndFX
	ld e, c ; Transfer the bit mask, since we already have it.
	; We must now compute LOW(rNRx4): $10 for CH1, $15 for CH2.
	srl c ; 00 / 01
	jr z, :+
	set 2, c ; 05
:
	set 4, c ; 10 / 15
	jp PlayDutyNote


FxNoteCut:
	; Should the note be cut now?
	ld a, [wRowTimer]
	ld h, a ; How many ticks are remaining.
	ld a, [wTicksPerRow]
.computeTick ; WARNING: see comments in `NoteCutTick0Trampoline` about register usage.
	sub h ; How many ticks have elapsed.
	cp b
	ret nz ; Wait until the time is right.
	; Make sure to disable the subpattern as well.
	ld hl, wCH1.subPattern - wCH1.note
	add hl, de
	xor a ; Set the pointer to NULL.
	ld [hli], a
	ld [hli], a
	; Don't touch the channel if not allowed to.
	ldh a, [hAllowedChannels]
	and c
	ret z
	; Ok, time to shut the channel down; this snippet optimised by @nitro2k01.
	; We write $08 to NRx2 to mute the channel without turning off the DAC, which makes a "pop".
	cp hUGE_CH3_MASK ; Two comparisons for the price of one!
	jr z, .ch3
	jr nc, .ch4 ; Only CH4 has a mask greater than CH3's.
	; Compute a pointer to NRx2.
	; CH1 = 1, CH2 = 2
	add a, 2 ; 03, 04
	xor $12  ; 11, 16
	inc a    ; 12, 17
	ld c, a
	ld a, AUDENV_UP
	ldh [c],a
	inc c ; NRx3
	inc c ; NRx4
	ld a, AUDHIGH_RESTART
	ldh [c], a
	ret

.ch4
	assert hUGE_CH4_MASK == AUDENV_UP
	ldh [rNR42], a
	ld a, AUDHIGH_RESTART
	ldh [rNR44], a
	ret

.ch3
	; CH3's DAC is instead controlled by NR30 bit 7, so let's turn it off briefly (again, avoiding pops).
	ld hl, rNR30
	ld [hl], l ; This has bit 7 reset.
	ld [hl], h ; This has bit 7 set.
	ret


; We can't fit all of `FxTonePorta` without `jr FxNoteCut` breaking.
; This is the function's second half.
; The split is essentially free because all code paths in `FxTonePorta` eventually jump anyway.
FxTonePorta2:
.goUp
	add a, b
	ld l, a
	ld a, h
	adc a, 0
.checkOverflow
	; If we over/underflowed, clamp at 0.
	jr nc, .noOverflow
	xor a
	ld l, a
.noOverflow
	ld h, a
	; `delta` was originally `current - target`, so `current` should be `delta + target`.
	add hl, de
	; Write it back.
	ld a, l
	ld d, h ; Save this from being overwritten.
	pop hl ; Get back a pointer to LOW(period).
	ld [hli], a
	ldh [c], a
	inc c
	ld a, d
	ld [hld], a
	dec hl
	assert wCH1.period - 1 == wCH1.ctrlMask
	or [hl]
	res 7, a ; We don't want to trigger the channel.
	ldh [c], a
	ret


; @param a: The note's index (range: 0..=63).
; @return a: The note's "polynom" (what must be written to NR43).
; @destroy e
GetNoisePolynom:
	; Flip the range.
	add 256 - 64
	cpl

	; Formula by RichardULZ:
	; https://docs.google.com/spreadsheets/d/1O9OTAHgLk1SUt972w88uVHp44w7HKEbS#gid=75028951
	; if a > 7 {
	;     let b = (a - 4) / 4;
	;     let c = (a % 4) + 4;
	;     a = c | (b << 4);
	; }

	; If a <= 7 (a < 8), do nothing.
	cp 8
	ret c
	; b = (a - 4) / 4, so b = a / 4 - 1
	ld e, a
	srl e ; / 2, e in 4..=31
	srl e ; / 4, e in 2..=15
	dec e ; e in 1..=14
	; c = (a % 4) + 4, so c = (a & 3) + 4
	and 3
	add a, 4
	; a = c | (b << 4)
	swap e ; This is a 4-bit rotate, but it's OK because e's upper 4 bits were clear.
	or e
	ret


ContinueFx: ; TODO: if this is short enough, swapping it with the other path may allow for a `jr`.
	; Run "continuous" FX.
	ld hl, wCH1.fxParams
	ld c, hUGE_CH1_MASK
	call .runFx
	ld hl, wCH1.ctrlMask
	ld c, hUGE_CH1_MASK
	call TickSubpattern

	ld hl, wCH2.fxParams
	ld c, hUGE_CH2_MASK
	call .runFx
	ld hl, wCH2.ctrlMask
	ld c, hUGE_CH2_MASK
	call TickSubpattern

	ld hl, wCH3.fxParams
	ld c, hUGE_CH3_MASK
	call .runFx
	ld hl, wCH3.ctrlMask
	ld c, hUGE_CH3_MASK
	call TickSubpattern

	ld hl, wCH4.fxParams
	ld c, hUGE_CH4_MASK
	call .runFx
	ld hl, wCH4.ctrlMask
	ld c, hUGE_CH4_MASK
	jp TickSubpattern

; @param hl: Pointer to the channel's FX params.
; @param c:  The channel's ID (0 for CH1, 1 for CH2, etc.)
; @destroy a bc de hl (potentially)
.runFx
	ld a, [hli]
	ld b, a
	ld a, [hli]
	assert wCH1.instrAndFX + 1 == wCH1.note
	ld e, l
	ld d, h
	and $0F ; Strip instrument bits.
	add a, a ; Each entry in the table is 2 bytes.
	add a, LOW(ContinuousFx)
	ld l, a
	adc a, HIGH(ContinuousFx)
	sub l
	ld h, a
	jp hl


PeriodTable:
	INCLUDE "include/hUGE_note_table.inc"


PUSHS
SECTION "hUGE music driver RAM", WRAM0 ; TODO: allow configuring

; While a channel can be safely tinkered with while muted, if wave RAM is modified,
; `hUGE_NO_WAVE` must be written to this variable before unmuting channel 3.
_hUGE_LoadedWaveID::
hUGE_LoadedWaveID:: db ; ID of the wave the driver currently has loaded in RAM.
	DEF hUGE_NO_WAVE equ 100
	EXPORT hUGE_NO_WAVE

wArpState: db ; 1 = No offset, 2 = Use Y, 3 = Use X. Global coounter for continuity across rows.
wRowTimer: db ; How many ticks until switching to the next row.

; Active song "cache".

wTicksPerRow: db ; How many ticks between each row.
wLastPatternIdx: db ; Index of the last pattern in the orders.

wDutyInstrs: dw
wWaveInstrs: dw
wNoiseInstrs: dw

wRoutines: dw

wWaves: dw

; Global variables.

IF DEF(PREVIEW_MODE)
loop_order: db ; If non-zero, instead of falling through to the next pattern, loop the current one.
current_order:
ENDC
wOrderIdx: db ; Index into the orders, *in bytes*.
wPatternIdx: db ; Index into the current patterns, with the two high bits set.
wForceRow: db ; If non-zero, will be written (verbatim) to `patternIdx` on the next tick 0, bypassing the increment.

; Individual channels.
MACRO channel
	; Pointer to the channel's order; never changes mid-song.
	; (Part of the "song cache", in a way, but per-channel.)
	.order: dw
	; The current row's FX parameters.
	.fxParams: db
	; The current row's instrument (high nibble) and FX ID (low nibble).
	.instrAndFX: db
	; The current row's note.
	.note: db
	.subPattern: dw ; Pointer to the channel's subpattern.
	.subPatternRow: db ; Which row the subpattern is currently in.
	.ctrlMask: db ; The upper 2 bits written to NRx4.
	IF (\1) != 4
		; The current "period" (what gets written to NRx3/NRx4).
		; This must be cached for effects like toneporta, which decouple this from the note.
		.period: dw
		UNION
			; The "period" that tone porta slides towards.
			; (Redundant with the "note", but makes the "continuous" FX code faster.)
			.portaTarget: dw
		NEXTU
			.vibratoCounter: db ; Upper 4 bits count down, lower 4 bits contain the next offset from the base note.
		ENDU
	ELSE ; CH4 is a lil' different.
		; The LFSR width bit (as in NR43).
		.lfsrWidth: db
		; The current "polynom" (what gets written to NR43).
		.polynom: db
		ds 2 ; Ensures that both branches are the same size.
	ENDC
ENDM

wCH1:  channel 1
wCH2:  channel 2
wCH3:  channel 3
wCH4:  channel 4


SECTION "hUGE music driver HRAM", HRAM

; `hAllowedChannels` is accessed directly a *lot* in FX code, and the 1-byte save from `ldh`
; helps keeping all the code in `jr` range.


; As soon as a channel's bit gets set in this variable, the driver will stop updating any of its registers.
; This is useful, for example, for playing sound effects: temporarily "mute" one of the song's channels,
; play the SFX on it, and un-mute it to "release" it back to the driver.
;
; Note that the driver will not touch the channel until a new note plays on it.
;
; IMPORTANT: muting CH3 (the wave channel) requires special attention: if wave RAM is modified, you
;            must set `hUGE_LoadedWaveID` to `hUGE_NO_WAVE` before unmuting the channel.
_hMutedChannels:: ; C interface.
hMutedChannels:: db
hAllowedChannels: db ; Bit mask of which channels the driver is allowed to use.
hSongBank:: db

; The two variables above use these masks.
	DEF hUGE_CH1_MASK equ 1 << 0
	DEF hUGE_CH2_MASK equ 1 << 1
	DEF hUGE_CH3_MASK equ 1 << 2
	DEF hUGE_CH4_MASK equ 1 << 3
	EXPORT hUGE_CH1_MASK, hUGE_CH2_MASK, hUGE_CH3_MASK, hUGE_CH4_MASK

POPS

IF DEF(PREVIEW_MODE)
	hUGE_init::
		ld d, h
		ld e, l
		jp hUGE_StartSong

	hUGE_dosound::
		; Check if the tracker requested a row break.
		ld a, [row_break]
		and a
		jr z, .noBreak
		dec a
		assert PATTERN_LENGTH == 1 << 6, "Pattern length must be a power of 2"
		or -PATTERN_LENGTH
		ld [wForceRow], a
		xor a
		ld [row_break], a
	.noBreak

		ld a, [next_order]
		and a
		jr z, .noOrderChange
		dec a
		add a, a
		ld [wOrderIdx], a
		xor a
		ld [next_order], a
	.noOrderChange

		call hUGE_TickSound
		TAKE_REG_SNAPSHOT

		; Convert row info to the format the tracker expects.
		ld a, [wPatternIdx]
		assert PATTERN_LENGTH == 1 << 6, "Pattern length must be a power of 2"
		and PATTERN_LENGTH - 1
		ld [row], a
		REFRESH_ROW
		ret

	SECTION "Preview variables", WRAM0

	row: db
	row_break: db
	next_order: db
ENDC
