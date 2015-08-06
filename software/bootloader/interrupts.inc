/*
 * File:   interrupts.inc
 * Author: Marzac (Frédéric Meslin)
 * Date:   16/05/15
 * Brief:  Interruptions declarations
 
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

; Remappable interrupts table
.extern _intInit
.extern _intInstallVector
.extern _intTable

; Remappable interrupt vectors
.equ INT0VECTOR,				#0x0000
.equ IC1VECTOR,					#0x0004
.equ OC1VECTOR,					#0x0008
.equ T1VECTOR,					#0x000C
.equ DMA0VECTOR,				#0x0010
.equ IC2VECTOR,					#0x0014
.equ OC2VECTOR,					#0x0018
.equ T2VECTOR,					#0x001C
.equ T3VECTOR,					#0x0020
.equ SPI1ERRVECTOR,				#0x0024
.equ SPI1VECTOR,				#0x0028
.equ U1RXVECTOR,				#0x002C
.equ U1TXVECTOR,				#0x0030
.equ AD1VECTOR,					#0x0034
.equ DMA1VECTOR,				#0x0038
.equ SI2C1VECTOR,				#0x003C
.equ MI2C1VECTOR,				#0x0040
.equ CM1VECTOR,					#0x0044
.equ CNVECTOR,					#0x0048
.equ INT1VECTOR,				#0x004C
.equ DMA2VECTOR,				#0x0050
.equ OC3VECTOR,					#0x0054
.equ OC4VECTOR,					#0x0058
.equ T4VECTOR,					#0x005C
.equ T5VECTOR,					#0x0060
.equ INT2VECTOR,				#0x0064
.equ U2RXVECTOR,				#0x0068
.equ U2TXVECTOR,				#0x006C
.equ SPI2ERRVECTOR,				#0x0070
.equ SPI2VECTOR,				#0x0074
.equ C1RXRDYVECTOR,				#0x0078
.equ C1VECTOR,					#0x007C
.equ DMA3VECTOR,				#0x0080
.equ IC3VECTOR,					#0x0084
.equ IC4VECTOR,					#0x0088
.equ SI2C2VECTOR,				#0x008C
.equ MI2C2VECTOR,				#0x0090
.equ PWMSPEVENTMATCHVECTOR,		#0x0094
.equ QEI1VECTOR,				#0x0098
.equ U1ERRVECTOR,				#0x009C
.equ U2ERRVECTOR,				#0x00A0
.equ CRCVECTOR,					#0x00A4
.equ C1TXREQVECTOR,				#0x00A8
.equ CTMUVECTOR,				#0x00AC
.equ PWM1VECTOR,				#0x00B0
.equ PWM2VECTOR,				#0x00B4
.equ PWM3VECTOR,				#0x00B8
.equ ICDVECTOR,					#0x00BC
.equ JTAGVECTOR,				#0x00C0
.equ PTGSTEPVECTOR,				#0x00C4
.equ PTGWDTVECTOR,				#0x00C8
.equ PTG0VECTOR,				#0x00CC
.equ PTG1VECTOR,				#0x00D0
.equ PTG2VECTOR,				#0x00D4
.equ PTG3VECTOR,				#0x00D8

.equ INT_REMAP_SIZE,			#0x00DC
