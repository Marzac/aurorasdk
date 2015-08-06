/*
 * File:   bluetooth.s
 * Author: Marzac (Frédéric Meslin)
 * Date:   20/06/15
 * Brief:  aurora: bluetooth driver
  
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

/** Global functions */
.global _blueInit
.global _blueForceInit
.global _blueUpdate
.global _blueReceive
.global _blueState

/** External functions */
.extern writeRXChar
.extern bootParseLine
.extern _delayms
.extern _delay100ms
.extern _delays

/******************************************************************************/
.extern _blueDefaultName
.extern _blueDefaultPass

/******************************************************************************/
.section .boot, code
/** Bluetooth AT commands */
blueATReset:		.asciz	"AT+RESET\r\n"
blueATMaster:		.asciz	"AT+ROLE=1\r\n"
blueATSlave:		.asciz	"AT+ROLE=0\r\n"
blueATName:			.asciz	"AT+NAME="
blueATPassword:		.asciz	"AT+PSWD="
blueATBaudrate:		.asciz	"AT+UART="
blueATEOL:			.asciz	"\r\n"

/** Bluetooth configuration */
blueBootBaudrate:	.asciz	"230400,0,0"

/** Bluetooth supported baudrates */
.equ BLUE_230400,	#75			; 70MHz, BRGH = 1, 75 = 70e6 / (4 * 230400) - 1
.equ BLUE_38400,	#455		; 70MHz, BRGH = 1, 455 = 70e6 / (4 * 38400) - 1

/** Bluetooth module state */
.equ BLUE_READY,	#0			; Bluetooth is ready (bit)
.equ BLUE_USART,	#1			; Bluetooth USART is enabled (bit)
.equ BLUE_AT,		#2			; Bluetooth is in AT mode (bit)

blueInitTable:
.long   fnSetATMode1
.long   fnDummy
.long   fnDummy
.long   fnDummy
.long   fnDummy
.long   fnDummy
.long   fnDummy
.long   fnDummy
.long   fnSetATMode2
.long	fnATReset
.long   fnDummy
.long   fnDummy
.long   fnDummy
.long	fnATSetSlave
.long	fnATSetName
.long	fnATSetPassword
.long	fnATSetBaudrate
.long   fnSetComMode1
.long   fnDummy
.long   fnDummy
.long   fnDummy
.long   fnDummy
.long   fnDummy
.long   fnDummy
.long   fnDummy
.long   fnSetComMode2
blueInitTableEnd:
.long   0

.section .nbss, bss, near
_blueState:			.space 2	; Bluetooth state
_blueSequence:		.space 2	; Bluetooth initialisation sequence

.section .boot, code
/******************************************************************************/
; void blueInit()
; Start configuration sequence
; return nothing
_blueInit:
clr _blueState
clr _blueSequence
return

