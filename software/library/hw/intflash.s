/*
 * File:   intFlash.s
 * Author: Marzac, (c) Frederic Meslin 2013 - 2015
 * Date:   18/11/14
 * Brief:  aurora : internal FLASH utilities
 
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

; Flash exported functions
.global _flashLoad

.text
/******************************************************************************/
; void flashLoad(const FlashPage page, const FlashPtr src, RamPtr dst, u16 size)
; Load a memory block from FLASH to RAM
; param[in] w0 FLASH EDS page
; param[in] w1 FLASH source pointer
; param[in] w2 RAM destination pointer
; param[in] w3 size of block in bytes
; return nothing
_flashLoad:
push DSRPAG
movpag w0, DSRPAG
lsr w3, #1, w3
dec w3, w3
repeat w3
mov [w1++], [w2++]
pop DSRPAG
return

.end
