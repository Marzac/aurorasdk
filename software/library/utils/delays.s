/*
 * File:   delays.h
 * Author: Marzac, (c) Frederic Meslin 2013 - 2015
 * Date:   18/02/14
 * Brief:  aurora : delay functions
 
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

; Exported symbols
.global _delayms
.global _delay10ms
.global _delay100ms
.global _delayus
.global _delay10us
.global _delay100us

.text

/******************************************************************************/
; void delayus()
; Wait for a us
; params[in]  : nothing
; params[out] : nothing
; return      : nothing
_delayus:
repeat (#CPU_FCY / #1000000) - #5   ; 1
nop                                 ; n - 1
return                              ; 3

/******************************************************************************/
; void delay10us()
; Wait for 10 us
; params[in]  : nothing
; params[out] : nothing
; return      : nothing
_delay10us:
repeat (#CPU_FCY / #100000) - #5    ; 1
nop                                 ; n - 1
return                              ; 3

/******************************************************************************/
; void delay100us()
; Wait for a 100 us
; params[in]  : nothing
; params[out] : nothing
; return      : nothing
_delay100us:
repeat (#CPU_FCY / #10000) - #5     ; 1
nop                                 ; n - 1
return                              ; 3

/******************************************************************************/
; void delayms()
; Wait for roughly a ms
; params[in]  : nothing
; params[out] : nothing
; return      : nothing
_delayms:
do #999, __dlyms                    ; 2 *
repeat (#CPU_FCY / #1000000) - #3   ; 1
nop                                 ; n - 1
__dlyms:
nop                                 ; 1
return                              ; 3 *

/******************************************************************************/
; void delay10ms()
; Wait for roughly 10 ms
; params[in]  : nothing
; params[out] : nothing
; return      : nothing
_delay10ms:
do #999, __dly10ms                  ; 2 *
repeat (#CPU_FCY / #100000) - #3    ; 1
nop                                 ; n - 1
__dly10ms:
nop                                 ; 1
return                              ; 3 *

/******************************************************************************/
; void delay100ms()
; Wait for roughly 100 ms
; params[in]  : nothing
; params[out] : nothing
; return      : nothing
_delay100ms:
do #999, __dly100ms                 ; 2 *
repeat (#CPU_FCY / #10000) - #3     ; 1
nop                                 ; n - 1
__dly100ms:
nop                                 ; 1
return                              ; 3 *

.end