; void blueSkip()
; Attend to skip configuration sequence
; return nothing
_blueForceInit:
btss BLUERESET_PORT, #BLUERESET_PIN		; check if in reset
bra 2f
btsc BLUEAT_PORT, #BLUEAT_PIN			; check if in AT mode
bra 2f
1:
push w0
clr U2MODE								; initialise UART 2
clr U2STA
mov #BLUE_230400, w0					; set communication baudrate
mov w0, U2BRG
bset U2MODE, #BRGH						; set high baudrate mode
bset U2MODE, #UARTEN					; enable the UART
bset U2STA, #UTXEN						; enable transmission
mov #BLUE_READY | #BLUE_USART, w0
mov w0, _blueState
mov (#blueInitTableEnd - #blueInitTable) / #4, w0
mov w0, _blueSequence
pop w0
return
2:
clr _blueState
clr _blueSequence
return

/******************************************************************************/
; void blueUpdate()
; Initialise bluetooth step by step
; return nothing
_blueUpdate:
push w0
push w1
push w2
mov #edspage(blueInitTable), w0
movpag w0, DSRPAG
mov #edsoffset(blueInitTable), w0
mov _blueSequence, w1
sl w1, #2, w1
add w0, w1, w2
mov [w2], w0
mov [w2+#2], w1
ior w0, w1, w2
bra Z, 1f
call.l w0
mov _blueSequence, w0
inc w0, w0
mov w0, _blueSequence
1:
pop w2
pop w1
pop w0
return

/******************************************************************************/
; void blueReceive()
; Receive and process UART2 data
; return nothing
_blueReceive:
push w0
push w1
btsc U2STA, #FERR							; Skip if error
bra 3f
btss U2STA, #URXDA							; Skip if no data
bra 3f
mov U2RXREG, w0								; Get character
btsc _blueState, #BLUE_AT					; Skip if in AT mode
bra 3f
cp w0, #'\r'								; Detect any \r received
bra Z, 2f									; Parse if \r received
cp w0, #'\n'								; Detect any \n received
bra Z, 2f									; Parse if \n received
1:
call writeRXChar							; Store character
bclr U2MODE, #OERR							; Clear overrun flag
pop w1
pop w0
return
2:
call bootParseLine							; Parse the line
3:
bclr U2MODE, #OERR							; Clear overrun flag
pop w1
pop w0
return

/******************************************************************************/
; void fnSetATMode()
; Set the bluetooth module in AT mode
; return nothing
fnSetATMode1:
push w0
clr _blueState							; clear bluetooth state
bclr BLUERESET_LAT, #BLUERESET_PIN		; disable bluetooth module
bset BLUEAT_LAT, #BLUEAT_PIN			; switch to AT mode
clr U2MODE								; initialise UART 2
clr U2STA
mov #BLUE_38400, w0						; set default baudrate
mov w0, U2BRG
bset U2MODE, #BRGH						; set high baudrate mode
bset U2MODE, #UARTEN					; enable the UART
bset U2STA, #UTXEN						; enable transmission
call _delay10ms							; wait 10 ms
bset BLUERESET_LAT, #BLUERESET_PIN		; enable bluetooth module
pop w0
return

fnSetATMode2:
bset _blueState, #BLUE_USART			; set bluetooth state
bset _blueState, #BLUE_AT
return

/******************************************************************************/
; void fnDummy()
; Do nothing this turn
fnDummy:
return

; void fnATReset()
; Reset the module configuration
fnATReset:
mov #edspage(blueATReset), w0			; reset configuration
movpag w0, DSRPAG
mov #edsoffset(blueATReset), w0
call _blueSendString
return

; void fnATSetSlave()
; Set slave configuration
fnATSetSlave:
mov #edspage(blueATSlave), w0			; configure in slave mode
movpag w0, DSRPAG
mov #edsoffset(blueATSlave), w0
call _blueSendString
return

; void fnATSetName()
; Set a new name to the module
fnATSetName:
mov #edspage(blueATName), w0			; set device name
movpag w0, DSRPAG
mov #edsoffset(blueATName), w0
call _blueSendString
mov #edspage(_blueDefaultName), w0
movpag w0, DSRPAG
mov #edsoffset(_blueDefaultName), w0
call _blueSendString
mov #edspage(blueATEOL), w0
movpag w0, DSRPAG
mov #edsoffset(blueATEOL), w0
call _blueSendString
return

; void fnATSetPassword()
; Set a new password to the module
fnATSetPassword:
mov #edspage(blueATPassword), w0		; set device password
movpag w0, DSRPAG
mov #edsoffset(blueATPassword), w0
call _blueSendString
mov #edspage(_blueDefaultPass), w0
movpag w0, DSRPAG
mov #edsoffset(_blueDefaultPass), w0
call _blueSendString
mov #edspage(blueATEOL), w0
movpag w0, DSRPAG
mov #edsoffset(blueATEOL), w0
call _blueSendString
return

; void fnATSetBaudrate()
; Set the serial baudrate
fnATSetBaudrate:
mov #edspage(blueATBaudrate), w0		; set communication baudrate
movpag w0, DSRPAG
mov #edsoffset(blueATBaudrate), w0
call _blueSendString
mov #edspage(blueBootBaudrate), w0
movpag w0, DSRPAG
mov #edsoffset(blueBootBaudrate), w0
call _blueSendString
mov #edspage(blueATEOL), w0
movpag w0, DSRPAG
mov #edsoffset(blueATEOL), w0
call _blueSendString
return

/******************************************************************************/
; void fnSetComMode()
; Set the bluetooth module in communication mode
fnSetComMode1:
push w0
clr _blueState							; clear bluetooth state
bclr BLUERESET_LAT, #BLUERESET_PIN		; disable bluetooth module
bclr BLUEAT_LAT, #BLUEAT_PIN			; switch to communication mode
clr U2MODE								; initialise UART 2
clr U2STA
mov #BLUE_230400, w0					; set communication baudrate
mov w0, U2BRG
bset U2MODE, #BRGH						; set high baudrate mode
bset U2MODE, #UARTEN					; enable the UART
bset U2STA, #UTXEN						; enable transmission
call _delay10ms							; wait 10 ms
bset BLUERESET_LAT, #BLUERESET_PIN		; enable bluetooth module
pop w0
return

fnSetComMode2:
bset _blueState, #BLUE_USART			; set bluetooth state
bset _blueState, #BLUE_READY
return

/******************************************************************************/
; void blueSendString(const char * string)
; Send a string to bluetooth module
_blueSendString:
push w1
push w2
clr w1
clr w2
1:
mov.b [w0++], w2		; load string character
cpbeq w2, w1, 3f		; check if end of string
2:
btsc U2STA, #UTXBF		; wait for UART2
bra 2b
mov w2, U2TXREG
mov U2RXREG, w2
bra 1b
3:
pop w2
pop w1
return

.end
