/*
 * File:   aurora.inc
 * Author: Marzac (Frédéric Meslin)
 * Date:   03/03/14
 * Brief:  Configuration file (pins / constants)
 
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

.include "p33Exxxx.inc"

; Clock related constants
.equ CPU_FRQ,			#140000000			; 140 Mhz (quartz + PLL)
.equ CPU_FCY,			CPU_FRQ / #2		; Instruction cycle clock

; Video pin mapping
.equ VIDEORGB_PORT,		PORTC
.equ VIDEORGB_TRIS,		TRISC
.equ RED0_PIN,			#0			; PORTC
.equ RED1_PIN,			#1			; PORTC
.equ RED2_PIN,			#2			; PORTC
.equ RED3_PIN,			#3			; PORTC
.equ GREEN0_PIN,		#4			; PORTC
.equ GREEN1_PIN,		#5			; PORTC
.equ GREEN2_PIN,		#6			; PORTC
.equ GREEN3_PIN,		#7			; PORTC
.equ BLUE0_PIN,			#8			; PORTC
.equ BLUE1_PIN,			#9			; PORTC
.equ BLUE2_PIN,			#10			; PORTC
.equ BLUE3_PIN,			#11			; PORTC

.equ RED_PINS,			#0x000F		; PORTC
.equ GREEN_PINS,		#0x00F0		; PORTC
.equ BLUE_PINS,			#0x0F00		; PORTC

.equ VIDEOSYNC_PORT,	PORTA
.equ VIDEOSYNC_TRIS,	TRISA
.equ SYNC_PIN,			#0			; PORTA

; Bluetooth pin mapping
.equ BLUEPAIRED_PIN,	#14			; PORTE, = RPI94
.equ BLUERESET_PIN,		#15			; PORTE, = RPI95
.equ BLUEAT_PIN,		#4			; PORTB, = RP36
.equ BLUERX_PIN,		#4			; PORTA, = RP20
.equ BLUETX_PIN,		#9			; PORTA, = RPI25
.equ BLUELED_PIN,		#9			; PORTG

; USB pin mapping
.equ USBENUM_PIN,		#8			; PORTD
.equ USBTX_PIN,			#5			; PORTB, = RP37
.equ USBRX_PIN,			#6			; PORTB, = RP38

; Audio PWM mapping
.equ AUDIODAC0_PIN,		#7			; PORTB, = RP39
.equ AUDIODAC1_PIN,		#8			; PORTB, = RP40
.equ AUDIODAC2_PIN,		#9			; PORTB, = RP41

; FLASH pin mapping
.equ FLASHSCLK_PIN,		#6			; PORTG, = RP118
.equ FLASHMISO_PIN,		#7			; PORTG, = RP119
.equ FLASHMOSI_PIN,		#8			; PORTG, = RP120
.equ FLASHSCS_PIN,		#1			; PORTF, = RP97

; Game pads pin mapping
.equ GP0_PIN,			#10			; PORTB
.equ GP1_PIN,			#11			; PORTB
.equ GP2_PIN,			#12			; PORTB
.equ GP3_PIN,			#13			; PORTB
.equ GP4_PIN,			#14			; PORTB
.equ GP5_PIN,			#15			; PORTB
.equ GPS0_PIN,			#5			; PORTD
.equ GPS1_PIN,			#6			; PORTD
.equ GPSELECT_PIN,		#10			; PORTA
.equ GPPOWER_PIN,		#12			; PORTE

; Debug LED pin mapping
.equ DEBUG1_PIN,		#0			; PORTB
.equ DEBUG2_PIN,		#1			; PORTB

