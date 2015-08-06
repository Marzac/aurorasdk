/*
 * File:   startup.s
 * Author: Marzac (Frédéric Meslin)
 * Date:   19/07/15
 * Brief:  uC startup code
  
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

; Fake symbols to discard default startup
.global __resetPRI
.global __resetALT
.global __reset

; User program symbols
.extern _main
.extern _intInit

/******************************************************************************/
; Device configuration bits
config __FICD,		ICS_PGD1 & JTAGEN_OFF
config __FWDT,		FWDTEN_OFF & PLLKEN_ON
config __FOSC,		POSCMD_HS & OSCIOFNC_OFF & IOL1WAY_OFF & FCKSM_CSECME
config __FOSCSEL,	FNOSC_FRC & PWMLOCK_OFF & IESO_OFF
config __FGS,		GWRP_OFF & GCP_OFF

/******************************************************************************/
; Fake reset symbols
; Provide symbols to discard default startup code
.section .userEntry, code
__resetPRI:
__resetALT:

; Reset function
; Disable interrupts & watchdog timer
; Clean the complete SRAM space & prepare the stack
; Initialise the PLL clock system for 140MHz
__reset:
; Disable all interrupts
    mov SR, w1
    ior #0xE0, w1
    mov w1, SR
; Clear reset cause & disable watchdog
	clr RCON
; Initialise the stack
    mov #__SP_init, w15				; Initialize the Stack Pointer
    mov #__SPLIM_init, w1			; Initialize the Stack Pointer Limit Register
    mov w1, SPLIM
    nop
; Initialise 28k of standard SRAM
	clr w0
	mov #0x1000, w1					; Start address of standard SRAM
	repeat #0x3800 - #1,			; Repeat 14k times
	mov w0, [w1++]					; Blank memory
; Initialise 20k of extended SRAM
	movpag #0x001, DSRPAG			; Second EDS page (0x8000 - 0xFFFF)
	mov #0x8000, w1					; Start address of extended SRAM
	repeat #0x2800 - #1				; Repeat 10k times
	mov w0, [w1++]					; Blank memory
; Configure default EDS page
    mov #__const_psvpage,w1			; Page used by C compiler
    movpag w1, DSRPAG
; Configure the unit
	call setupMCU
	call initPorts
	call _intInit
    call _main
    reset

.text
/******************************************************************************/
; void setupMCU()
; Set default MCU state
setupMCU:
; Disable all interrupts
    mov SR, w1
    ior #0xE0, w1
    mov w1, SR
; Clear reset cause & disable watchdog
	clr RCON
	return

/******************************************************************************/
; void setupClock()
; Configure oscillator and PLL
setupClock:
; Configure the PLL system
    mov #0x3000, w1					; PLL : PRE 0.5 POST 0.5
    mov w1, CLKDIV
    mov #0x0037, w1					; PLL : MUL 56 (20 x 56 / 8 = 140MHz)
    mov w1, PLLFBD
; Unlock the clock system A
    mov #OSCCONH, w4
    mov #0x78, w1
    mov #0x9A, w2
    mov #0x03, w3
    mov.b w1, [w4]					; Unlock sequence
    mov.b w2, [w4]					; Unlock sequence
; Write new configuration
    mov.b w3, [w4]					; Osc -> HS & PLL
; Unlock the clock system B
    mov #OSCCONL, w4
    mov #0x46, w1
    mov #0x57, w2
    mov.b w1, [w4]					; Unlock sequence
    mov.b w2, [w4]					; Unlock sequence
; Switch to new clock
    bset OSCCON, #OSWEN
; Wait for PLL synchronisation
1:
    btst OSCCON, #OSWEN
    bra NZ, 1b
	return

/******************************************************************************/
; void setupPorts()
; Set ports to default configuration
setupPorts:
; Disable analog function
    clr ANSELA
    clr ANSELB
	clr ANSELC
	clr ANSELE
