/*
 * File:   bootloader.s
 * Author: Marzac (Frédéric Meslin)
 * Date:   15/06/15
 * Brief:  aurora: serial (USB + Bluetooth) bootloader
 
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

; Global symbols
.global _bootWOBlue
.global _bootWBlue

.global bootParseLine
.global writeRXChar

; External symbols
.extern _flashPageCompare
.extern _flashPageBurn
.extern _flashPageErase
.extern _flashPageRead

.extern _intInit
.extern _intInstallVector

.extern _blueInit
.extern _blueUpdate
.extern _blueReceive
.extern _blueState

.extern _usbInit
.extern _usbReceive

.extern _padsPower
.extern _padsRead

/******************************************************************************/
; Program memory layout
.equ __CODE_BASE,		#0x001000
.equ __CODE_LENGTH,		#0x050000
.equ __BOOT_BASE,		#0x051000
.equ __BOOT_LENGTH,		#0x004000

/******************************************************************************/
; Bluetooth state bits
.equ BLUE_READY,	#0			; Bluetooth is ready (bit)
.equ BLUE_USART,	#1			; Bluetooth USART is enabled (bit)
.equ BLUE_AT,		#2			; Bluetooth is in AT mode (bit)

/******************************************************************************/
; USART bitmasks
.equ ABAUD_MSK,				(#1 << #ABAUD)
.equ BRGH_MSK,				(#1 << #BRGH)

.equ UTXANY_MSK,			#0
.equ UTXSHIFTEMPTY_MSK,		(#1 << #UTXISEL0)
.equ UTXBUFFEREMPTY_MSK,	(#1 << #UTXISEL1)

.equ URXANY_MSK,			#0
.equ URX3CHARS_MSK,			(#1 << #URXISEL1)
.equ URX4CHARS_MSK,			(#1 << #URXISEL1) | (#1 << #URXISEL0)

; RX & TX buffers
.equ RXBUF_SIZE,			#256					; Size of reception buffer
.equ TXBUF_SIZE,			#256					; Size of transmission buffer

; Hex-files constants
.equ RC_DATA,				#0x0					; Data hex line
.equ RC_EOF,				#0x1					; End Of File hex line
.equ RC_ESA,				#0x2					; Extended address hex line
.equ RC_ELA,				#0x4					; Extended linear address hex line

; Flash programming constants
.equ PAGE_SIZE,				#4096					; Flash page size (in bytes)
.equ PAGE_BOOT,				#162
.equ PAGE_PROG,				#2
.equ PAGE_NONE,				#0xFFFF					; No page selected

.equ FLASH_MIN_LSW,			__CODE_BASE	& 0xFFFF	; Minimal address that can be written
.equ FLASH_MIN_HSW,			__CODE_BASE >> 16		; Minimal address that can be written
.equ FLASH_MAX_LSW,			__BOOT_BASE	& 0xFFFF	; Maximal address that can be written
.equ FLASH_MAX_HSW,			__BOOT_BASE >> 16		; Maximal address that can be written

/******************************************************************************/
; Serial communication
.section .nbss, bss, near
modified:			.space 2				; Modified flag
rxRd:				.space 2				; Read pointer
rxEOL:				.space 2				; End Of Line pointer
rxWr:				.space 2				; Write pointer

; Flash temporary page
MSWBuffer:			.space 2				; Most Significant Word address
LSWBuffer:			.space 2				; Low Significant Word address
MSWAddr:			.space 2				; Most Significant Word address
LSWAddr:			.space 2				; Low Significant Word address

.section .bss
; Data buffers
rxBuffer:			.space RXBUF_SIZE		; Reception buffer (USB & Bluetooth)
pageBuffer:			.space PAGE_SIZE		; Page data buffer

/******************************************************************************/
.section .boot, code
; Serial commands
cmdWhoAreYou:		.asciz	"WAY"
cmdReboot:			.asciz	"REBOOT"
cmdErase:			.asciz	"ERASE"
cmdVersion:			.asciz	"VERSION";
cmdLED1:			.asciz	"LED1";
cmdLED2:			.asciz	"LED2";
cmdRun:				.asciz	"RUN";

; Serial informations
auroraBoot:			.asciz	"AURORA-BOOT\n"
auroraSoft:			.asciz	"AURORA-SOFT\n"
bootVersion:		.asciz	"BOOT: 1.10 HW: 1.3\n"

; Acknowledge and errors
.equ bootAck,		'A'
.equ bootErr,		'E'
.equ bootSum,		'S'
.equ bootUnknown,	'U'

.section .boot, code
/******************************************************************************/
; void bootWOBlue()
; Start bootloader and initialise bluetooth
; return nothing
_bootWOBlue:
call __bootInit							; Initialise receiver
call _usbInit							; Initialise USB module
call _blueInit							; Initialise Bluetooth module
mov #1, w0								; Enable power
call _padsPower							; Initialise gamepads
bra bootLoop

; void bootWBlue()
; Start bootloader considering bluetooth initialised
; return nothing
_bootWBlue:
call __bootInit							; Initialise receiver
call _usbInit							; Initialise USB module
call _blueForceInit						; Force init state
mov #1, w0								; Enable power
call _padsPower							; Initialise gamepads
bra bootLoop

/******************************************************************************/
__bootInit:
bset LATB, #DEBUG1_PIN					; Set LEDs state
bclr LATB, #DEBUG2_PIN
clr w0
mov w0, rxRd							; Reset RX buffer pointers
mov w0, rxEOL
mov w0, rxWr
mov w0, MSWAddr							; Reset hex-file address
mov w0, LSWAddr
mov w0, modified						; Buffer unmodified
mov #PAGE_NONE, w0						; No current page
mov w0, MSWBuffer
mov w0, LSWBuffer
call pageBufferClean					; Empty page buffer
return

/******************************************************************************/
; void bootLoop()
; Start bootloader and initialise bluetooth
; return nothing
bootLoop:
mov SR, w0								; Enable interrupts
mov #0xFF1F, w1
and w0, w1, w0
mov w0, SR
clr w2									; Init loop counter
clr w3
1:
call _usbReceive						; Poll USB USART
call _blueReceive						; Poll Bluetooth USART
add #1, w2								; Increment counter
addc #0, w3
and w3, #3, w0							; Check counter
ior w2, w0, w0
bra NZ, 1b
call _blueUpdate						; Update bluetooth
mov #0, w0								; Get gamepad state
mov #1, w1
call _padsRead
btsc w0, #4								; Is start pressed?
call bootRun							; Boot the game
and w3, #15, w0							; Check counter
ior w2, w0, w0
bra NZ, 1b
btg LATB, #DEBUG1_PIN					; Blink bootloader LED
btsc _blueState, #BLUE_READY			; Blink bluetooth LED
btg BLUELED_LAT, #BLUELED_PIN
btsc BLUEPAIRED_PORT, #BLUEPAIRED_PIN
bset BLUELED_LAT, #BLUELED_PIN
bra 1b
return

/******************************************************************************/
; void bootRun()
; Start the game in flash
; return nothing
bootRun:
bclr LATB, #DEBUG1_PIN		; Reset LEDs state
bclr LATB, #DEBUG2_PIN
mov SR, w0					; Disable the interrupts
ior #0xE0, w0
mov w0, SR
call __CODE_BASE			; Jump to the game
reset

/******************************************************************************/
; void bootParseLine()
; Interpret the line received
; End of line detected
; Registers :
; w0 temporary
; w1 temporary
bootParseLine:
push w0
push w1
mov rxRd, w1					; Load line begin
mov rxWr, w0					; Load line end
mov w0, rxEOL					; Save end of line
cp w0, w1
bra Z, 3f						; Skip if empty line
mov rxRd, w1					; Load read pointer
call readRXChar					; Read line first character
mov w1, rxRd					; Restore read pointer
cp w0, #':'						; Check if hex file line
bra NZ, 2f						; Jump if not
1:
call hexParseLine				; Parse the hex line
mov rxEOL, w1					; Goto next line
mov w1, rxRd
pop w1
pop w0
return
2:
call cmdParseLine				; Parse the command line
3:
mov rxEOL, w1					; Goto next line
mov w1, rxRd
pop w1
pop w0
return

/******************************************************************************/
; void cmdParseLine()
; Execute a string identified as a command
; return nothing
; Registers :
; w0 temporary
cmdParseLine:
push w0
1: ; COMMAND: Who are you?
mov #edspage(cmdWhoAreYou), w0
movpag w0, DSRPAG
mov #edsoffset(cmdWhoAreYou), w0
call cmdCheck
btss w0, #0
bra 2f
mov #edspage(auroraBoot), w0
movpag w0, DSRPAG
mov #edsoffset(auroraBoot), w0
call sendString
pop w0
return

; COMMAND: Reboot
2:
mov #edspage(cmdReboot), w0
movpag w0, DSRPAG
mov #edsoffset(cmdReboot), w0
call cmdCheck
btss w0, #0
bra 3f
mov #bootAck, w0
call sendChar
reset

; COMMAND: Erase
3:
mov #edspage(cmdErase), w0
movpag w0, DSRPAG
mov #edsoffset(cmdErase), w0
call cmdCheck
btss w0, #0
bra 4f
call chipErase
mov #bootAck, w0
call sendChar
pop w0
return

; COMMAND: Version
4:
mov #edspage(cmdVersion), w0
movpag w0, DSRPAG
mov #edsoffset(cmdVersion), w0
call cmdCheck
btss w0, #0
bra 5f
mov #edspage(bootVersion), w0
movpag w0, DSRPAG
mov #edsoffset(bootVersion), w0
call sendString
pop w0
return

; COMMAND: LED1
5:
mov #edspage(cmdLED1), w0
movpag w0, DSRPAG
mov #edsoffset(cmdLED1), w0
call cmdCheck
btss w0, #0
bra 6f
btg LATB, #DEBUG1_PIN
pop w0
return

; COMMAND: LED2
6:
mov #edspage(cmdLED2), w0
movpag w0, DSRPAG
mov #edsoffset(cmdLED2), w0
call cmdCheck
btss w0, #0
bra 7f
btg LATB, #DEBUG2_PIN
pop w0
return

; COMMAND: RUN
7:
mov #edspage(cmdRun), w0
movpag w0, DSRPAG
mov #edsoffset(cmdRun), w0
call cmdCheck
btss w0, #0
bra 8f
mov #bootAck, w0
call sendChar
call bootRun
reset

; COMMAND: Totally unknown command
8:
mov #bootUnknown, w0
call sendChar
pop w0
return

/******************************************************************************/
; int cmdCheck(const char * cmd)
; Compare received string and command string
; param[in] w0 = pointer to a command
; return 1 if match, 0 else
; Registers :
; w0 temporary
; w1 command character
; w2 command pointer
cmdCheck:
push w1
push w2
mov w0, w2			; Transfer command pointer
mov rxRd, w1		; Preserve read pointer
push w1
bra 2f				; Start the comparison
1:
call readRXChar		; Load buffer character
cp w0, w1			; Check if characters equal
bra NZ, 4f
2:
clr w1				; Clear w1 MSB
mov.b [w2++], w1	; Load command character
cp0 w1				; Check if end of string
bra NZ, 1b
; Comparison succeeded
3:
pop w1				; Restore read pointer
mov w1, rxRd
mov #1, w0			; Return code 1
pop w2
pop w1
return
; Comparison failed
4:
pop w1				; Restore read pointer
mov w1, rxRd
mov #0, w0			; Return code 0
pop w2
pop w1
return

/******************************************************************************/
; void hexParseLine()
; Parse an hex line from reception buffer
; return nothing
; Registers :
; w0 temporary
; w1 number of data bytes
hexParseLine:
push w0
push w1
push w2
mov rxEOL, w1					; Load end of line
mov rxRd, w2					; Load start of line
sub w1, w2, w1					; Compute line length
and #RXBUF_SIZE - #1, w1		; Mask the result
sub #11, w1						; Check minimum line length
bra N, errLine					; Line is shorter than minimum
1:
call readRXChar					; Trash the colon
mov #2, w0						; Ask for a byte
call hexToNum					; Get data length
sl w0, w2						; Get characters length
cp w1, w2						; Check line length
bra LT, errLine					; Line is shorter than required
mov w0, w1						; Preserve data length
call hexCheckLine				; Compute line checksum
cp0 w0							; Check if not zero
bra NZ, sumLine					; Error
btg LATB, #DEBUG2_PIN			; Data valid, toggle LED
mov #4, w0						; Ask for a word
call hexToNum					; Get the relative address
mov w0, LSWAddr					; Save the address
mov #2, w0						; Ask for a byte
call hexToNum					; Get the line type
1:
cp w0, #RC_DATA					; Is a data type ?
bra NZ, 2f						; No
mov w1, w0						; Load data length
call pageBufferWrite
mov #bootAck, w0
call sendChar
pop w2
pop w1
pop w0
return
2:
cp w0, #RC_ELA					; Is an extended linear address type ?
bra NZ, 3f						; No
mov #4, w0						; Ask for a word
call hexToNum					; Get the extended address
mov w0, MSWAddr					; Save for later
mov #bootAck, w0
call sendChar
pop w2
pop w1
pop w0
return
3:
cp w0, #RC_EOF					; Is an end of file type ?
bra NZ, errLine					; No
call pageBufferBurn				; Write last page
mov #bootAck, w0
call sendChar
pop w2
pop w1
pop w0
return
errLine:
mov #bootErr, w0
call sendChar
pop w2
pop w1
pop w0
return
sumLine:
mov #bootSum, w0
call sendChar
pop w2
pop w1
pop w0
return

/******************************************************************************/
; u8 hexCheckLine(u16 nb)
; Compute the checksum of an hex line
; param[in] w0 = number of data bytes in line
; return w0 = checksum (should be zero)
; Registers :
; w0 temporary
; w1 checksum
; w2 loop counter
hexCheckLine:
push w1
push w2
push w3
mov w0, w1			; Include data length in checksum
mov w0, w2			; Load loop counter
add #3, w2			; Add 4 bytes to parse (2 address, 1 type, 1 checksum)
mov rxRd, w3		; Preserve rxRd for the end
do w2, 1f			; For each byte
mov #2, w0			; Ask for a byte
call hexToNum		; Read the byte
1:
add w0, w1, w1		; Add to checksum
and #0xFF, w1		; Clamp the checksum
mov w3, rxRd		; Restore rxRd
mov w1, w0			; Transfer the sum
pop w3
pop w2
pop w1
return				; Return checksum in w0

/******************************************************************************/
; u16 hexToNum(u16 nb)
; Convert a received string in numerical value
; param[in] w0 = number of characters to parse
; return w0 = value
; Registers :
; w0 temporary
; w1 numerical value
; w2 loop counter
hexToNum:
push w1
push w2
clr w1				; Clear the value
dec w0, w2			; Get number of iterations
do w2, 4f			; For each character
call readRXChar		; Read the character
sl w1, #4, w1		; Multiply value by 16
1:
cp w0, #'0'			; If between 0 and 9
bra LT, 2f
cp w0, #'9'
bra GT, 2f
sub #'0', w0		; Get the numerical value
ior w1, w0, w1		; Add the digit
bra 4f
2:
cp w0, #'A'			; If between A and F
bra LT, 3f
cp w0, #'F'
bra GT, 3f
sub #'A', w0		; Get the numerical value
add #10, w0			; Add 10 to it
ior w1, w0, w1		; Add the digit
bra 4f
3:
cp w0, #'a'			; If between a and f
bra LT, 4f
cp w0, #'f'
bra GT, 4f
sub #'a', w0		; Get the numerical value
add #10, w0			; Add 10 to it
ior w1, w0, w1		; Add the digit
4:
nop
mov w1, w0
pop w2
pop w1
return				; Return value in w0

/******************************************************************************/
; void sendChar(char c)
; Send a character on UARTs
; param[in] w0 = character
sendChar:
1:
btsc U1STA, #UTXBF		; Send on UART1
bra 1b
mov w0, U1TXREG
2:
btsc U2STA, #UTXBF		; Send on UART2
bra 2b
mov w0, U2TXREG
return

; void sendString(const char * string)
; Send a string on UARTs
; param[in] w0 = string address
sendString:
push w1
bra 3f					; Start the send
1:
btsc U1STA, #UTXBF		; Send on UART1
bra 1b
mov w1, U1TXREG
2:
btsc U2STA, #UTXBF		; Send on UART2
bra 2b
mov w1, U2TXREG
3:
clr w1					; Clear w1 MSB
mov.b [w0++], w1		; Load string character
cp0 w1					; Check if end of string
bra NZ, 1b
pop w1
return

/******************************************************************************/
; u16 readRXChar()
; Read a character from the reception buffer
; Increments rxRd after reading
; return w0 = character
; Registers :
; w0 temporary
; w1 read pointer
readRXChar:
push w1
push w2
mov #rxBuffer, w2			; Get buffer address
mov rxRd, w1				; Get read pointer
clr w0						; Clear w0 MSB
mov.b [w2+w1], w0			; Get a character
inc w1, w1					; Increment the pointer
and #RXBUF_SIZE - #1, w1	; Mask the result
mov w1, rxRd				; Store the pointer
pop w2
pop w1
return						; Return character in w0

; writeRXChar()
; Write a character in the reception buffer
; Increments rxWr after writting
; param[in] w0 = character
; return nothing
; Registers :
; w0 temporary
; w1 read pointer
writeRXChar:
push w1
push w2
mov #rxBuffer, w1			; Get buffer address
mov rxWr, w2				; Get read pointer
mov.b w0, [w1+w2]			; Store a character
inc w2, w2					; Increment the pointer
and #RXBUF_SIZE - #1, w2	; Mask the result
mov w2, rxWr				; Store the pointer
pop w2
pop w1
return

/******************************************************************************/
; void chipErase()
; Blank the complete chip (excepting bootloader)
; return nothing
; Registers :
; w0 address low significant word
; w1 address high significant word
chipErase:
push w0
push w1
push w2
mov (#PAGE_SIZE * #PAGE_PROG) / #2, w0	; Load first program page
clr w1
mov #PAGE_SIZE / #2, w2					; Load page length
do (#PAGE_BOOT - #PAGE_PROG) - #1, 1f
call _flashPageErase					; Erase page
add w0, w2, w0							; Go to next page
addc #0, w1
1:
btg LATB, #DEBUG2_PIN					; Toggle debug LED
pop w2
pop w1
pop w0
return

/******************************************************************************/
; void pageBufferWrite(int nobyte)
; Write data in temporary page buffer
; When page change, it writes the page to flash and loads the next page
; param[in] w0 byte
; return nothing
; Registers :
; w1 LSWAddr
; w2 MSWAddr
; w3 LSWBuffer
; w4 MSWBuffer
; w5 Temporary
pageBufferWrite:
push w0
push w1
push w2
push w3
push w4
push w5
push w6
push w7
mov LSWAddr, w1					; Load lower address
mov MSWAddr, w2					; Load higher address
mov LSWBuffer, w3				; Load buffer lower address
mov MSWBuffer, w4				; Load buffer higher address
dec w0, w5						; Prepare number of iterations
do w5, 5f
mov #0xF000, w0					; Mask out page offset
and w1, w0, w5
sub w5, w3, w0					; Compare the page
subb w2, w4, w0
bra Z, 4f
btsc modified, #0				; Skip if untouched
call pageBufferBurn				; Burn the current page
3:
mov w5, LSWBuffer				; Save address
mov w2, MSWBuffer				; Update address
mov w5, w3
mov w2, w4
call pageBufferRead				; Load the current page
clr modified
4:
mov #pageBuffer, w5				; Load buffer address
mov #0x0FFF, w0					; Mask buffer offset
and w1, w0, w6
mov #2,	w0						; Ask for a byte
call hexToNum					; Get the byte
clr w7							; Clear top byte
mov.b [w5+w6], w7				; Load previous byte
mov.b w0, [w5+w6]				; Store the data byte
cpseq w7, w0					; Check if new data
bset modified, #0
inc w1, w1
5:
addc #0, w2
mov w1, LSWAddr					; Save the address
mov w2, MSWAddr
pop w7
pop w6
pop w5
pop w4
pop w3
pop w2
pop w1
pop w0
return

; void pageBufferBurn()
; Burn the current page in flash
; return nothing
; Registers :
; w0 temporary
; w1 current page
pageBufferBurn:
push w0
push w1
push w2
push w3
mov LSWBuffer, w0			; Load lower address
mov MSWBuffer, w1			; Load higher address
mov #FLASH_MIN_LSW, w2		; Check for lower limit
mov #FLASH_MIN_HSW, w3
sub w0, w2, w2
subb w1, w3, w3
bra LT, 1f
mov #FLASH_MAX_LSW, w2		; Check for upper limit
mov #FLASH_MAX_HSW, w3
sub w0, w2, w2
subb w1, w3, w3
bra GE, 1f
lsr w1, w1					; Convert address
rrc w0, w0
call _flashPageErase			; Erase flash page
mov #pageBuffer, w2			; Load buffer address
call _flashPageWrite			; Burn flash page
1:
pop w3
pop w2
pop w1
pop w0
return

/******************************************************************************/
; void pageBufferClean()
; Fill the page buffer with 0xFFFF
; return nothing
; Registers :
; w0 temporary
; w1 temporary
pageBufferClean:
push w0
push w1
mov #pageBuffer, w0
mov #0xFFFF, w1
repeat (#PAGE_SIZE / #2) - #1
mov w1, [w0++]
pop w1
pop w0
return

; void pageBufferRead()
; Read page buffer from flash
; return nothing
; Registers :
; w0 temporary
; w1 temporary
pageBufferRead:
push w0
push w1
push w2
mov LSWBuffer, w0			; Load lower address
mov MSWBuffer, w1			; Load higher address
lsr w1, w1
rrc w0, w0
mov #pageBuffer, w2			; Load buffer address
call _flashPageRead			; Preload buffer data
pop w2
pop w1
pop w0
return

.end
