/*
 * File:   pads.s
 * Author: Marzac, (c) Frederic Meslin 2013 - 2015
 * Date:   15/06/15
 * Brief:  aurora : gamepads routines
 
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

; Gamepads exported functions
.global _padsPower
.global _padsRead


/******************************************************************************/
.equ GPS_MASK,		(#1 << #GPS0_PIN) | (#1 << #GPS1_PIN)
.equ GP_MASK,		(#1 << #GP0_PIN) | (#1 << #GP1_PIN) | (#1 << #GP2_PIN) | (#1 << #GP3_PIN) | (#1 << #GP4_PIN) | (#1 << #GP5_PIN)

.text
/******************************************************************************/
; int padsRead(int pad, int group)
; Read one gamepad button status
; param[in] w0 pad index (0 to 3)
; param[in] w1 group of buttons (0 : UP/DW/LF/RG/B/C, 1 : A/START)
; return buttons state
; Registers:
; w2 port read / write
; w3 bit masks
_padsRead:
push w2
push w3
btsc w1, #0					; skip if group A
bclr LATA, #GPSELECT_PIN	; set group B
btss w1, #0					; skip if group B
bset LATA, #GPSELECT_PIN	; set group A
and #3, w0					; restrict pad index
sl w0, #GPS0_PIN, w0		; prepare mux position
mov ~#GPS_MASK, w3			; load mask
mov LATD, w2				; load mux position
and w2, w3, w2
ior w2, w0, w2
mov w2, LATD				; set mux position
repeat #69					; waste 1us before reading
nop
mov PORTB, w2				; get gamepad state
mov #GP_MASK, w3			; load buttons mask
and w2, w3, w0				; only keep buttons state
lsr w0, #GP0_PIN, w0
com w0, w0					; complement the result
pop w3
pop w2
return

; int padsPower(int enable)
; Enable power for pads
; param[in] w0 power state
; return nothing
_padsPower:
bset LATE, #GPPOWER_PIN		; set power on
btss w0, #0					; skip if power on
bclr LATE, #GPPOWER_PIN		; set power off
return

.end
