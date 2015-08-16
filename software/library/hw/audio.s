/*
 * File:   audio.s
 * Author: Marzac, (c) Frederic Meslin 2013 - 2015
 * Date:   03/01/15
 * Brief:  aurora : RAW & PCM audio + small synthesizer
 *
 * This module makes use of: timer4, OC1, OC2, OC3, DMA2 and DMA3 peripherals
 *
 * TODO: use the flags accurately to reduce computing
 
  The MIT License (MIT)

  Copyright (c) 2013-2015 Frédéric Meslin
  Email: fredericmeslin@hotmail.com
  Website: www.fredslab.net
  Twitter: @marzacdev

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
  
 */

/******************************************************************************/
.include "aurora.inc"

; Exported PCM audio functions
.global _pcmAudioInit
.global _pcmAudioPlay
.global _pcmAudioStop
.global _pcmAudioUpdate

; Exported RAW audio functions
.global _rawAudioInit
.global _rawAudioStart
.global _rawAudioStop
.global _rawAudioPitch
.global _rawAudioPitchMod
.global _rawAudioPW
.global _rawAudioPWMod
.global _rawAudioUpdate

/******************************************************************************/
; Audio constants
.equ SAMPLE_FRQ,			#17010
.equ BUFFER_SIZE,			#320			; around 18.8 ms @ 17010 kHz
.equ T4_PRESCALER,			#64				; pre-divide CPU_FCY by 64
.equ BASE_NOTE,				f020.6017223071	; BASE_NOTE = MIDI note 16, E-4
.equ BASE_WAVELEN,			#53090			; CPU_FCY / (BASE_NOTE * T4_PRESCALER)

; Raw channel structure
.equ RAW_STR_SIZE,			#22				; raw channel structure size (bytes)
.equ RAW_PITCH,				#0				; attribute: pitch
.equ RAW_PITCH_SPEED,		#2				; attribute: pitch mod speed
.equ RAW_PITCH_AMOUNT,		#4				; attribute: pitch mod amount
.equ RAW_PW,				#6				; attribute: pw (pulse width)
.equ RAW_PW_SPEED,			#8				; attribute: pw mod. speed
.equ RAW_PW_AMOUNT,			#10				; attribute: pw mod. amount
.equ RAW_PITCH_CNT,			#12				; realtime: pitch mod. counter
.equ RAW_PW_CNT,			#14				; realtime: pw mod. counter
.equ RAW_CUR_PITCH,			#16				; realtime: current pitch
.equ RAW_CUR_PW,			#18				; realtime: current pw
.equ RAW_FLAGS,				#20				; realtime: flags (update)

; Raw special flags
.equ FLAG_WILL_START,		#0				; channel will start
.equ FLAG_WILL_STOP,		#1				; channel will stop
.equ FLAG_UPDATE_OC,		#4				; output compare needs update
.equ FLAG_UPDATE_PITCHMOD,	#5				; pitch modulation needs update
.equ FLAG_UPDATE_PWMOD,		#6				; pulse width modulation needs update

