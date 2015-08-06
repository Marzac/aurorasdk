/*
 * File:   interrupts.s
 * Author: Marzac (Frédéric Meslin)
 * Date:   16/06/15
 * Brief:  interrupt function jumps
 
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

; Software interrupt functions
.global _intInit
.global _intInstallVector
.global _intTable

; Catched and remapped interrupts
.global __INT0Interrupt
.global __IC1Interrupt
.global __OC1Interrupt
.global __T1Interrupt
.global __DMA0Interrupt
.global __IC2Interrupt
.global __OC2Interrupt
.global __T2Interrupt
.global __T3Interrupt
.global __SPI1ErrInterrupt
.global __SPI1Interrupt
.global __U1RXInterrupt
.global __U1TXInterrupt
.global __AD1Interrupt
.global __DMA1Interrupt
.global __SI2C1Interrupt
.global __MI2C1Interrupt
.global __CM1Interrupt
.global __CNInterrupt
.global __INT1Interrupt
.global __DMA2Interrupt
.global __OC3Interrupt
.global __OC4Interrupt
.global __T4Interrupt
.global __T5Interrupt
.global __INT2Interrupt
.global __U2RXInterrupt
.global __U2TXInterrupt
.global __SPI2ErrInterrupt
.global __SPI2Interrupt
.global __C1RxRdyInterrupt
.global __C1Interrupt
.global __DMA3Interrupt
.global __IC3Interrupt
.global __IC4Interrupt
.global __SI2C2Interrupt
.global __MI2C2Interrupt
.global __PWMSpEventMatchInterrupt
.global __QEI1Interrupt
.global __U1ErrInterrupt
.global __U2ErrInterrupt
.global __CRCInterrupt
.global __C1TxReqInterrupt
.global __CTMUInterrupt
.global __PWM1Interrupt
.global __PWM2Interrupt
.global __PWM3Interrupt
.global __ICDInterrupt
.global __JTAGInterrupt
.global __PTGSTEPInterrupt
.global __PTGWDTInterrupt
.global __PTG0Interrupt
.global __PTG1Interrupt
.global __PTG2Interrupt
.global __PTG3Interrupt

; Errors or traps interrupts
.global __HardTrapError
.global __SoftTrapError
.global __AddressError
.global __StackError
.global __MathError
.global __DMACError
.global __DefaultInterrupt

; Interrupt vectors table
.section .softivt, bss
_intTable:	.space	INT_REMAP_SIZE

/******************************************************************************/
.section .handlers, code
__INT0Interrupt:
	push w0
	push w1
	mov _intTable + INT0VECTOR, w0
	mov _intTable + INT0VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__IC1Interrupt:
	push w0
	push w1
	mov _intTable + #IC1VECTOR, w0
	mov _intTable + #IC1VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__OC1Interrupt:
	push w0
	push w1
	mov _intTable + #OC1VECTOR, w0
	mov _intTable + #OC1VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__T1Interrupt:
	push w0
	push w1
	mov _intTable + #T1VECTOR, w0
	mov _intTable + #T1VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__DMA0Interrupt:
	push w0
	push w1
	mov _intTable + #DMA0VECTOR, w0
	mov _intTable + #DMA0VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__IC2Interrupt:
	push w0
	push w1
	mov _intTable + #IC2VECTOR, w0
	mov _intTable + #IC2VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__OC2Interrupt:
	push w0
	push w1
	mov _intTable + #OC2VECTOR, w0
	mov _intTable + #OC2VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__T2Interrupt:
	push w0
	push w1
	mov _intTable + #T2VECTOR, w0
	mov _intTable + #T2VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__T3Interrupt:
	push w0
	push w1
	mov _intTable + #T3VECTOR, w0
	mov _intTable + #T3VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__SPI1ErrInterrupt:
	push w0
	push w1
	mov _intTable + #SPI1ERRVECTOR, w0
	mov _intTable + #SPI1ERRVECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__SPI1Interrupt:
	push w0
	push w1
	mov _intTable + #SPI1VECTOR, w0
	mov _intTable + #SPI1VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__U1RXInterrupt:
	push w0
	push w1
	mov _intTable + #U1RXVECTOR, w0
	mov _intTable + #U1RXVECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__U1TXInterrupt:
	push w0
	push w1
	mov _intTable + #U1TXVECTOR, w0
	mov _intTable + #U1TXVECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__AD1Interrupt:
	push w0
	push w1
	mov _intTable + #AD1VECTOR, w0
	mov _intTable + #AD1VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__DMA1Interrupt:
	push w0
	push w1
	mov _intTable + #DMA1VECTOR, w0
	mov _intTable + #DMA1VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__SI2C1Interrupt:
	push w0
	push w1
	mov _intTable + #SI2C1VECTOR, w0
	mov _intTable + #SI2C1VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__MI2C1Interrupt:
	push w0
	push w1
	mov _intTable + #MI2C1VECTOR, w0
	mov _intTable + #MI2C1VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__CM1Interrupt:
	push w0
	push w1
	mov _intTable + #CM1VECTOR, w0
	mov _intTable + #CM1VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__CNInterrupt:
	push w0
	push w1
	mov _intTable + #CNVECTOR, w0
	mov _intTable + #CNVECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__INT1Interrupt:
	push w0
	push w1
	mov _intTable + #INT1VECTOR, w0
	mov _intTable + #INT1VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__DMA2Interrupt:
	push w0
	push w1
	mov _intTable + #DMA2VECTOR, w0
	mov _intTable + #DMA2VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__OC3Interrupt:
	push w0
	push w1
	mov _intTable + #OC3VECTOR, w0
	mov _intTable + #OC3VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__OC4Interrupt:
	push w0
	push w1
	mov _intTable + #OC4VECTOR, w0
	mov _intTable + #OC4VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__T4Interrupt:
	push w0
	push w1
	mov _intTable + #T4VECTOR, w0
	mov _intTable + #T4VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__T5Interrupt:
	push w0
	push w1
	mov _intTable + #T5VECTOR, w0
	mov _intTable + #T5VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__INT2Interrupt:
	push w0
	push w1
	mov _intTable + #INT2VECTOR, w0
	mov _intTable + #INT2VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__U2RXInterrupt:
	push w0
	push w1
	mov _intTable + #U2RXVECTOR, w0
	mov _intTable + #U2RXVECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__U2TXInterrupt:
	push w0
	push w1
	mov _intTable + #U2TXVECTOR, w0
	mov _intTable + #U2TXVECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__SPI2ErrInterrupt:
	push w0
	push w1
	mov _intTable + #SPI2ERRVECTOR, w0
	mov _intTable + #SPI2ERRVECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__SPI2Interrupt:
	push w0
	push w1
	mov _intTable + #SPI2VECTOR, w0
	mov _intTable + #SPI2VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__C1RxRdyInterrupt:
	push w0
	push w1
	mov _intTable + #C1RXRDYVECTOR, w0
	mov _intTable + #C1RXRDYVECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__C1Interrupt:
	push w0
	push w1
	mov _intTable + #C1VECTOR, w0
	mov _intTable + #C1VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__DMA3Interrupt:
	push w0
	push w1
	mov _intTable + #DMA3VECTOR, w0
	mov _intTable + #DMA3VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__IC3Interrupt:
	push w0
	push w1
	mov _intTable + #IC3VECTOR, w0
	mov _intTable + #IC3VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__IC4Interrupt:
	push w0
	push w1
	mov _intTable + #IC4VECTOR, w0
	mov _intTable + #IC4VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__SI2C2Interrupt:
	push w0
	push w1
	mov _intTable + #SI2C2VECTOR, w0
	mov _intTable + #SI2C2VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__MI2C2Interrupt:
	push w0
	push w1
	mov _intTable + #MI2C2VECTOR, w0
	mov _intTable + #MI2C2VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__PWMSpEventMatchInterrupt:
	push w0
	push w1
	mov _intTable + #PWMSPEVENTMATCHVECTOR, w0
	mov _intTable + #PWMSPEVENTMATCHVECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__QEI1Interrupt:
	push w0
	push w1
	mov _intTable + #QEI1VECTOR, w0
	mov _intTable + #QEI1VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__U1ErrInterrupt:
	push w0
	push w1
	mov _intTable + #U1ERRVECTOR, w0
	mov _intTable + #U1ERRVECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__U2ErrInterrupt:
	push w0
	push w1
	mov _intTable + #U2ERRVECTOR, w0
	mov _intTable + #U2ERRVECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__CRCInterrupt:
	push w0
	push w1
	mov _intTable + #CRCVECTOR, w0
	mov _intTable + #CRCVECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__C1TxReqInterrupt:
	push w0
	push w1
	mov _intTable + #C1TXREQVECTOR, w0
	mov _intTable + #C1TXREQVECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__CTMUInterrupt:
	push w0
	push w1
	mov _intTable + #CTMUVECTOR, w0
	mov _intTable + #CTMUVECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__PWM1Interrupt:
	push w0
	push w1
	mov _intTable + #PWM1VECTOR, w0
	mov _intTable + #PWM1VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__PWM2Interrupt:
	push w0
	push w1
	mov _intTable + #PWM2VECTOR, w0
	mov _intTable + #PWM2VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__PWM3Interrupt:
	push w0
	push w1
	mov _intTable + #PWM3VECTOR, w0
	mov _intTable + #PWM3VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__ICDInterrupt:
	push w0
	push w1
	mov _intTable + #ICDVECTOR, w0
	mov _intTable + #ICDVECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__JTAGInterrupt:
	push w0
	push w1
	mov _intTable + #JTAGVECTOR, w0
	mov _intTable + #JTAGVECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__PTGSTEPInterrupt:
	push w0
	push w1
	mov _intTable + #PTGSTEPVECTOR, w0
	mov _intTable + #PTGSTEPVECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__PTGWDTInterrupt:
	push w0
	push w1
	mov _intTable + #PTGWDTVECTOR, w0
	mov _intTable + #PTGWDTVECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__PTG0Interrupt:
	push w0
	push w1
	mov _intTable + #PTG0VECTOR, w0
	mov _intTable + #PTG0VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__PTG1Interrupt:
	push w0
	push w1
	mov _intTable + #PTG1VECTOR, w0
	mov _intTable + #PTG1VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__PTG2Interrupt:
	push w0
	push w1
	mov _intTable + #PTG2VECTOR, w0
	mov _intTable + #PTG2VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