; Configure port A (SCART Sync / Gamepads select / Bluetooth data)
	clr PORTA
	mov #0xFFFE, w0
	mov w0, TRISA
	mov #0x0210, w0
	mov w0,	CNPUA
; Configure port B (DEBUG / USB serial / Bluetooth AT / DAC / Gamepads data)
	clr PORTB
	mov #0xFFEC, w0
	mov w0, TRISB
	mov #0xFC00, w0
	mov w0,	CNPUB
; Configure port C (SCART RGB)
	clr PORTC
	mov #0xF000, w0
	mov w0, TRISC
; Configure port D (Gamepads mux / USB enum.)
	clr PORTD
	mov #0xFF9F, w0
	mov w0, TRISD
; Configure port E (Gamepads power / Bluetooth enum. & reset)
	clr PORTE
	mov #0x6FFF, w0
	mov w0, TRISE
; Configure port F (Flash CS)
	clr PORTF
	mov #0xFFFD, w0
	mov w0, TRISF
; Configure port G (Flash serial / Bluetooth LED)
	clr PORTG
	mov #0xFDFF, w0
	mov w0, TRISG
; Unlock pin configuration
	mov #OSCCONL, w3
    mov #0x46, w1
    mov #0x57, w2
    mov.b w1, [w3]					; Unlock sequence
    mov.b w2, [w3]					; Unlock sequence
    bclr OSCCON, #IOLOCK
; Configure SPI2 CLK pin (External flash clock)
	mov #0x0900, w0		; 0x09 = SPI 2 clock (SCK2)
	mov w0, RPOR8
; Configure SPI2 SDO pin (External flash MOSI)
	mov #0x0008, w0		; 0x08 = SPI 2 output (SDO2)
	mov w0, RPOR9
; Configure SPI2 SDI pin (External flash MISO)
	mov #0x0077, w0		; RPI119 = 0x77
	mov w0, RPINR22
; Configure UART1 RX pin (USB serial RX)
	mov #0x0025, w0		; RP37 = 0x25
	mov w0, RPINR18
; Configure UART1 TX, OC1 pins (USB serial TX, DAC0 / left output)
	mov #0x1001, w0		; 0x01 = UART 1 transmit (U1TX)
	mov w0, RPOR2		; 0x10 = Output compare 1 (OC1)
; Configure OC2, OC3 pins (DAC1 / right output, DAC2 / center output)
	mov #0x1211, w0		; 0x11 = Output compare 2 (OC2)
	mov w0, RPOR3		; 0x12 = Output compare 3 (OC3)
; Configure UART2 RX pin (Bluetooth serial RX)
	mov #0x0019, w0		; RPI25 = 0x19
	mov w0, RPINR19
; Configure UART2 TX pin (Bluetooth serial TX)
	mov #0x0003, w0		; 0x03 UART 2 transmit (U2TX)
	mov w0, RPOR0
; Lock pin configuration
    mov.b w1, [w3]					; Unlock sequence
    mov.b w2, [w3]					; Unlock sequence
    bset OSCCON, #IOLOCK
	nop
	return

/******************************************************************************/
; void initPorts()
; Initialise ports outputs
initPorts:
	push w0
	push w1
; Disable analog function
    clr ANSELA
    clr ANSELB
	clr ANSELC
	clr ANSELE
; Clear port A
	clr PORTA
; Clear port B (excepting bluetooth AT)
	mov LATB, w0
	mov #0x0010, w1
	and w0, w1, w0
	mov w0, PORTB
; Clear port C
	clr PORTC
; Clear port D
	clr PORTD
; Clear port E (excepting bluetooth RESET)
	mov LATE, w0
	mov #0x8000, w1
	and w0, w1, w0
	mov w0, PORTE
; Clear port F
	clr PORTF
; Clear port G
	clr PORTG
	pop w1
	pop w0
	return

.end
