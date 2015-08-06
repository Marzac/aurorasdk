/*
 * File:   unique.s
 * Author: Marzac (Fr�d�ric Meslin)
 * Date:   19/07/15
 * Brief:  aurora: unique ID and default bluetooth name
 
  The MIT License (MIT)

  Copyright (c) 2013-2015 Fr�d�ric Meslin
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

.global _blueDefaultName
.global _blueDefaultPass

/******************************************************************************/
; Machine Unique device ID
config __FUID0,		0x1507		;Date code in BCD format
config __FUID1,		0x0019
config __FUID2,		0x0001		;Serial number
config __FUID3,		0x0000

/******************************************************************************/
; Bluetooth configuration
.section .bluename, code
_blueDefaultName:	.asciz	"Aurora-1507190001"

.section .bluepass, code
_blueDefaultPass:	.asciz	"1234"

.end