__PTG3Interrupt:
	push w0
	push w1
	mov _intTable + #PTG3VECTOR, w0
	mov _intTable + #PTG3VECTOR + #2, w1
	call.l w0
	pop w1
	pop w0
	retfie

/******************************************************************************/
__OscillatorFail:
    goto __OscillatorFail

__HardTrapError:
    goto __HardTrapError

__SoftTrapError:
    goto __SoftTrapError

__AddressError:
	bclr LATB, #DEBUG1_PIN
	bclr LATB, #DEBUG2_PIN
	goto __Blink2Fast

__StackError:
	bset LATB, #DEBUG1_PIN
	bclr LATB, #DEBUG2_PIN
	goto __Blink2Fast

__MathError:
	bclr LATB, #DEBUG1_PIN
	bclr LATB, #DEBUG2_PIN
	goto __Blink12Fast
	goto __MathError

__DMACError:
	goto __DMACError

__DefaultInterrupt:
	bset LATB, #DEBUG1_PIN
	bclr LATB, #DEBUG2_PIN
	goto __Blink12Fast

/******************************************************************************/
__Blink2Fast:
	clr w1
	clr w2
1:
	mov w1, w2
	inc w0, w0
	addc #0, w1
	xor w2, w1, w2
	btss w2, #3
	bra 1b
	btg LATB, #DEBUG2_PIN
    bra 1b

