;
; Sound effects driver for GB
;
; Copyright 2018, 2019 Damian Yerrick
;
; This software is provided 'as-is', without any express or implied
; warranty.  In no event will the authors be held liable for any damages
; arising from the use of this software.
;
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
;
; 1. The origin of this software must not be misrepresented; you must not
;    claim that you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation would be
;    appreciated but is not required.
; 2. Altered source versions must be plainly marked as such, and must not be
;    misrepresented as being the original software.
; 3. This notice may not be removed or altered from any source distribution.
;
; This version of audio.asm has been slightly modified by Eievui for use in the
; VuiBui engine. A precomputed pitch table is included at the bottom of this
; file, originally generated using Damian Yerrick's `pitchtable.py`
;
; Additionally, the `audio_update` function was updated to swap to the SFX bank,
; and the engine now mutes channels in GBT player as needed.

include "hardware.inc"

def LOG_SIZEOF_CHANNEL equ 3
def LOG_SIZEOF_SFX equ 2
def NUM_CHANNELS equ 4

def ENVB_DPAR equ 5
def ENVB_PITCH equ 4
def ENVF_QPAR equ $C0
def ENVF_DPAR equ $20
def ENVF_PITCH equ $10
def ENVF_DURATION equ $0F

section "audio_wram", wram0, ALIGN[LOG_SIZEOF_CHANNEL]
audio_channels: ds NUM_CHANNELS << LOG_SIZEOF_CHANNEL
def Channel_envseg_cd = 0
def Channel_envptr = 1
def Channel_envpitch = 3

section "audioengine", rom0

; Starting sequences ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

audio_init::
  ; Init PSG
  ld a,$80
  ldh [rNR52],a  ; bring audio out of reset
  ld a,$FF
  ldh [rNR51],a  ; set panning
  ld a,$77
  ldh [rNR50],a
  ld a,$08
  ldh [rNR10],a  ; disable sweep

  ; Silence all channels
  xor a
  ldh [rNR12],a
  ldh [rNR22],a
  ldh [rNR32],a
  ldh [rNR42],a
  ld a,$80
  ldh [rNR14],a
  ldh [rNR24],a
  ldh [rNR34],a
  ldh [rNR44],a

  ; Clear sound effect state
  xor a
  ld hl,audio_channels
  ld bc,NUM_CHANNELS << LOG_SIZEOF_CHANNEL
  jp MemSet

;;
; Plays sound effect A.
; Trashes ABCHL
audio_play_fx::
  ld h, a
  ldh a, [hCurrentBank]
  push af
  ld a, bank("Sound Effects")
  rst SwapBank
  ld a, h
  ld h,high(sfx_table >> 2)
  add low(sfx_table >> 2)
  jr nc,.nohlwrap
    inc h
  .nohlwrap:
  ld l,a
  add hl,hl
  add hl,hl
  ld a,[hl]  ; channel ID
  call GetBitA
  ld b, a
  ldh a, [hMutedChannels]
  xor a, b
  ldh [hMutedChannels], a
  ld a, [hli]
  inc l
  ld c,[hl]   ; ptr lo
  inc l
  ld b,[hl]   ; ptr hi

  ; Get pointer to channel
  rept LOG_SIZEOF_CHANNEL
    add a
  endr
  add low(audio_channels+Channel_envseg_cd)
  ld l,a
  ld a,0
  adc high(audio_channels)
  ld h,a

  xor a  ; begin effect immediately
  ld [hl+],a
  ld a,c
  ld [hl+],a
  ld [hl],b

  pop af
  rst SwapBank
  ret

; Sequence reading ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

audio_update::
  ld a,0
  call audio_update_ch_a
  ld a,1
  call audio_update_ch_a
  ld a,2
  call audio_update_ch_a
  ld a,3

audio_update_ch_a:
  ld b, a
  ; Get pointer to current position in effect
  ld l,a
  ld h,0
  rept LOG_SIZEOF_CHANNEL
    add hl,hl
  endr
  ld de,audio_channels+Channel_envseg_cd
  add hl,de

  ; Each segment has a duration in frames.  If this segment's
  ; duration has not expired, do nothing.
  ld a,[hl]
  or a
  jr z,.read_next_segment
    dec [hl]
    ret
  .read_next_segment:

  inc l
  ld e,[hl]
  inc l
  ld a,[hl-]
  ld d,a
  or e
  ret z  ; address $0000: no playback

  ; HL points at low byte of effect position
  ; DE = effect pointer
  ld a,[de]
  cp $F0
  jr c,.not_special
    ; Currently all specials mean stop playback
    ld a, b
    call GetBitA
    ld b, a
    ldh a, [hMutedChannels]
    xor a, b
    ldh [hMutedChannels], a
    xor a
    ld [hl+],a
    ld [hl+],a  ; Clear pointer to sound sequence
    ld d,a
    ld bc,($C0 | ENVF_DPAR) << 8
    jr .call_updater
  .not_special:
  inc de

  ; Save this envelope segment's duration
  ld b,a
  and ENVF_DURATION
  dec l
  ld [hl+],a

  ; Is there a deep parameter?
  bit ENVB_DPAR,b
  jr z,.nodeep
    ld a,[de]
    inc de
    ld c,a
  .nodeep:

  bit ENVB_PITCH,b
  jr z,.nopitch
    ld a,[de]
    inc de
    inc l
    inc l
    ld [hl-],a
    dec l
  .nopitch:

  ; Write back envelope position
  ld [hl],e
  inc l
  ld [hl],d
  inc l
  ld d,[hl]
  ; Regmap:
  ; B: quick parameter and flags
  ; C: deep parameter valid if BIT 5, B
  ; D: pitch, which changed if BIT 4, B

