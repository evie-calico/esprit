;*
;* Gameboy Hardware definitions
;*
;* Based on Jones' hardware.inc
;* And based on Carsten Sorensen's ideas.
;*
;* Rev 1.1 - 15-Jul-97 : Added define check
;* Rev 1.2 - 18-Jul-97 : Added revision check macro
;* Rev 1.3 - 19-Jul-97 : Modified for RGBASM V1.05
;* Rev 1.4 - 27-Jul-97 : Modified for new subroutine prefixes
;* Rev 1.5 - 15-Aug-97 : Added _HRAM, PAD, CART defines
;*                     :  and Nintendo Logo
;* Rev 1.6 - 30-Nov-97 : Added rDIV, rTIMA, rTMA, & rTAC
;* Rev 1.7 - 31-Jan-98 : Added _SCRN0, _SCRN1
;* Rev 1.8 - 15-Feb-98 : Added rSB, rSC
;* Rev 1.9 - 16-Feb-98 : Converted I/O registers to $FFXX format
;* Rev 2.0 -           : Added GBC registers
;* Rev 2.1 -           : Added MBC5 & cart RAM enable/disable defines
;* Rev 2.2 -           : Fixed NR42,NR43, & NR44 equates
;* Rev 2.3 -           : Fixed incorrect _HRAM equate
;* Rev 2.4 - 27-Apr-13 : Added some cart defines (AntonioND)
;* Rev 2.5 - 03-May-15 : Fixed format (AntonioND)
;* Rev 2.6 - 09-Apr-16 : Added GBC OAM and cart defines (AntonioND)
;* Rev 2.7 - 19-Jan-19 : Added rPCMXX (ISSOtm)
;* Rev 2.8 - 03-Feb-19 : Added audio registers flags (Álvaro Cuesta)
;* Rev 2.9 - 28-Feb-20 : Added utility rP1 constants
;* Rev 3.0 - 27-Aug-20 : Register ordering, byte-based sizes, OAM additions, general cleanup (Blitter Object)
;* Rev 4.0 - 03-May-21 : Updated to use RGBDS 0.5.0 syntax, changed IEF_LCDC to IEF_STAT (Eievui)
;* Rev 4.1 - 16-Aug-21 : Added more flags, bit number defines, and offset constants for OAM and window positions (rondnelson99)
;* Rev 4.2 - 04-Sep-21 : Added CH3- and CH4-specific audio registers flags (ISSOtm)
;* Rev 4.3 - 07-Nov-21 : Deprecate VRAM address constants (Eievui)
;* Rev 4.4 - 11-Jan-22 : Deprecate VRAM CART_SRAM_2KB constant (avivace)
;* Rev 4.5 - 03-Mar-22 : Added bit number definitions for OCPS, BCPS and LCDC (sukus)
;* Rev 4.6 - 15-Jun-22 : Added MBC3 registers and special values
;* Rev 4.7.0 - 27-Jun-22 : Added alternate names for some constants
;* Rev 4.7.1 - 05-Jul-22 : Added RPB_LED_ON constant

; NOTE: REVISION NUMBER CHANGES MUST BE REFLECTED
; IN `rev_Check_hardware_inc` BELOW!

if __RGBDS_MAJOR__ == 0 && __RGBDS_MINOR__ < 5
    fail "This version of 'hardware.inc' requires RGBDS version 0.5.0 or later."
endc

; If all of these are already defined, don't do it again.

    if !def(HARDWARE_INC)
def HARDWARE_INC equ 1

; Usage: rev_Check_hardware_inc <min_ver>
; Examples: rev_Check_hardware_inc 4.1.2
;           rev_Check_hardware_inc 4.1 (equivalent to 4.1.0)
;           rev_Check_hardware_inc 4 (equivalent to 4.0.0)
macro rev_Check_hardware_inc
    def CUR_VER equs "4,7,1"    ; ** UPDATE THIS LINE WHEN CHANGING THE REVISION NUMBER **
    def MIN_VER equs STRRPL("\1", ".", ",")
    def INTERNAL_CHK equs """macro ___internal
    if \\1 != \\4 || \\2 < \\5 || (\\2 == \\5 && \\3 < \\6)
    	fail "Version \\1.\\2.\\3 of 'hardware.inc' is incompatible with requested version \\4.\\5.\\6"
    endc
\nENDM"""
    INTERNAL_CHK
    ___internal {CUR_VER}, {MIN_VER},0,0
    purge CUR_VER, MIN_VER, INTERNAL_CHK, ___internal
endm


;***************************************************************************
;*
;* General memory region constants
;*
;***************************************************************************