__Blink12Fast:
	clr w1
	clr w2
1:
	mov w1, w2
	inc w0, w0
	addc #0, w1
	xor w2, w1, w2
	btss w2, #3
	bra 1b
	btg LATB, #DEBUG1_PIN
	btg LATB, #DEBUG2_PIN
    bra 1b

/******************************************************************************/
; void intInit()
; return nothing
_intInit:
push w0
push w1
push w2
mov #tbloffset(__DefaultInterrupt), w0	; load default function pointer
mov #tblpage(__DefaultInterrupt), w1
mov #_intTable, w2						; load vector table
do (#INT_REMAP_SIZE >> #2) - #1, 1f		; for every vector
mov w0, [w2++]							; install the pointer
1:
mov w1, [w2++]
pop w2
pop w1
pop w0
return

/******************************************************************************/
; void intInstallVector(int vector, int functionPage, int functionPointer)
; param[in] w0 vector index
; param[in] w1 function address, table page
; param[in] w2 function address, table offset
; return nothing
_intInstallVector:
push w3
mov #_intTable, w3			; load vector table
add w0, w3, w3				; get vector address
and #0xff, w1				; ensure a 24bits pointer
mov w1, [w3+#2]				; install the function pointer
mov w2, [w3]
pop w3
return

/******************************************************************************/
.section .ivt, code
.word __OscillatorFail							/* OscillatorFail */
.word __AddressError							/* AddressError */
.word __HardTrapError							/* HardTrapError */
.word __StackError								/* StackError */
.word __MathError								/* MathError */
.word __DMACError								/* DMACError */
.word __SoftTrapError							/* SoftTrapError */
.word __DefaultInterrupt						/* ReservedTrap7 */
.word __INT0Interrupt							/* INT0Interrupt */
.word __IC1Interrupt							/* IC1Interrupt */
.word __OC1Interrupt							/* OC1Interrupt */
.word __T1Interrupt								/* T1Interrupt */
.word __DMA0Interrupt							/* DMA0Interrupt */
.word __IC2Interrupt							/* IC2Interrupt */
.word __OC2Interrupt							/* OC2Interrupt */
.word __T2Interrupt								/* T2Interrupt */
.word __T3Interrupt								/* T3Interrupt */
.word __SPI1ErrInterrupt						/* SPI1ErrInterrupt */
.word __SPI1Interrupt							/* SPI1Interrupt */
.word __U1RXInterrupt							/* U1RXInterrupt */
.word __U1TXInterrupt							/* U1TXInterrupt */
.word __AD1Interrupt							/* AD1Interrupt */
.word __DMA1Interrupt							/* DMA1Interrupt */
.word __DefaultInterrupt						/* Interrupt15 */
.word __SI2C1Interrupt							/* SI2C1Interrupt */
.word __MI2C1Interrupt							/* MI2C1Interrupt */
.word __CM1Interrupt							/* CM1Interrupt */
.word __CNInterrupt								/* CNInterrupt */
.word __INT1Interrupt							/* INT1Interrupt */
.word __DefaultInterrupt						/* Interrupt21 */
.word __DefaultInterrupt						/* Interrupt22 */
.word __DefaultInterrupt						/* Interrupt23 */
.word __DMA2Interrupt							/* DMA2Interrupt */
.word __OC3Interrupt							/* OC3Interrupt */
.word __OC4Interrupt							/* OC4Interrupt */
.word __T4Interrupt								/* T4Interrupt */
.word __T5Interrupt								/* T5Interrupt */
.word __INT2Interrupt							/* INT2Interrupt */
.word __U2RXInterrupt							/* U2RXInterrupt */
.word __U2TXInterrupt							/* U2TXInterrupt */
.word __SPI2ErrInterrupt						/* SPI2ErrInterrupt */
.word __SPI2Interrupt							/* SPI2Interrupt */
.word __C1RxRdyInterrupt						/* C1RxRdyInterrupt */
.word __C1Interrupt								/* C1Interrupt */
.word __DMA3Interrupt							/* DMA3Interrupt */
.word __IC3Interrupt							/* IC3Interrupt */
.word __IC4Interrupt							/* IC4Interrupt */
.word __DefaultInterrupt						/* Interrupt39 */
.word __DefaultInterrupt						/* Interrupt40 */
.word __DefaultInterrupt						/* Interrupt41 */
.word __DefaultInterrupt						/* Interrupt42 */
.word __DefaultInterrupt						/* Interrupt43 */
.word __DefaultInterrupt						/* Interrupt44 */
.word __DefaultInterrupt						/* Interrupt45 */
.word __DefaultInterrupt						/* Interrupt46 */
.word __DefaultInterrupt						/* Interrupt47 */
.word __DefaultInterrupt						/* Interrupt48 */
.word __SI2C2Interrupt							/* SI2C2Interrupt */
.word __MI2C2Interrupt							/* MI2C2Interrupt */
.word __DefaultInterrupt						/* Interrupt51 */
.word __DefaultInterrupt						/* Interrupt52 */
.word __DefaultInterrupt						/* Interrupt53 */
.word __DefaultInterrupt						/* Interrupt54 */
.word __DefaultInterrupt						/* Interrupt55 */
.word __DefaultInterrupt						/* Interrupt56 */
.word __PWMSpEventMatchInterrupt				/* PWMSpEventMatchInterrupt */
.word __QEI1Interrupt							/* QEI1Interrupt */
.word __DefaultInterrupt						/* Interrupt59 */
.word __DefaultInterrupt						/* Interrupt60 */
.word __DefaultInterrupt						/* Interrupt61 */
.word __DefaultInterrupt						/* Interrupt62 */
.word __DefaultInterrupt						/* Interrupt63 */
.word __DefaultInterrupt						/* Interrupt64 */
.word __U1ErrInterrupt							/* U1ErrInterrupt */
.word __U2ErrInterrupt							/* U2ErrInterrupt */
.word __CRCInterrupt							/* CRCInterrupt */
.word __DefaultInterrupt						/* Interrupt68 */
.word __DefaultInterrupt						/* Interrupt69 */
.word __C1TxReqInterrupt						/* C1TxReqInterrupt */
.word __DefaultInterrupt						/* Interrupt71 */
.word __DefaultInterrupt						/* Interrupt72 */
.word __DefaultInterrupt						/* Interrupt73 */
.word __DefaultInterrupt						/* Interrupt74 */
.word __DefaultInterrupt						/* Interrupt75 */
.word __DefaultInterrupt						/* Interrupt76 */
.word __CTMUInterrupt							/* CTMUInterrupt */
.word __DefaultInterrupt						/* Interrupt78 */
.word __DefaultInterrupt						/* Interrupt79 */
.word __DefaultInterrupt						/* Interrupt80 */
.word __DefaultInterrupt						/* Interrupt81 */
.word __DefaultInterrupt						/* Interrupt82 */
.word __DefaultInterrupt						/* Interrupt83 */
.word __DefaultInterrupt						/* Interrupt84 */
.word __DefaultInterrupt						/* Interrupt85 */
.word __DefaultInterrupt						/* Interrupt86 */
.word __DefaultInterrupt						/* Interrupt87 */
.word __DefaultInterrupt						/* Interrupt88 */
.word __DefaultInterrupt						/* Interrupt89 */
.word __DefaultInterrupt						/* Interrupt90 */
.word __DefaultInterrupt						/* Interrupt91 */
.word __DefaultInterrupt						/* Interrupt92 */
.word __DefaultInterrupt						/* Interrupt93 */
.word __PWM1Interrupt							/* PWM1Interrupt */
.word __PWM2Interrupt							/* PWM2Interrupt */
.word __PWM3Interrupt							/* PWM3Interrupt */
.word __DefaultInterrupt						/* Interrupt97 */
.word __DefaultInterrupt						/* Interrupt98 */
.word __DefaultInterrupt						/* Interrupt99 */
.word __DefaultInterrupt						/* Interrupt100 */
.word __DefaultInterrupt						/* Interrupt101 */
.word __DefaultInterrupt						/* Interrupt102 */
.word __DefaultInterrupt						/* Interrupt103 */
.word __DefaultInterrupt						/* Interrupt104 */
.word __DefaultInterrupt						/* Interrupt105 */
.word __DefaultInterrupt						/* Interrupt106 */
.word __DefaultInterrupt						/* Interrupt107 */
.word __DefaultInterrupt						/* Interrupt108 */
.word __DefaultInterrupt						/* Interrupt109 */
.word __DefaultInterrupt						/* Interrupt110 */
.word __DefaultInterrupt						/* Interrupt111 */
.word __DefaultInterrupt						/* Interrupt112 */
.word __DefaultInterrupt						/* Interrupt113 */
.word __DefaultInterrupt						/* Interrupt114 */
.word __DefaultInterrupt						/* Interrupt115 */
.word __DefaultInterrupt						/* Interrupt116 */
.word __DefaultInterrupt						/* Interrupt117 */
.word __DefaultInterrupt						/* Interrupt118 */
.word __DefaultInterrupt						/* Interrupt119 */
.word __DefaultInterrupt						/* Interrupt120 */
.word __DefaultInterrupt						/* Interrupt121 */
.word __DefaultInterrupt						/* Interrupt122 */
.word __DefaultInterrupt						/* Interrupt123 */
.word __DefaultInterrupt						/* Interrupt124 */
.word __DefaultInterrupt						/* Interrupt125 */
.word __DefaultInterrupt						/* Interrupt126 */
.word __DefaultInterrupt						/* Interrupt127 */
.word __DefaultInterrupt						/* Interrupt128 */
.word __DefaultInterrupt						/* Interrupt129 */
.word __DefaultInterrupt						/* Interrupt130 */
.word __DefaultInterrupt						/* Interrupt131 */
.word __DefaultInterrupt						/* Interrupt132 */
.word __DefaultInterrupt						/* Interrupt133 */
.word __DefaultInterrupt						/* Interrupt134 */
.word __DefaultInterrupt						/* Interrupt135 */
.word __DefaultInterrupt						/* Interrupt136 */
.word __DefaultInterrupt						/* Interrupt137 */
.word __DefaultInterrupt						/* Interrupt138 */
.word __DefaultInterrupt						/* Interrupt139 */
.word __DefaultInterrupt						/* Interrupt140 */
.word __DefaultInterrupt						/* Interrupt141 */
.word __ICDInterrupt							/* ICDInterrupt */
.word __JTAGInterrupt							/* JTAGInterrupt */
.word __DefaultInterrupt						/* Interrupt144 */
.word __PTGSTEPInterrupt						/* PTGSTEPInterrupt */
.word __PTGWDTInterrupt							/* PTGWDTInterrupt */
.word __PTG0Interrupt							/* PTG0Interrupt */
.word __PTG1Interrupt							/* PTG1Interrupt */
.word __PTG2Interrupt							/* PTG2Interrupt */
.word __PTG3Interrupt							/* PTG3Interrupt */

.end