.equ MASK_STARTSTOP,		(#1 << FLAG_WILL_START) | (#1 << FLAG_WILL_STOP)
.equ MASK_UPDATE,			(#1 << FLAG_UPDATE_OC) | (#1 << FLAG_UPDATE_PITCHMOD) | (#1 << FLAG_UPDATE_PWMOD)

; Output compare configuration
; T4 clock source + edge aligned PWM
.equ OC_OCxCON1_ON,			(#1 << OCTSEL1) | (#1 << OCM2) | (#1 << OCM1)	; 0x0806
.equ OC_OCxCON1_OFF,		(#1 << OCTSEL1)
; Synchronise on OCxRS event
.equ OC_OCxCON2,			#0x001F

/******************************************************************************/
.pushsection .bss
rawChannels:	.space	RAW_STR_SIZE * #3	; raw channel objects
.popsection

/******************************************************************************/
.section .const, psv
OCxR:
.word OC1R
.word OC2R
.word OC3R

OCxRS:
.word OC1RS
.word OC2RS
.word OC3RS

OCxCON1:
.word OC1CON1
.word OC2CON1
.word OC3CON1

OCxCON2:
.word OC1CON2
.word OC2CON2
.word OC3CON2

expTable:
.word 32768, 34716, 36781, 38968
.word 41285, 43740, 46341, 49097
.word 52016, 55109, 58386, 61858
.word 65535

.text
/******************************************************************************/
; void rawAudioInit(int channel)
; return nothing
_rawAudioInit:
push w0
push w1
push w2
push w3
push w4
push w5

; Set timer 4 prescaler
mov #0x0020, w1						; /64 prescaler
mov w1, T4CON

; Initialise channel object
mov #rawChannels, w1				; load channels table
mulw.uu, w0, #RAW_STR_SIZE, w2		; compute the pointer
add w2, w1, w1
clr w2
mov #0x7fff, w3
mov w2, [w1+RAW_PITCH]				; initialise pitch
mov w2, [w1+RAW_PITCH_SPEED]		; initialise pitch mod. speed
mov w2, [w1+RAW_PITCH_AMOUNT]		; initialise pitch mod. amount
mov w3, [w1+RAW_PW]					; initialise pw
mov w2, [w1+RAW_PW_SPEED]			; initialise pw mod. speed
mov w2, [w1+RAW_PW_AMOUNT]			; initialise pw mod. amount
mov w2, [w1+RAW_PITCH_CNT]
mov w2, [w1+RAW_PW_CNT]
mov w2, [w1+RAW_CUR_PITCH]
mov w2, [w1+RAW_CUR_PW]
mov w2, [w1+RAW_FLAGS]				; initialise flags

; Get channel registers adresses
sl w0, #1, w0						; multiply w0 by 2
mov DSRPAG, w5						; save EDS page
mov #psvpage(OCxR), w1				; load constants page
movpag w1, DSRPAG
mov #psvoffset(OCxR), w1			; load constant offset
mov [w1+w0], w1						; load OCxR register address
mov #psvoffset(OCxRS), w2			; load constant offset
mov [w2+w0], w2						; load OCxRS register address
mov #psvoffset(OCxCON1), w3			; load constant offset
mov [w3+w0], w3						; load OCxCON1 register address
mov #psvoffset(OCxCON2), w4			; load constant offset
mov [w4+w0], w4						; load OCxCON2 register address
movpag w5, DSRPAG					; restore EDS page

; Configure output compare module
mov #0x7FFF, w0						; OCxR = 0x7FFF
mov w0, [w1]
mov #0xFFFF, w0						; OCxRS = 0x7FFF
mov w0, [w2]
mov #OC_OCxCON1_OFF, w0				; T4 clock source + edge aligned PWM
mov w0, [w3]
mov #OC_OCxCON2, w0					; synchronise on OCxRS event
mov w0, [w4]
bset T4CON, #TON					; start the timer

pop w5
pop w4
pop w3
pop w2
pop w1
pop w0
return

/******************************************************************************/
; void rawAudioStart(int channel)
; Start sound generation on specified channel
; param[in] w0 channel index
_rawAudioStart:
push w1
push w2
mov #rawChannels, w1				; load channels table
mulw.uu, w0, #RAW_STR_SIZE, w2		; compute the pointer
add w2, w1, w2
mov [w2+#RAW_FLAGS], w1				; load channel flags
bset w1, #FLAG_WILL_START			; set the start flag
mov w1, [w2+#RAW_FLAGS]
pop w2
pop w1
return

; void rawAudioStop(int channel)
; Stop sound generation on specified channel
; param[in] w0 channel index
_rawAudioStop:
push w1
push w2
mov #rawChannels, w1				; load channels table
mulw.uu, w0, #RAW_STR_SIZE, w2		; compute the pointer
add w2, w1, w2
mov [w2+#RAW_FLAGS], w1				; load channel flags
bset w1, #FLAG_WILL_STOP			; set the stop flag
mov w1, [w2+#RAW_FLAGS]
pop w2
pop w1
return

/******************************************************************************/
; void rawAudioPitch(int channel, int pitch)
; Set channel base pitch
; param[in] w0 channel index
; param[in] w1 pulse width ratio
_rawAudioPitch:
push w2
push w3
mov #rawChannels, w3				; load channels table
mulw.uu, w0, #RAW_STR_SIZE, w2		; compute the pointer
add w2, w3, w2
mov w1, [w2+#RAW_PITCH]				; save the pitch
mov [w2+#RAW_FLAGS], w3				; signal an OC update
bset w3, #FLAG_UPDATE_OC
mov w3, [w2+#RAW_FLAGS]
pop w3
pop w2
return

; void rawAudioPitchMod(int channel, int speed, int amount)
; Configure a pitch modulation
; param[in] w0 channel index
; param[in] w1 speed of modulation
; param[in] w2 amount of modulation
; return nothing
_rawAudioPitchMod:
push w3
push w4
mov #rawChannels, w3				; load channels table
mulw.uu, w0, #RAW_STR_SIZE, w4		; compute the pointer
add w4, w3, w3
mov w1, [w3+#RAW_PITCH_SPEED]		; save the modulation speed
mov w2, [w3+#RAW_PITCH_AMOUNT]		; save the modulation amount
mov [w3+#RAW_FLAGS], w4				; load and mask flags
bclr w4, #FLAG_UPDATE_PITCHMOD
cp0 w2
bra Z, 1f
bset w4, #FLAG_UPDATE_PITCHMOD		; signal a pitch modulation
1:
mov w4, [w3+#RAW_FLAGS]				; store the flags
pop w4
pop w3
return

/******************************************************************************/
; void rawAudioPW(int channel, int pw)
; Set channel base pulse width ratio
; param[in] w0 channel index
; param[in] w1 pulse width ratio
_rawAudioPW:
push w2
push w3
mov #rawChannels, w3				; load channels table
mulw.uu, w0, #RAW_STR_SIZE, w2		; compute the pointer
add w2, w3, w2
mov w1, [w2+#RAW_PW]				; save the pulse width
mov [w2+#RAW_FLAGS], w3				; signal an OC update
bset w3, #FLAG_UPDATE_OC
mov w3, [w2+#RAW_FLAGS]
pop w3
pop w2
return

; void rawAudioPWMod(int channel, int speed, int amount)
; Configure a sine pulse width modulation
; param[in] w0 channel index
; param[in] w1 speed of modulation
; param[in] w2 amount of modulation
; return nothing
_rawAudioPWMod:
push w3
push w4
mov #rawChannels, w3				; load channels table
mulw.uu, w0, #RAW_STR_SIZE, w4		; compute the pointer
add w4, w3, w3
mov w1, [w3+#RAW_PW_SPEED]			; save the modulation speed
mov w2, [w3+#RAW_PW_AMOUNT]			; save the modulation amount
mov [w3+#RAW_FLAGS], w4				; load and mask flags
bclr w4, #FLAG_UPDATE_PWMOD
cp0 w2
bra Z, 1f
bset w4, #FLAG_UPDATE_PWMOD			; signal a pulse width modulation
1:
mov w4, [w3+#RAW_FLAGS]
pop w4
pop w3
return

/******************************************************************************/
; void rawAudioUpdate()
; Update channels modulations and configurations
; Should be called periodically (every frame)
; return nothing
_rawAudioUpdate:
push w0
clr w0								; load channel index
1:
call rawUpdateMod					; update channel modulations
call rawUpdateOC					; update output compare
call rawUpdateStatus				; update channel status
inc w0, w0
cp w0, #3
bra NZ, 1b
pop w0
return

/******************************************************************************/
; void rawUpdateMod(int channel)
; Update channel modulations
; param[in] w0 channel index
; return nothing
rawUpdateMod:
push w0
push w1
push w2
push w3
push w4
push w5

; Get the channel object
mov #rawChannels, w1				; load channels table
mulw.uu, w0, #RAW_STR_SIZE, w2		; compute the pointer
add w1, w2, w1

; Compute the PW modulation
mov [w1+#RAW_PW_CNT], w2			; load the counter
mov [w1+#RAW_PW_SPEED], w3			; load the mod. speed
add w2, w3, w2						; t += speed;
mov w2, [w1+#RAW_PW_CNT]			; save the counter
mov w2, w4							; a = abs(t)
btsc w4, #15
neg w4, w4
mov #0x7fff, w3						; v = (t * (0x7fff - a)) >> 13;
sub w3, w4, w4
mul.ss w2, w4, w4
lsr w4, #13, w4
sl w5, #3, w5
ior w4, w5, w4

; Apply the PW modulation
mov [w1+#RAW_PW], w2				; load the base pulse width
mov [w1+#RAW_PW_AMOUNT], w3			; load the mod. amount
mul.ss w4, w3, w4					; m = (v * s) >> 15
lsr w4, #14, w4
sl w5, #2, w3
ior w4, w3, w4
asr w5, #14, w5
add w4, w2, w4						; r = p + m
addc w5, #0, w5
cp0 w5								; saturate result
bra z, 1f
mov #0xffff, w4						; top limit
btsc w5, #15
mov #0x0000, w4						; bottom limit
1:
mov w4, [w1+#RAW_CUR_PW]			; save the pulse width

; Compute the pitch modulation
mov [w1+#RAW_PITCH_CNT], w2			; load the counter
mov [w1+#RAW_PITCH_SPEED], w3		; load the mod. speed
add w2, w3, w2						; t += speed;
mov w2, [w1+#RAW_PITCH_CNT]			; save the counter
mov w2, w4							; a = abs(t)
btsc w4, #15
neg w4, w4
mov #0x7fff, w3						; v = (t * (0x7fff - a)) >> 13;
sub w3, w4, w4
mul.ss w2, w4, w4
lsr w4, #13, w4
sl w5, #3, w5
ior w4, w5, w4

; Apply the pitch modulation
mov [w1+#RAW_PITCH], w2				; load the base pitch
mov [w1+#RAW_PITCH_AMOUNT], w3		; load the mod. amount
mul.ss w4, w3, w4					; m = (v * s) >> 15
lsr w4, #14, w4
sl w5, #2, w3
ior w4, w3, w4
asr w5, #14, w5
add w4, w2, w4						; r = p + m
addc w5, #0, w5
cp0 w5								; saturate result
bra z, 1f
mov #0xffff, w4						; top limit
btsc w5, #15
mov #0x0000, w4						; bottom limit
1:
mov w4, [w1+#RAW_CUR_PITCH]			; save the pitch

pop w5
pop w4
pop w3
pop w2
pop w1
pop w0
return

; void rawUpdateOC(int channel)
; Update channel output compare peripheral
; param[in] w0 channel index
; return nothing
rawUpdateOC:
push w0
push w1
push w2
push w3
push w4
push w5
push w6

; Get the channel object
mov w0, w6							; preserve channel number
mov #rawChannels, w1				; load channels table
mulw.uu, w6, #RAW_STR_SIZE, w2		; compute the pointer
add w1, w2, w1

; Compute the wave length
mov [w1+#RAW_CUR_PITCH], w0			; load current pitch value
call noteToWL						; compute wave length
mov #BASE_WAVELEN, w2				; load base wave length
mul.uu w2, w0, w2					; apply exponential
lsr w2, #15, w2						; shift the result
sl w3, #1, w3
ior w2, w3, w0						; get output compare value

; Get registers adresses
sl w6, #1, w6						; multiply w6 by 2
mov DSRPAG, w3						; save EDS page
mov #psvpage(OCxR), w4				; load constants page
movpag w4, DSRPAG
mov #psvoffset(OCxR), w4			; load constant offset
mov [w4+w6], w4						; load OCxR register address
mov #psvoffset(OCxRS), w5			; load constant offset
mov [w5+w6], w5						; load OCxRS register address
movpag w3, DSRPAG					; restore EDS page

; Configure output compare
mov [w1+#RAW_CUR_PW], w2			; load current pulse width
mul.uu w2, w0, w2					; multiply pw by modulation
mov w3, [w4]						; set output compare configuration
mov w0, [w5]

pop w6
pop w5
pop w4
pop w3
pop w2
pop w1
pop w0
return

; void rawUpdateStatus(int channel)
; Update channel status
; param[in] w0 channel index
; return nothing
rawUpdateStatus:
push w1
push w2
push w3
push w4
mov #rawChannels, w1				; load channels table
mulw.uu, w0, #RAW_STR_SIZE, w2		; compute the pointer
add w1, w2, w1
mov DSRPAG, w4						; save EDS page
mov #psvpage(OCxCON1), w3			; load constants page
movpag w3, DSRPAG
mov #psvoffset(OCxCON1), w3			; load constant offset
sl w0, #1, w2						; multiply w0 by 2
mov [w3+w2], w3						; load OCxCON1 register address
movpag w4, DSRPAG					; restore EDS page
mov [w1+#RAW_FLAGS], w4				; load the flags
mov #OC_OCxCON1_ON, w2
btsc w4, #FLAG_WILL_START			; check for start
mov w2, [w3]						; start module
bclr w4, #FLAG_WILL_START			; clear the flag
mov #OC_OCxCON1_OFF, w2
btsc w4, #FLAG_WILL_STOP			; check for stop
mov w2, [w3]						; stop module
bclr w4, #FLAG_WILL_STOP			; clear the flag
mov w4, [w1+#RAW_FLAGS]				; store the flags
pop w4
pop w3
pop w2
pop w1
return

/******************************************************************************/
; void pcmAudioInit(int channel)
; Initialise the specified channel for samples playback
; param[in] w0 channel index 
; return nothing
_pcmAudioInit:
push w0
push w1
pop w1
pop w0
return

; void pcmAudioStart(int channel, const FlashPage page, const FlashPtr buffer, int length)
; Play a given samples buffer through the specified channel
; param[in] w0 channel index 
; param[in] w1 buffer page in flash
; param[in] w2 buffer pointer in flash
; param[in] w3 length of buffer in samples
; return nothing
pcmAudioStart:
return

; void pcmAudioStop(int channel)
; Stop the samples playback
; param[in] w0 channel index
; return nothing
pcmAudioStop:
return

; void pcmAudioUpdate()
; Update the audio playback
; return nothing
pcmAudioUpdate:
return

/******************************************************************************/
; int noteToWL(int note)
; Compute the wave length associated to a MIDI (alike) note
; param[in] w0 note number (from 0 to 127, 8 bits fractionnal part)
; return the associated wave length
;w0: n
;w1: f
;w2: o
;w3: s
noteToWL:
push w1
push w2
push w3
push w4
push w5
push w6
push w7

mov #256 * #120, w1					; s16 n = 256 * 120 - value;
sub w1, w0, w0
mov #0xAAAB, w1						; s16 o = (n * 0xAAAB) >> (10 + 17); (divide by 3)
mul.su w0, w1, w2
asr w3, #11, w2
mov #256 * #12, w1					; u16 s = n - o * 12 * 256;
mulw.su w2, w1, w4
sub w0, w4, w3
mov #0xFF, w1						; u16 f = s & 0xFF;
and w3, w1, w1
lsr w3, #8, w3						; s >>= 8;
mov DSRPAG, w0						; save EDS page
mov #psvpage(expTable), w4			; load constants page
movpag w4, DSRPAG
mov #psvoffset(expTable), w4
sl w3, #1, w3
mov [w4+w3], w5						; u32 d = (expTab[s+1] - expTab[s]) * f;
inc2 w4, w4
mov [w4+w3], w6
sub w6, w5, w6
mul.uu w6, w1, w6
movpag w0, DSRPAG					; restore EDS page
lsr w6, #8, w6						; u16 v = d >> 8;
sl w7, #8, w7
ior w6, w7, w6
add w6, w5, w6						; v += expTab[s];
mov #10, w1							; v >>= 10 - o;
sub w1, w2, w1
lsr w6, w1, w0

pop w7
pop w6
pop w5
pop w4
pop w3
pop w2
pop w1
return

/*
u16 midiNoteToWL(u16 value)
{
    s16 n = 256 * 120 - value;
    s16 o = (n * 43691) >> (10 + 17);
    u16 s = n - o * 12 * 256;
    u16 f = s & 0xFF;
    s >>= 8;
    u32 d = (expTab[s+1] - expTab[s]) * f;
    u16 v = d >> 8;
    v += expTab[s];
    v >>= 10 - o;
    return v;
}
*/