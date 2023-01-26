; This file is to be included by generated songs as well.

def PATTERN_LENGTH equ 64

; dn note, instr, effect
MACRO dn
    ; The tracker outputs a bunch of `dn` lines, whose arguments are identical to the tracker grid
    ; for debuggability purposes.
    ; However, some transformations can be made at compile time, which simplifies the driver, makes
    ; it faster, and most importantly, "loosens" the `jr` tangle hell that is the FX code.
    DEF NOTE = (\1)
    DEF STEAL_FLAG = ((\2) & $10) << 3 ; Used by subpatterns only.
    DEF INSTR = (\2) & $0F
    DEF FX = HIGH(\3)
    DEF FX_ARG = LOW(\3)

    ; Some FX-specific transformations.
    ; TODO: at least do some `assert`s where relevant
    IF FX == FX_ARPEGGIO
    ELIF FX == FX_PORTA_UP
    ELIF FX == FX_PORTA_DOWN
    ELIF FX == FX_TONE_PORTA
    ELIF FX == FX_VIBRATO
    ELIF FX == FX_MASTER_VOL
    ELIF FX == FX_ROUTINE
    ELIF FX == FX_NOTE_DELAY
    ELIF FX == FX_PANNING
    ELIF FX == FX_DUTY_CYCLE
    ELIF FX == FX_VOL_SLIDE
    ELIF FX == FX_POS_JUMP
        def FX_ARG = (FX_ARG - 1) * 2 ; This is 1-based in the tracker. Convert to `orderIdx` format.
    ELIF FX == FX_SET_VOLUME
        def FX_ARG = LOW(FX_ARG << 4) | FX_ARG >> 4 ; Swap the two nibbles to match NRx2 format.
        IF FX_ARG & $0F != 0 && FX_ARG & $F8 == 0
            ; We will kill the channel! Let's mute it but avoid that.
            def FX_ARG = $08 ; Set the volume to 0, but keep the channel alive to avoid a pop.
        ENDC
    ELIF FX == FX_PATTERN_BRK
        assert PATTERN_LENGTH == 1 << 6, "Pattern length must be a power of 2"
        def FX_ARG |= -PATTERN_LENGTH ; Convert to `forceRow` format.
    ELIF FX == FX_NOTE_CUT
    ELIF FX == FX_SET_SPEED
    ELSE
        FAIL "Unknown FX type {FX}"
    ENDC

    ; And finally, the raw binary data.
    db NOTE | STEAL_FLAG, INSTR << 4 | FX, FX_ARG
ENDM

rsreset
def C_3 rb
def C#3 rb
def D_3 rb
def D#3 rb
def E_3 rb
def F_3 rb
def F#3 rb
def G_3 rb
def G#3 rb
def A_3 rb
def A#3 rb
def B_3 rb
def C_4 rb
def C#4 rb
def D_4 rb
def D#4 rb
def E_4 rb
def F_4 rb
def F#4 rb
def G_4 rb
def G#4 rb
def A_4 rb
def A#4 rb
def B_4 rb
def C_5 rb
def C#5 rb
def D_5 rb
def D#5 rb
def E_5 rb
def F_5 rb
def F#5 rb
def G_5 rb
def G#5 rb
def A_5 rb
def A#5 rb
def B_5 rb
def C_6 rb
def C#6 rb
def D_6 rb
def D#6 rb
def E_6 rb
def F_6 rb
def F#6 rb
def G_6 rb
def G#6 rb
def A_6 rb
def A#6 rb
def B_6 rb
def C_7 rb
def C#7 rb
def D_7 rb
def D#7 rb
def E_7 rb
def F_7 rb
def F#7 rb
def G_7 rb
def G#7 rb
def A_7 rb
def A#7 rb
def B_7 rb
def C_8 rb
def C#8 rb
def D_8 rb
def D#8 rb
def E_8 rb
def F_8 rb
def F#8 rb
def G_8 rb
def G#8 rb
def A_8 rb
def A#8 rb
def B_8 rb
def LAST_NOTE rb
def ___ equ 90 ; the default "no note" value

rsreset
def FX_ARPEGGIO rb
def FX_PORTA_UP rb
def FX_PORTA_DOWN rb
def FX_TONE_PORTA rb
def FX_VIBRATO rb
def FX_MASTER_VOL rb
def FX_ROUTINE rb
def FX_NOTE_DELAY rb
def FX_PANNING rb
def FX_DUTY_CYCLE rb
def FX_VOL_SLIDE rb
def FX_POS_JUMP rb
def FX_SET_VOLUME rb
def FX_PATTERN_BRK rb
def FX_NOTE_CUT rb
def FX_SET_SPEED rb
