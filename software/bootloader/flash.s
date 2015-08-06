/*
 * File:   flash.s
 * Author: Marzac (Frédéric Meslin)
 * Date:   06/11/14
 * Brief:  aurora: internal flash driver
 
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

; Global and external symbols
.global _flashPageCompare
.global _flashPageWrite
.global _flashPageRead
.global _flashPageErase

.section .boot, code
/******************************************************************************/
; int flashPageCompare(int LSWaddr, int HSWaddr, void * data)
; Compare flash to buffer data
; param[in] w0 address low significant word
; param[in] w1 address high significant word
; param[in] w2 buffer pointer
; return 0 if data identical, 1 else
; Registers:
; w0 flash data pointer
; w1 loop counter
; w2 buffer data pointer
; w3 flash word
; w4 buffer word
_flashPageCompare:
push TBLPAG
push w2
push w3
push w4
mov w1, TBLPAG			; Set the page
mov #1024, w1			; Compare the complete page
1:
tblrdl [w0], w3			; Load flash lowest word
mov [w2++], w4			; Load data word
cp w3, w4
bra NZ, 3f				; Jump if different
tblrdh [w0++], w3		; Load flash highest word
mov [w2++], w4			; Load data word
and #0xFF, w4			; Mask top byte out
cp w3, w4
bra NZ, 3f				; Jump if different
dec w1, w1				; Decrement the counter
bra NZ, 1b
2:
mov #0, w0				; Identical data
pop w4
pop w3
pop w2
pop TBLPAG
return
3:
mov #1, w0				; Different data
pop w4
pop w3
pop w2
pop TBLPAG
return

; void flashPageErase(int LSWaddr, int HSWaddr)
; Blank one page in flash memory
; param[in] w0 address low significant word
; param[in] w1 address high significant word
; Registers:
; w2 temporary
; w3 SR backup
_flashPageErase:
push w2
push w3
mov SR, w2						; Get SR register
mov w2, w3						; Backup SR register
ior #0xE0, w2					; Disable user interrupts
mov w2, SR
mov w1, NVMADRU					; Set high memory address
mov w0, NVMADR					; Set low memory address
mov #0x4003, w2					; Ask for a flash erasing
mov w2, NVMCON					; Configure the register
mov #0x55, w2					; Unlock sequence
mov w2, NVMKEY
mov #0xAA, w2
mov w2, NVMKEY
bset NVMCON, #15				; Erase the page
nop
nop
1:
btsc NVMCON, #15				; Wait for ending (Errata: CPU does not stall)
bra 1b
mov w3, SR						; Restore user interrupts
pop w3
pop w2
return

/******************************************************************************/
; void flashPageWrite(int LSWaddr, int HSWaddr, void * src)
; Write a complete page from SRAM to flash
; param[in] w0 address low significant word
; param[in] w1 address high significant word
; param[in] w2 data source
; Registers:
; w3 temporary
; w4 burning loop counter
; w5 SR backup
_flashPageWrite:
push w2
push w3
push w4
push w5
push TBLPAG
mov SR, w3						; Get SR register
mov w3, w5						; Backup SR register
ior #0xE0, w3					; Disable interrupts
mov w3, SR
mov #512, w4					; Write a complete page
1:
mov w1, NVMADRU					; Set high memory address
mov w0, NVMADR					; Set low memory address
mov #0xFA, w3					; Load top byte latch address
mov w3, TBLPAG
clr w3
tblwtl [w2++], [w3]				; WORD1, lower 16 bits
tblwth [w2++], [w3++]			; WORD1, upper 8 bits & phantom
tblwtl [w2++], [w3]				; WORD2, lower 16 bits
tblwth [w2++], [w3++]			; WORD2, upper 8 bits & phantom
add w0, #4, w0					; Increment by two instructions
addc w1, #0, w1
mov #0x4001, w3					; Ask for 64 bits word programming
mov w3, NVMCON					; Configure the register
mov #0x55, w3					; Unlock sequence
mov w3, NVMKEY
mov #0xAA, w3
mov w3, NVMKEY
bset NVMCON, #15				; Transfer data from latches to flash
nop
nop
2:
btsc NVMCON, #15				; Wait for ending (Errata: CPU does not stall)
bra 2b
dec w4, w4
bra NZ, 1b
pop TBLPAG
pop w5
pop w4
pop w3
pop w2
return

; void flashPageRead(int LSWaddr, int HSWaddr, void * dst)
; Read a complete page from flash to SRAM
; param[in] w0 address low significant word
; param[in] w1 address high significant word
; param[in] w2 data destination
; Registers:
; w0 flash data pointer
; w1 loop counter
; w2 buffer data pointer
; w3 flash word
; w4 buffer word
_flashPageRead:
push w0
push w1
push w2
push TBLPAG
mov w1, TBLPAG			; Set the page
mov #1024, w1
1:
tblrdl [w0], [w2++]		; Load lower 16 bits
tblrdh [w0++], [w2++]	; Load higher 16 bits
dec w1, w1				; Decrement the counter
bra NZ, 1b
pop TBLPAG
pop w2
pop w1
pop w0
return

.end