.call_updater:
  ; Seek to the appropriate audio channel's updater
  ld a,l
  sub low(audio_channels)
  ; rgbasm's nightmare of a parser can't subtract.
  ; Parallels to lack of "sub hl,*"?
  rept LOG_SIZEOF_CHANNEL + (-1)
    rra
  endr
  and $06

  ld hl,channel_writing_jumptable
  add l
  jr nc,.nohlwrap
    inc h
  .nohlwrap:
  ld l,a
  jp hl

; Channel hardware updaters ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_noise:
  ; Noise has no quick parameter.  Change pitch and timbre first
  ld a,d
  ldh [rNR43],a
  ; If no deep parameter, return quickly
  bit ENVB_DPAR,b
  ret z

  ; New deep parameter
  ld a,c
  ldh [rNR42],a
  ; See note below about turning off the DAC
  ld a,8
  cp c
  jr c,.no_vol8fix
    ldh [rNR42],a
  .no_vol8fix:
  ld a,$80
  ldh [rNR44],a
  ret

update_pulse1:
  ld hl,rNR11
  jr update_pulse_hl
update_pulse2:
  ld hl,rNR21
update_pulse_hl:
  ld [hl],b  ; Quick parameter is duty
  inc l
  bit ENVB_DPAR,b
  jr z,.no_new_volume
    ; Deep parameter is volume envelope
    ; APU turns off the DAC if the starting volume (bit 7-4) is 0
    ; and increase mode (bit 3) is off, which corresponds to NRx2
    ; values $00-$07.  Turning off the DAC makes a clicking sound as
    ; the level gradually returns to 7.5 as the current leaks out.
    ; But LIJI32 in gbdev Discord pointed out that if the DAC is off
    ; for only a few microseconds, it doesn't have time to leak out
    ; appreciably.
    ld a,8
    cp c
    ld [hl],c
    jr c,.no_vol8fix
      ld [hl],a
    .no_vol8fix:
  .no_new_volume:
  inc l
set_pitch_hl_to_d:
  ; Write pitch
  ld a,d
  add a
  ld de,pitch_table
  add e
  ld e,a
  jr nc,.nodewrap
    inc d
  .nodewrap:
  ld a,[de]
  inc de
  ld [hl+],a
  ld a,[de]
  bit ENVB_DPAR,b
  jr z,.no_restart_note
    set 7,a
  .no_restart_note:
  ld [hl+],a
  ret

;;
; @param B quick parameter and flags
; @param C deep parameter if valid
; @param D current pitch
channel_writing_jumptable:
  jr update_pulse1 ; no-optimize Stub jump
  jr update_pulse2
  jr update_wave
  jr update_noise

update_wave:
  ; First update volume (quick parameter)
  ld a,b
  add $40
  rra
  ldh [rNR32],a

  ; Update wave 9
  bit ENVB_DPAR,b
  jr z,.no_new_wave

  ; Get address of wave C
  ld h,high(wavebank >> 4)
  ld a,low(wavebank >> 4)
  add c
  ld l,a
  add hl,hl
  add hl,hl
  add hl,hl
  add hl,hl

  ; Copy wave
  xor a
  ldh [rNR30],a  ; give CPU access to waveram

  def WAVEPTR = _AUD3WAVERAM

  rept 16
    ld a,[hl+]
    ldh [WAVEPTR],a
  def WAVEPTR += 1
  endr
  ld a,$80
  ldh [rNR30],a  ; give APU access to waveram

.no_new_wave:
  ld hl,rNR33
  jr set_pitch_hl_to_d

; Precomputed pitch table
section "pitch_table",rom0,align[1]
pitch_table::
  dw   51,  163,  269,  368,  463,  552,  636,  715
  dw  790,  860,  927,  990, 1049, 1105, 1158, 1208
  dw 1255, 1300, 1342, 1381, 1419, 1454, 1488, 1519
  dw 1549, 1577, 1603, 1628, 1652, 1674, 1695, 1715
  dw 1733, 1751, 1768, 1783, 1798, 1812, 1826, 1838
  dw 1850, 1861, 1871, 1881, 1891, 1900, 1908, 1916
  dw 1923, 1930, 1937, 1943, 1949, 1954, 1960, 1965
  dw 1969, 1974, 1978, 1982, 1986, 1989, 1992, 1996