def _VRAM        equ $8000 ; $8000->$9FFF
def _SCRN0       equ $9800 ; $9800->$9BFF
def _SCRN1       equ $9C00 ; $9C00->$9FFF
def _SRAM        equ $A000 ; $A000->$BFFF
def _RAM         equ $C000 ; $C000->$CFFF / $C000->$DFFF
def _RAMBANK     equ $D000 ; $D000->$DFFF
def _OAMRAM      equ $FE00 ; $FE00->$FE9F
def _IO          equ $FF00 ; $FF00->$FF7F,$FFFF
def _AUD3WAVERAM equ $FF30 ; $FF30->$FF3F
def _HRAM        equ $FF80 ; $FF80->$FFFE


;***************************************************************************
;*
;* MBC registers
;*
;***************************************************************************

; *** Common ***

; --
; -- RAMG ($0000-$1FFF)
; -- Controls whether access to SRAM (and the MBC3 RTC registers) is allowed (W)
; --
def rRAMG equ $0000

def CART_SRAM_ENABLE  equ $0A
def CART_SRAM_DISABLE equ $00


; --
; -- ROMB0 ($2000-$3FFF)
; -- Selects which ROM bank is mapped to the romx space ($4000-$7FFF) (W)
; --
; -- The range of accepted values, as well as the behavior of writing $00,
; -- varies depending on the MBC.
; --
def rROMB0 equ $2000

; --
; -- RAMB ($4000-$5FFF)
; -- Selects which SRAM bank is mapped to the SRAM space ($A000-$BFFF) (W)
; --
; -- The range of accepted values varies depending on the cartridge configuration.
; --
def rRAMB equ $4000


; *** MBC3-specific registers ***

; Write one of these to rRAMG to map the corresponding RTC register to all SRAM space
def RTC_S  equ $08 ; Seconds  (0-59)
def RTC_M  equ $09 ; Minutes  (0-59)
def RTC_H  equ $0A ; Hours    (0-23)
def RTC_DL equ $0B ; Lower 8 bits of Day Counter ($00-$FF)
def RTC_DH equ $0C ; Bit 7 - Day Counter Carry Bit (1=Counter Overflow)
                   ; Bit 6 - Halt (0=Active, 1=Stop Timer)
                   ; Bit 0 - Most significant bit of Day Counter (Bit 8)


; --
; -- RTCLATCH ($6000-$7FFF)
; -- Write $00 then $01 to latch the current time into the RTC registers (W)
; --
def rRTCLATCH equ $6000


; *** MBC5-specific register ***

; --
; -- ROMB1 ($3000-$3FFF)
; -- A 9th bit that "extends" ROMB0 if more than 256 banks are present (W)
; --
; -- Also note that rROMB0 thus only spans $2000-$2FFF.
; --
def rROMB1 equ $3000


; Bit 3 of RAMB enables the rumble motor (if any)
def CART_RUMBLE_ON equ 1 << 3


;***************************************************************************
;*
;* Memory-mapped registers
;*
;***************************************************************************

; --
; -- P1 ($FF00)
; -- Register for reading joy pad info. (R/W)
; --
def rP1 equ $FF00

def P1F_5 equ %00100000 ; P15 out port, set to 0 to get buttons
def P1F_4 equ %00010000 ; P14 out port, set to 0 to get dpad
def P1F_3 equ %00001000 ; P13 in port
def P1F_2 equ %00000100 ; P12 in port
def P1F_1 equ %00000010 ; P11 in port
def P1F_0 equ %00000001 ; P10 in port

def P1F_GET_DPAD equ P1F_5
def P1F_GET_BTN  equ P1F_4
def P1F_GET_NONE equ P1F_4 | P1F_5


; --
; -- SB ($FF01)
; -- Serial Transfer Data (R/W)
; --
def rSB equ $FF01


; --
; -- SC ($FF02)
; -- Serial I/O Control (R/W)
; --
def rSC equ $FF02

def SCF_START  equ %10000000 ; Transfer Start Flag (1=Transfer in progress, or requested)
def SCF_SPEED  equ %00000010 ; Clock Speed (0=Normal, 1=Fast) ** CGB Mode Only **
def SCF_SOURCE equ %00000001 ; Shift Clock (0=External Clock, 1=Internal Clock)

def SCB_START  equ 7
def SCB_SPEED  equ 1
def SCB_SOURCE equ 0

; --
; -- DIV ($FF04)
; -- Divider register (R/W)
; --
def rDIV equ $FF04


; --
; -- TIMA ($FF05)
; -- Timer counter (R/W)
; --
def rTIMA equ $FF05


; --
; -- TMA ($FF06)
; -- Timer modulo (R/W)
; --
def rTMA equ $FF06


; --
; -- TAC ($FF07)
; -- Timer control (R/W)
; --
def rTAC equ $FF07

