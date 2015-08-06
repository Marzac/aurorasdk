/*
 * File:   usb.c
 * Author: Marzac, (c) Frederic Meslin 2013 - 2015
 * Date:   21/06/15
 * Brief:  aurora : USB serial communications
 *
 * This module makes use of UART1 peripheral
 
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

#include "../aurora.h"
#include "../interrupts.h"
#include "usb.h"

/******************************************************************************/
#define BAUD_BRG(b) (CPU_FCY / (4 * (u32)(b)) - 1)
const int const usbBauds[] = {
    BAUD_BRG(4800),
    BAUD_BRG(9600),
    BAUD_BRG(19200),
    BAUD_BRG(38400),
    BAUD_BRG(57600),
    BAUD_BRG(115200),
    BAUD_BRG(230400),
    BAUD_BRG(460800),
    BAUD_BRG(921600),
    BAUD_BRG(1382400)
};

/******************************************************************************/
void usbRXInterrupt();
void usbRXDBGInterrupt();
void usbTXInterrupt();

/******************************************************************************/
u8 usbRX[USB_RXTX_SIZE];
u8 usbTX[USB_RXTX_SIZE];
volatile u8 usbRXRd, usbRXWr;
volatile u8 usbTXRd, usbTXWr;
u8 usbBaud;
u8 usbDebug;

/******************************************************************************/
void usbInit()
{
// Initialise module state
    usbBaud = USB_38400;
    usbRXRd = usbRXWr = 0;
    usbTXRd = usbTXWr = 0;
    usbDebug = 1;
// Initialise the UART
    U1MODE = 0;
    U1STA  = 0;
    U1BRG  = usbBauds[USB_230400];
    U1MODE = _U1MODE_BRGH_MASK | _U1MODE_UARTEN_MASK;
    U1STA  = _U1STA_UTXEN_MASK;
// Install the interrupts
    intInstallVector(U2RXVECTOR, FUNCTIONPAGE(usbRXDBGInterrupt), FUNCTIONPTR(usbRXDBGInterrupt));
    intInstallVector(U2TXVECTOR, FUNCTIONPAGE(usbTXInterrupt), FUNCTIONPTR(usbTXInterrupt));
    IEC0bits.U1RXIE = 1;
    IEC0bits.U1TXIE = 1;
}

void usbSetRate(int baud)
{
    while(!U1STAbits.TRMT);
    U1MODE = 0;    
    U1BRG = usbBauds[baud];
    usbBaud = baud;
    usbRXRd = usbRXWr;
    usbTXRd = usbTXWr;
    U1MODE = _U1MODE_BRGH_MASK | _U1MODE_UARTEN_MASK;
    U1STA  = _U1STA_UTXEN_MASK;
}

/******************************************************************************/
int usbWrite(const void * buffer, int size)
{
    return 0;
}

int usbWriteText(const char * text)
{
    int len = 0;
    const char * t = text;
    while (*t ++) len ++;
    return usbWrite(text, len);
}

int usbRead(void * buffer, int length)
{
    return 0;
}

/******************************************************************************/
void usbEnableDebug(int enable)
{

}

/*****************************************************************************/
void usbRXDBGInterrupt()
{
    IFS0bits.U1RXIF = 0;
    if (!U1STAbits.FERR) {
        u8 d = U2RXREG;
        usbRX[usbRXWr ++] = d;
        usbRXWr &= (USB_RXTX_SIZE - 1);
    }
    U1STAbits.OERR = 0;
}

void usbRXInterrupt()
{
    IFS0bits.U1RXIF = 0;
    if (!U1STAbits.FERR) {
        u8 d = U1RXREG;
        usbRX[usbRXWr ++] = d;
        usbRXWr &= (USB_RXTX_SIZE - 1);
    }
    U1STAbits.OERR = 0;
}

void usbTXInterrupt()
{
    IFS0bits.U1TXIF = 0;
    while(usbTXRd != usbTXWr && !U1STAbits.UTXBF) {
        u8 d = usbTX[usbTXRd ++];
        U1TXREG = d;
        usbTXRd &= (USB_RXTX_SIZE - 1);
    }
}
