/*
 * File:   interrupts.h
 * Author: Marzac, (c) Frederic Meslin 2013 - 2015
 * Date:   16/05/15
 * Brief:  aurora : software interrupts remapper
 *
 * This module allows software remapping of the interrupts.
 
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

#ifndef INTERRUPTS_H
#define	INTERRUPTS_H

    #include "aurora.h"

    #define INT0VECTOR                  0x0000
    #define IC1VECTOR                   0x0004
    #define OC1VECTOR                   0x0008
    #define T1VECTOR                    0x000C
    #define DMA0VECTOR                  0x0010
    #define IC2VECTOR                   0x0014
    #define OC2VECTOR                   0x0018
    #define T2VECTOR                    0x001C
    #define T3VECTOR                    0x0020
    #define SPI1ERRVECTOR               0x0024
    #define SPI1VECTOR                  0x0028
    #define U1RXVECTOR                  0x002C
    #define U1TXVECTOR                  0x0030
    #define AD1VECTOR                   0x0034
    #define DMA1VECTOR                  0x0038
    #define SI2C1VECTOR                 0x003C
    #define MI2C1VECTOR                 0x0040
    #define CM1VECTOR                   0x0044
    #define CNVECTOR                    0x0048
    #define INT1VECTOR                  0x004C
    #define DMA2VECTOR                  0x0050
    #define OC3VECTOR                   0x0054
    #define OC4VECTOR                   0x0058
    #define T4VECTOR                    0x005C
    #define T5VECTOR                    0x0060
    #define INT2VECTOR                  0x0064
    #define U2RXVECTOR                  0x0068
    #define U2TXVECTOR                  0x006C
    #define SPI2ERRVECTOR               0x0070
    #define SPI2VECTOR                  0x0074
    #define C1RXRDYVECTOR               0x0078
    #define C1VECTOR                    0x007C
    #define DMA3VECTOR                  0x0080
    #define IC3VECTOR                   0x0084
    #define IC4VECTOR                   0x0088
    #define SI2C2VECTOR                 0x008C
    #define MI2C2VECTOR                 0x0090
    #define PWMSPEVENTMATCHVECTOR       0x0094
    #define QEI1VECTOR                  0x0098
    #define U1ERRVECTOR                 0x009C
    #define U2ERRVECTOR                 0x00A0
    #define CRCVECTOR                   0x00A4
    #define C1TXREQVECTOR               0x00A8
    #define CTMUVECTOR                  0x00AC
    #define PWM1VECTOR                  0x00B0
    #define PWM2VECTOR                  0x00B4
    #define PWM3VECTOR                  0x00B8
    #define ICDVECTOR                   0x00BC
    #define JTAGVECTOR                  0x00C0
    #define PTGSTEPVECTOR               0x00C4
    #define PTGWDTVECTOR                0x00C8
    #define PTG0VECTOR                  0x00CC
    #define PTG1VECTOR                  0x00D0
    #define PTG2VECTOR                  0x00D4
    #define PTG3VECTOR                  0x00D8

    void intInit();
    void intInstallVector(int vector, FunctionPage functionPage, FunctionPtr functionPtr);

	#define EnableInterrupts()			(SRbits.IPL = 0)
	#define DisableInterrupts()			(SRbits.IPL &= ~0x00E0)
	
#endif	/* INTERRUPTS_H */