def TACF_START  equ %00000100
def TACF_STOP   equ %00000000
def TACF_4KHZ   equ %00000000
def TACF_16KHZ  equ %00000011
def TACF_65KHZ  equ %00000010
def TACF_262KHZ equ %00000001

def TACB_START  equ 2


; --
; -- if ($FF0F)
; -- Interrupt Flag (R/W)
; --
def rIF equ $FF0F


; --
; -- AUD1SWEEP/NR10 ($FF10)
; -- Sweep register (R/W)
; --
; -- Bit 6-4 - Sweep Time
; -- Bit 3   - Sweep Increase/Decrease
; --           0: Addition    (frequency increases???)
; --           1: Subtraction (frequency increases???)
; -- Bit 2-0 - Number of sweep shift (# 0-7)
; -- Sweep Time: (n*7.8ms)
; --
def rNR10 equ $FF10
def rAUD1SWEEP equ rNR10

def AUD1SWEEP_UP   equ %00000000
def AUD1SWEEP_DOWN equ %00001000


; --
; -- AUD1LEN/NR11 ($FF11)
; -- Sound length/Wave pattern duty (R/W)
; --
; -- Bit 7-6 - Wave Pattern Duty (00:12.5% 01:25% 10:50% 11:75%)
; -- Bit 5-0 - Sound length data (# 0-63)
; --
def rNR11 equ $FF11
def rAUD1LEN equ rNR11


; --
; -- AUD1ENV/NR12 ($FF12)
; -- Envelope (R/W)
; --
; -- Bit 7-4 - Initial value of envelope
; -- Bit 3   - Envelope UP/DOWN
; --           0: Decrease
; --           1: Range of increase
; -- Bit 2-0 - Number of envelope sweep (# 0-7)
; --
def rNR12 equ $FF12
def rAUD1ENV equ rNR12


; --
; -- AUD1LOW/NR13 ($FF13)
; -- Frequency low byte (W)
; --
def rNR13 equ $FF13
def rAUD1LOW equ rNR13


; --
; -- AUD1HIGH/NR14 ($FF14)
; -- Frequency high byte (W)
; --
; -- Bit 7   - Initial (when set, sound restarts)
; -- Bit 6   - Counter/consecutive selection
; -- Bit 2-0 - Frequency's higher 3 bits
; --
def rNR14 equ $FF14
def rAUD1HIGH equ rNR14


; --
; -- AUD2LEN/NR21 ($FF16)
; -- Sound Length; Wave Pattern Duty (R/W)
; --
; -- see AUD1LEN for info
; --
def rNR21 equ $FF16
def rAUD2LEN equ rNR21


; --
; -- AUD2ENV/NR22 ($FF17)
; -- Envelope (R/W)
; --
; -- see AUD1ENV for info
; --
def rNR22 equ $FF17
def rAUD2ENV equ rNR22


; --
; -- AUD2LOW/NR23 ($FF18)
; -- Frequency low byte (W)
; --
def rNR23 equ $FF18
def rAUD2LOW equ rNR23


; --
; -- AUD2HIGH/NR24 ($FF19)
; -- Frequency high byte (W)
; --
; -- see AUD1HIGH for info
; --
def rNR24 equ $FF19
def rAUD2HIGH equ rNR24


; --
; -- AUD3ENA/NR30 ($FF1A)
; -- Sound on/off (R/W)
; --
; -- Bit 7   - Sound ON/OFF (1=ON,0=OFF)
; --
def rNR30 equ $FF1A
def rAUD3ENA equ rNR30

def AUD3ENA_OFF equ %00000000
def AUD3ENA_ON  equ %10000000


; --
; -- AUD3LEN/NR31 ($FF1B)
; -- Sound length (R/W)
; --
; -- Bit 7-0 - Sound length
; --
def rNR31 equ $FF1B
def rAUD3LEN equ rNR31


; --
; -- AUD3LEVEL/NR32 ($FF1C)
; -- Select output level
; --
; -- Bit 6-5 - Select output level
; --           00: 0/1 (mute)
; --           01: 1/1
; --           10: 1/2
; --           11: 1/4
; --
def rNR32 equ $FF1C
def rAUD3LEVEL equ rNR32

def AUD3LEVEL_MUTE equ %00000000
def AUD3LEVEL_100  equ %00100000
def AUD3LEVEL_50   equ %01000000
def AUD3LEVEL_25   equ %01100000


; --
; -- AUD3LOW/NR33 ($FF1D)
; -- Frequency low byte (W)
; --
; -- see AUD1LOW for info
; --
def rNR33 equ $FF1D
def rAUD3LOW equ rNR33


; --
; -- AUD3HIGH/NR34 ($FF1E)
; -- Frequency high byte (W)
; --
; -- see AUD1HIGH for info
; --
def rNR34 equ $FF1E
def rAUD3HIGH equ rNR34


; --
; -- AUD4LEN/NR41 ($FF20)
; -- Sound length (R/W)
; --
; -- Bit 5-0 - Sound length data (# 0-63)
; --
def rNR41 equ $FF20
def rAUD4LEN equ rNR41


; --
; -- AUD4ENV/NR42 ($FF21)
; -- Envelope (R/W)
; --
; -- see AUD1ENV for info
; --
def rNR42 equ $FF21
def rAUD4ENV equ rNR42


; --
; -- AUD4POLY/NR43 ($FF22)
; -- Polynomial counter (R/W)
; --
; -- Bit 7-4 - Selection of the shift clock frequency of the (scf)
; --           polynomial counter (0000-1101)
; --           freq=drf*1/2^scf (not sure)
; -- Bit 3 -   Selection of the polynomial counter's step
; --           0: 15 steps
; --           1: 7 steps
; -- Bit 2-0 - Selection of the dividing ratio of frequencies (drf)
; --           000: f/4   001: f/8   010: f/16  011: f/24
; --           100: f/32  101: f/40  110: f/48  111: f/56  (f=4.194304 Mhz)
; --
def rNR43 equ $FF22
def rAUD4POLY equ rNR43

def AUD4POLY_15STEP equ %00000000
def AUD4POLY_7STEP  equ %00001000


; --
; -- AUD4GO/NR44 ($FF23)
; --
; -- Bit 7 -   Initial (when set, sound restarts)
; -- Bit 6 -   Counter/consecutive selection
; --
def rNR44 equ $FF23
def rAUD4GO equ rNR44


; --
; -- AUDVOL/NR50 ($FF24)
; -- Channel control / ON-OFF / Volume (R/W)
; --
; -- Bit 7   - Vin->SO2 ON/OFF (left)
; -- Bit 6-4 - SO2 output level (left speaker) (# 0-7)
; -- Bit 3   - Vin->SO1 ON/OFF (right)
; -- Bit 2-0 - SO1 output level (right speaker) (# 0-7)
; --
def rNR50 equ $FF24
def rAUDVOL equ rNR50

def AUDVOL_VIN_LEFT  equ %10000000 ; SO2
def AUDVOL_VIN_RIGHT equ %00001000 ; SO1


; --
; -- AUDTERM/NR51 ($FF25)
; -- Selection of Sound output terminal (R/W)
; --
; -- Bit 7   - Output channel 4 to SO2 terminal (left)
; -- Bit 6   - Output channel 3 to SO2 terminal (left)
; -- Bit 5   - Output channel 2 to SO2 terminal (left)
; -- Bit 4   - Output channel 1 to SO2 terminal (left)
; -- Bit 3   - Output channel 4 to SO1 terminal (right)
; -- Bit 2   - Output channel 3 to SO1 terminal (right)
; -- Bit 1   - Output channel 2 to SO1 terminal (right)
; -- Bit 0   - Output channel 1 to SO1 terminal (right)
; --
def rNR51 equ $FF25
def rAUDTERM equ rNR51

; SO2
def AUDTERM_4_LEFT  equ %10000000
def AUDTERM_3_LEFT  equ %01000000
def AUDTERM_2_LEFT  equ %00100000
def AUDTERM_1_LEFT  equ %00010000
; SO1
def AUDTERM_4_RIGHT equ %00001000
def AUDTERM_3_RIGHT equ %00000100
def AUDTERM_2_RIGHT equ %00000010
def AUDTERM_1_RIGHT equ %00000001


; --
; -- AUDENA/NR52 ($FF26)
; -- Sound on/off (R/W)
; --
; -- Bit 7   - All sound on/off (sets all audio regs to 0!)
; -- Bit 3   - Sound 4 ON flag (read only)
; -- Bit 2   - Sound 3 ON flag (read only)
; -- Bit 1   - Sound 2 ON flag (read only)
; -- Bit 0   - Sound 1 ON flag (read only)
; --
def rNR52 equ $FF26
def rAUDENA equ rNR52

def AUDENA_ON    equ %10000000
def AUDENA_OFF   equ %00000000  ; sets all audio regs to 0!


; --
; -- LCDC ($FF40)
; -- LCD Control (R/W)
; --
def rLCDC equ $FF40

def LCDCF_OFF     equ %00000000 ; LCD Control Operation
def LCDCF_ON      equ %10000000 ; LCD Control Operation
def LCDCF_WIN9800 equ %00000000 ; Window Tile Map Display Select
def LCDCF_WIN9C00 equ %01000000 ; Window Tile Map Display Select
def LCDCF_WINOFF  equ %00000000 ; Window Display
def LCDCF_WINON   equ %00100000 ; Window Display
def LCDCF_BG8800  equ %00000000 ; BG & Window Tile Data Select
def LCDCF_BG8000  equ %00010000 ; BG & Window Tile Data Select
def LCDCF_BG9800  equ %00000000 ; BG Tile Map Display Select
def LCDCF_BG9C00  equ %00001000 ; BG Tile Map Display Select
def LCDCF_OBJ8    equ %00000000 ; OBJ Construction
def LCDCF_OBJ16   equ %00000100 ; OBJ Construction
def LCDCF_OBJOFF  equ %00000000 ; OBJ Display
def LCDCF_OBJON   equ %00000010 ; OBJ Display
def LCDCF_BGOFF   equ %00000000 ; BG Display
def LCDCF_BGON    equ %00000001 ; BG Display

def LCDCB_ON      equ 7 ; LCD Control Operation
def LCDCB_WIN9C00 equ 6 ; Window Tile Map Display Select
def LCDCB_WINON   equ 5 ; Window Display
def LCDCB_BG8000  equ 4 ; BG & Window Tile Data Select
def LCDCB_BG9C00  equ 3 ; BG Tile Map Display Select
def LCDCB_OBJ16   equ 2 ; OBJ Construction
def LCDCB_OBJON   equ 1 ; OBJ Display
def LCDCB_BGON    equ 0 ; BG Display
; "Window Character Data Select" follows BG


; --
; -- STAT ($FF41)
; -- LCDC Status   (R/W)
; --
def rSTAT equ $FF41

def STATF_LYC     equ  %01000000 ; LYC=LY Coincidence (Selectable)
def STATF_MODE10  equ  %00100000 ; Mode 10
def STATF_MODE01  equ  %00010000 ; Mode 01 (V-Blank)
def STATF_MODE00  equ  %00001000 ; Mode 00 (H-Blank)
def STATF_LYCF    equ  %00000100 ; Coincidence Flag
def STATF_HBL     equ  %00000000 ; H-Blank
def STATF_VBL     equ  %00000001 ; V-Blank
def STATF_OAM     equ  %00000010 ; OAM-RAM is used by system
def STATF_LCD     equ  %00000011 ; Both OAM and VRAM used by system
def STATF_BUSY    equ  %00000010 ; When set, VRAM access is unsafe

def STATB_LYC     equ  6
def STATB_MODE10  equ  5
def STATB_MODE01  equ  4
def STATB_MODE00  equ  3
def STATB_LYCF    equ  2
def STATB_BUSY    equ  1

; --
; -- SCY ($FF42)
; -- Scroll Y (R/W)
; --
def rSCY equ $FF42


; --
; -- SCX ($FF43)
; -- Scroll X (R/W)
; --
def rSCX equ $FF43


; --
; -- LY ($FF44)
; -- LCDC Y-Coordinate (R)
; --
; -- Values range from 0->153. 144->153 is the VBlank period.
; --
def rLY equ $FF44


; --
; -- LYC ($FF45)
; -- LY Compare (R/W)
; --
; -- When LY==LYC, STATF_LYCF will be set in STAT
; --
def rLYC equ $FF45


; --
; -- DMA ($FF46)
; -- DMA Transfer and Start Address (W)
; --
def rDMA equ $FF46


; --
; -- BGP ($FF47)
; -- BG Palette Data (W)
; --
; -- Bit 7-6 - Intensity for %11
; -- Bit 5-4 - Intensity for %10
; -- Bit 3-2 - Intensity for %01
; -- Bit 1-0 - Intensity for %00
; --
def rBGP equ $FF47


; --
; -- OBP0 ($FF48)
; -- Object Palette 0 Data (W)
; --
; -- See BGP for info
; --
def rOBP0 equ $FF48


; --
; -- OBP1 ($FF49)
; -- Object Palette 1 Data (W)
; --
; -- See BGP for info
; --
def rOBP1 equ $FF49


; --
; -- WY ($FF4A)
; -- Window Y Position (R/W)
; --
; -- 0 <= WY <= 143
; -- When WY = 0, the window is displayed from the top edge of the LCD screen.
; --
def rWY equ $FF4A


; --
; -- WX ($FF4B)
; -- Window X Position (R/W)
; --
; -- 7 <= WX <= 166
; -- When WX = 7, the window is displayed from the left edge of the LCD screen.
; -- Values of 0-6 and 166 are unreliable due to hardware bugs.
; --
def rWX equ $FF4B

def WX_OFS equ 7 ; add this to a screen position to get a WX position


; --
; -- SPEED ($FF4D)
; -- Select CPU Speed (R/W)
; --
def rKEY1 equ $FF4D
def rSPD  equ rKEY1

def KEY1F_DBLSPEED equ %10000000 ; 0=Normal Speed, 1=Double Speed (R)
def KEY1F_PREPARE  equ %00000001 ; 0=No, 1=Prepare (R/W)


; --
; -- VBK ($FF4F)
; -- Select Video RAM Bank (R/W)
; --
; -- Bit 0 - Bank Specification (0: Specify Bank 0; 1: Specify Bank 1)
; --
def rVBK equ $FF4F


; --
; -- HDMA1 ($FF51)
; -- High byte for Horizontal Blanking/General Purpose DMA source address (W)
; -- CGB Mode Only
; --
def rHDMA1 equ $FF51


; --
; -- HDMA2 ($FF52)
; -- Low byte for Horizontal Blanking/General Purpose DMA source address (W)
; -- CGB Mode Only
; --
def rHDMA2 equ $FF52


; --
; -- HDMA3 ($FF53)
; -- High byte for Horizontal Blanking/General Purpose DMA destination address (W)
; -- CGB Mode Only
; --
def rHDMA3 equ $FF53


; --
; -- HDMA4 ($FF54)
; -- Low byte for Horizontal Blanking/General Purpose DMA destination address (W)
; -- CGB Mode Only
; --
def rHDMA4 equ $FF54


; --
; -- HDMA5 ($FF55)
; -- Transfer length (in tiles minus 1)/mode/start for Horizontal Blanking, General Purpose DMA (R/W)
; -- CGB Mode Only
; --
def rHDMA5 equ $FF55

def HDMA5F_MODE_GP  equ %00000000 ; General Purpose DMA (W)
def HDMA5F_MODE_HBL equ %10000000 ; HBlank DMA (W)
def HDMA5B_MODE equ 7 ; DMA mode select (W)

; -- Once DMA has started, use HDMA5F_BUSY to check when the transfer is complete
def HDMA5F_BUSY equ %10000000 ; 0=Busy (DMA still in progress), 1=Transfer complete (R)


; --
; -- RP ($FF56)
; -- Infrared Communications Port (R/W)
; -- CGB Mode Only
; --
def rRP equ $FF56

def RPF_ENREAD   equ %11000000
def RPF_DATAIN   equ %00000010 ; 0=Receiving IR Signal, 1=Normal
def RPF_WRITE_HI equ %00000001
def RPF_WRITE_LO equ %00000000

def RPB_LED_ON   equ 0
def RPB_DATAIN   equ 1


; --
; -- BCPS/BGPI ($FF68)
; -- Background Color Palette Specification (aka Background Palette Index) (R/W)
; --
def rBCPS equ $FF68
def rBGPI equ rBCPS

def BCPSF_AUTOINC equ %10000000 ; Auto Increment (0=Disabled, 1=Increment after Writing)
def BCPSB_AUTOINC equ 7
def BGPIF_AUTOINC equ BCPSF_AUTOINC
def BGPIB_AUTOINC equ BCPSB_AUTOINC


; --
; -- BCPD/BGPD ($FF69)
; -- Background Color Palette Data (aka Background Palette Data) (R/W)
; --
def rBCPD equ $FF69
def rBGPD equ rBCPD


; --
; -- OCPS/OBPI ($FF6A)
; -- Object Color Palette Specification (aka Object Background Palette Index) (R/W)
; --
def rOCPS equ $FF6A
def rOBPI equ rOCPS

def OCPSF_AUTOINC equ %10000000 ; Auto Increment (0=Disabled, 1=Increment after Writing)
def OCPSB_AUTOINC equ 7
def OBPIF_AUTOINC equ OCPSF_AUTOINC
def OBPIB_AUTOINC equ OCPSB_AUTOINC


; --
; -- OCPD/OBPD ($FF6B)
; -- Object Color Palette Data (aka Object Background Palette Data) (R/W)
; --
def rOCPD equ $FF6B
def rOBPD equ rOCPD


; --
; -- SMBK/SVBK ($FF70)
; -- Select Main RAM Bank (R/W)
; --
; -- Bit 2-0 - Bank Specification (0,1: Specify Bank 1; 2-7: Specify Banks 2-7)
; --
def rSVBK equ $FF70
def rSMBK equ rSVBK


; --
; -- PCM12 ($FF76)
; -- Sound channel 1&2 PCM amplitude (R)
; --
; -- Bit 7-4 - Copy of sound channel 2's PCM amplitude
; -- Bit 3-0 - Copy of sound channel 1's PCM amplitude
; --
def rPCM12 equ $FF76


; --
; -- PCM34 ($FF77)
; -- Sound channel 3&4 PCM amplitude (R)
; --
; -- Bit 7-4 - Copy of sound channel 4's PCM amplitude
; -- Bit 3-0 - Copy of sound channel 3's PCM amplitude
; --
def rPCM34 equ $FF77


; --
; -- IE ($FFFF)
; -- Interrupt Enable (R/W)
; --
def rIE equ $FFFF

def IEF_HILO   equ %00010000 ; Transition from High to Low of Pin number P10-P13
def IEF_SERIAL equ %00001000 ; Serial I/O transfer end
def IEF_TIMER  equ %00000100 ; Timer Overflow
def IEF_STAT   equ %00000010 ; STAT
def IEF_VBLANK equ %00000001 ; V-Blank

def IEB_HILO   equ 4
def IEB_SERIAL equ 3
def IEB_TIMER  equ 2
def IEB_STAT   equ 1
def IEB_VBLANK equ 0


;***************************************************************************
;*
;* Flags common to multiple sound channels
;*
;***************************************************************************

; --
; -- Square wave duty cycle
; --
; -- Can be used with AUD1LEN and AUD2LEN
; -- See AUD1LEN for more info
; --
def AUDLEN_DUTY_12_5    equ %00000000 ; 12.5%
def AUDLEN_DUTY_25      equ %01000000 ; 25%
def AUDLEN_DUTY_50      equ %10000000 ; 50%
def AUDLEN_DUTY_75      equ %11000000 ; 75%


; --
; -- Audio envelope flags
; --
; -- Can be used with AUD1ENV, AUD2ENV, AUD4ENV
; -- See AUD1ENV for more info
; --
def AUDENV_UP           equ %00001000
def AUDENV_DOWN         equ %00000000


; --
; -- Audio trigger flags
; --
; -- Can be used with AUD1HIGH, AUD2HIGH, AUD3HIGH
; -- See AUD1HIGH for more info
; --
def AUDHIGH_RESTART     equ %10000000
def AUDHIGH_LENGTH_ON   equ %01000000
def AUDHIGH_LENGTH_OFF  equ %00000000


;***************************************************************************
;*
;* CPU values on bootup (a=type, b=qualifier)
;*
;***************************************************************************

def BOOTUP_A_DMG    equ $01 ; Dot Matrix Game
def BOOTUP_A_CGB    equ $11 ; Color GameBoy
def BOOTUP_A_MGB    equ $FF ; Mini GameBoy (Pocket GameBoy)

; if a=BOOTUP_A_CGB, bit 0 in b can be checked to determine if real CGB or
; other system running in GBC mode
def BOOTUP_B_CGB    equ %00000000
def BOOTUP_B_AGB    equ %00000001   ; GBA, GBA SP, Game Boy Player, or New GBA SP


;***************************************************************************
;*
;* Header
;*
;***************************************************************************

;*
;* Nintendo scrolling logo
;* (Code won't work on a real GameBoy)
;* (if next lines are altered.)
macro NINTENDO_LOGO
    db  $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
    db  $00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
    db  $BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E
endm

; $0143 Color GameBoy compatibility code
def CART_COMPATIBLE_DMG     equ $00
def CART_COMPATIBLE_DMG_GBC equ $80
def CART_COMPATIBLE_GBC     equ $C0

; $0146 GameBoy/Super GameBoy indicator
def CART_INDICATOR_GB       equ $00
def CART_INDICATOR_SGB      equ $03

; $0147 Cartridge type
def CART_ROM                     equ $00
def CART_ROM_MBC1                equ $01
def CART_ROM_MBC1_RAM            equ $02
def CART_ROM_MBC1_RAM_BAT        equ $03
def CART_ROM_MBC2                equ $05
def CART_ROM_MBC2_BAT            equ $06
def CART_ROM_RAM                 equ $08
def CART_ROM_RAM_BAT             equ $09
def CART_ROM_MMM01               equ $0B
def CART_ROM_MMM01_RAM           equ $0C
def CART_ROM_MMM01_RAM_BAT       equ $0D
def CART_ROM_MBC3_BAT_RTC        equ $0F
def CART_ROM_MBC3_RAM_BAT_RTC    equ $10
def CART_ROM_MBC3                equ $11
def CART_ROM_MBC3_RAM            equ $12
def CART_ROM_MBC3_RAM_BAT        equ $13
def CART_ROM_MBC5                equ $19
def CART_ROM_MBC5_BAT            equ $1A
def CART_ROM_MBC5_RAM_BAT        equ $1B
def CART_ROM_MBC5_RUMBLE         equ $1C
def CART_ROM_MBC5_RAM_RUMBLE     equ $1D
def CART_ROM_MBC5_RAM_BAT_RUMBLE equ $1E
def CART_ROM_MBC7_RAM_BAT_GYRO   equ $22
def CART_ROM_POCKET_CAMERA       equ $FC
def CART_ROM_BANDAI_TAMA5        equ $FD
def CART_ROM_HUDSON_HUC3         equ $FE
def CART_ROM_HUDSON_HUC1         equ $FF

; $0148 ROM size
; these are kilobytes
def CART_ROM_32KB   equ $00 ; 2 banks
def CART_ROM_64KB   equ $01 ; 4 banks
def CART_ROM_128KB  equ $02 ; 8 banks
def CART_ROM_256KB  equ $03 ; 16 banks
def CART_ROM_512KB  equ $04 ; 32 banks
def CART_ROM_1024KB equ $05 ; 64 banks
def CART_ROM_2048KB equ $06 ; 128 banks
def CART_ROM_4096KB equ $07 ; 256 banks
def CART_ROM_8192KB equ $08 ; 512 banks
def CART_ROM_1152KB equ $52 ; 72 banks
def CART_ROM_1280KB equ $53 ; 80 banks
def CART_ROM_1536KB equ $54 ; 96 banks

; $0149 SRAM size
; these are kilobytes
def CART_SRAM_NONE  equ 0
def CART_SRAM_8KB   equ 2 ; 1 bank
def CART_SRAM_32KB  equ 3 ; 4 banks
def CART_SRAM_128KB equ 4 ; 16 banks

; $014A Destination code
def CART_DEST_JAPANESE     equ $00
def CART_DEST_NON_JAPANESE equ $01


;***************************************************************************
;*
;* Keypad related
;*
;***************************************************************************

def PADF_DOWN   equ $80
def PADF_UP     equ $40
def PADF_LEFT   equ $20
def PADF_RIGHT  equ $10
def PADF_START  equ $08
def PADF_SELECT equ $04
def PADF_B      equ $02
def PADF_A      equ $01

def PADB_DOWN   equ $7
def PADB_UP     equ $6
def PADB_LEFT   equ $5
def PADB_RIGHT  equ $4
def PADB_START  equ $3
def PADB_SELECT equ $2
def PADB_B      equ $1
def PADB_A      equ $0


;***************************************************************************
;*
;* Screen related
;*
;***************************************************************************

def SCRN_X    equ 160 ; Width of screen in pixels
def SCRN_Y    equ 144 ; Height of screen in pixels. Also corresponds to the value in LY at the beginning of VBlank.
def SCRN_X_B  equ 20  ; Width of screen in bytes
def SCRN_Y_B  equ 18  ; Height of screen in bytes

def SCRN_VX   equ 256 ; Virtual width of screen in pixels
def SCRN_VY   equ 256 ; Virtual height of screen in pixels
def SCRN_VX_B equ 32  ; Virtual width of screen in bytes
def SCRN_VY_B equ 32  ; Virtual height of screen in bytes


;***************************************************************************
;*
;* OAM related
;*
;***************************************************************************

; OAM attributes
; each entry in OAM RAM is 4 bytes (sizeof_OAM_ATTRS)
rsreset
def OAMA_Y              rb  1   ; y pos plus 16
def OAMA_X              rb  1   ; x pos plus 8
def OAMA_TILEID         rb  1   ; tile id
def OAMA_FLAGS          rb  1   ; flags (see below)
def sizeof_OAM_ATTRS    rb  0

def OAM_Y_OFS equ 16 ; add this to a screen-relative Y position to get an OAM Y position
def OAM_X_OFS equ 8  ; add this to a screen-relative X position to get an OAM X position

def OAM_COUNT           equ 40  ; number of OAM entries in OAM RAM

; flags
def OAMF_PRI        equ %10000000 ; Priority
def OAMF_YFLIP      equ %01000000 ; Y flip
def OAMF_XFLIP      equ %00100000 ; X flip
def OAMF_PAL0       equ %00000000 ; Palette number; 0,1 (DMG)
def OAMF_PAL1       equ %00010000 ; Palette number; 0,1 (DMG)
def OAMF_BANK0      equ %00000000 ; Bank number; 0,1 (GBC)
def OAMF_BANK1      equ %00001000 ; Bank number; 0,1 (GBC)

def OAMF_PALMASK    equ %00000111 ; Palette (GBC)

def OAMB_PRI        equ 7 ; Priority
def OAMB_YFLIP      equ 6 ; Y flip
def OAMB_XFLIP      equ 5 ; X flip
def OAMB_PAL1       equ 4 ; Palette number; 0,1 (DMG)
def OAMB_BANK1      equ 3 ; Bank number; 0,1 (GBC)


; Deprecated constants. Please avoid using.

def IEF_LCDC   equ %00000010 ; LCDC (see STAT)
def _VRAM8000  equ _VRAM
def _VRAM8800  equ _VRAM+$800
def _VRAM9000  equ _VRAM+$1000
def CART_SRAM_2KB   equ 1 ; 1 incomplete bank


    endc ;HARDWARE_INC
