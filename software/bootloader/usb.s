/*
 * File:   usb.s
 * Author: Marzac (Frédéric Meslin)
 * Date:   21/06/15
 * Brief:  aurora: usb driver
 
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

.include "aurora.inc"
.include "interrupts.inc"

.global _usbInit
.global _usbReceive

.extern writeRXChar
.extern bootParseLine

/******************************************************************************/
.equ USB_230400,	#75					; 70MHz, BRGH = 1, 75 = 70e6 / (4 * 230400) - 1

.section .boot, code
/******************************************************************************/
; void usbInit()
; Configure UART1 (associated with USB) for transfer
; return nothing
; Registers :
; w0 temporary
; w1 temporary
; w2 temporary
_usbInit:
push w0
push w1
clr U1MODE
clr U1STA
mov #USB_230400, w0						; fixed baudrate: 230400
mov w0, U1BRG
bset U1MODE, #BRGH						; set high baudrate mode
bset U1MODE, #UARTEN					; enable UART module
bset U1STA, #UTXEN						; enable TX mode
pop w1
pop w0
return

; void usbReceive()
; Receive and process UART1 data
; return nothing
_usbReceive:
push w0
push w1
btsc U1STA, #FERR							; Skip if error
bra 3f
btss U1STA, #URXDA							; Skip if no data
bra 3f
mov U1RXREG, w0								; Get character
cp w0, #'\r'								; Detect any \r received
bra Z, 2f									; Parse if \r received
cp w0, #'\n'								; Detect any \n received
bra Z, 2f									; Parse if \n received
1:
call writeRXChar							; Store character
bclr U1MODE, #OERR							; Clear overrun flag
pop w1
pop w0
return
2:
call bootParseLine							; Parse the line
3:
bclr U1MODE, #OERR							; Clear overrun flag
pop w1
pop w0
return

.end
