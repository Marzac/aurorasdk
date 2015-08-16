/*
 * File:   bluetooth.c
 * Author: Marzac, (c) Frederic Meslin 2013 - 2015
 * Date:   18/11/14
 * Brief:  aurora : Bluetooth serial communications
 *
 * This module makes use of UART2 peripheral
 
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
#include "../utils/delays.h"
#include "../interrupts.h"
#include "bluetooth.h"

/******************************************************************************/
const char blueAnsInit[]        = "INITIALIZED";
const char blueAnsReady[]       = "READY";
const char blueAnsPairable[]    = "PAIRABLE";
const char blueAnsPaired[]      = "PAIRED";
const char blueAnsInquiring[]   = "INQUIRING";
const char blueAnsConnecting[]  = "CONNECTING";
const char blueAnsConnected[]   = "CONNECTED";
const char blueAnsDisonnected[] = "DISCONNECTED";
const char blueAnsUnknown[]     = "UNKNOWN";

const char * const blueRates[] = {
    "4800", "9600", "19200", "38400",
    "57600", "115200", "230400", "460800",
    "921600", "1382400"
};

#define BAUD_BRG(b) (CPU_FCY / (4 * (u32)(b)) - 1)
const int const blueBauds[] = {
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
void blueRXInterrupt();
void blueTXInterrupt();

/*****************************************************************************/
/* Bluetooth flash configuration */
extern const char * _blueDefaultName;
extern const char * _blueDefaultPass;

/******************************************************************************/
u8 blueRX[BLUE_RXTX_SIZE];
u8 blueTX[BLUE_RXTX_SIZE];
volatile u8 blueRXRd, blueRXWr;
volatile u8 blueTXRd, blueTXWr;
u8 blueMode;
u8 blueBaud;

/*****************************************************************************/
void blueInit()
{
// Initialise control signal
    BLUEAT_PIN = 0;
    BLUERESET_PIN = 1;
// Initialise module state
    blueMode = BLUE_MODE_COM;
    blueBaud = BLUE_230400;
    blueRXRd = blueRXWr = 0;
    blueTXRd = blueTXWr = 0;
// Initialise the USART
    U2MODE = 0;
    U2STA  = 0;
// Install the interrupts
    intInstallVector(U2RXVECTOR, FUNCTIONPAGE(blueRXInterrupt), FUNCTIONPTR(blueRXInterrupt));
    intInstallVector(U2TXVECTOR, FUNCTIONPAGE(blueTXInterrupt), FUNCTIONPTR(blueTXInterrupt));
    IEC1bits.U2RXIE = 1;
    IEC1bits.U2TXIE = 1;
}

void blueConfigure()
{
// Set default configuration
    blueSetMode(BLUE_MODE_AT);
    blueSetRole(BLUE_ROLE_SLAVE);
    blueSetName(blueDefaultName);
    blueSetPassword(blueDefaultPass);
    blueSetRate(BLUE_230400);
    blueSetMode(BLUE_MODE_COM);
}

/*****************************************************************************/
void blueSetMode(int mode)
{
    U2MODE = 0;
    BLUERESET_PIN = 0;
    if (mode == BLUE_MODE_COM) {
        BLUEAT_PIN = 0;
        U2BRG = blueBauds[blueBaud];
        blueMode = BLUE_MODE_COM;
    }else{
        BLUEAT_PIN = 1;
        U2BRG = blueBauds[BLUE_38400];
        blueMode = BLUE_MODE_AT;
    }
    delay100ms();
    BLUERESET_PIN = 1;
    delay100ms();
    U2MODE = _U2MODE_BRGH_MASK | _U2MODE_UARTEN_MASK;
    U2STA  = _U2STA_UTXEN_MASK;
}

/*****************************************************************************/
void blueSetRole(int role)
{
	if (blueMode != BLUE_MODE_AT)
		return;
    char cmd[] = "AT+ROLE=x\r\n";
    cmd[8] = '0' + role;
    blueWriteText(cmd);
    delay100ms();
}

void blueSetName(const char * name)
{
	if (blueMode != BLUE_MODE_AT)
		return;
    char cmd[] = "AT+NAME=";
    blueWriteText(cmd);
    blueWriteText(name);
    blueWriteText("\r\n");
    delay100ms();
}

void blueSetPassword(const char * password)
{
	if (blueMode != BLUE_MODE_AT)
		return;
    char cmd[] = "AT+PSWD=";
    blueWriteText(cmd);
    blueWrite(password, 4);
    blueWriteText("\r\n");
    delay100ms();
}

void blueSetRate(int baudrate)
{
	if (blueMode != BLUE_MODE_AT)
		return;
    char cmd[] = "AT+UART=";
    blueWriteText(cmd);
    blueWriteText(blueRates[baudrate]);
    blueWriteText(",0,0\r\n");
    blueBaud = baudrate;
    delay100ms();
}

/*****************************************************************************/
int blueRead(void * buffer, int length)
{
    int len = length;
    u8 * b = (u8 *) buffer;
    while (blueRXRd != blueRXWr && len) {
        *b ++ = blueRX[blueRXRd ++];
        blueRXRd &= BLUE_RXTX_SIZE - 1;
        len --;
    }
    return length - len;
}

int blueWrite(const void * buffer, int length)
{
    int len = length;
    const u8 * p = (const u8 *) buffer;
    while (len --) {
        while(U2STAbits.UTXBF);
        U2TXREG = * p++;
    }
    return length;
}
/*
int blueWrite(const void * buffer, int length)
{
    int len = length;
    u8 * b = (u8 *) buffer;
    int limit = (blueTXRd - 1) & (BLUE_BUFFER_SIZE - 1);
    while (blueTXWr != limit && len) {
        blueTX[blueTXWr ++] = *b ++;
        blueTXWr &= BLUE_BUFFER_SIZE - 1;
        limit = (blueTXRd - 1) & (BLUE_BUFFER_SIZE - 1);
        len --;
    }
    U2STAbits.UTXEN = 1;
    return length - len;
}
*/
int blueWriteString(const char * string)
{
    int len = 0;
    const char * s = string;
    while (*s ++) len ++;
    return blueWrite(string, len);
}

/*****************************************************************************/
void blueSetDebug(int enable)
{

}

/*****************************************************************************/
void blueRXInterrupt()
{
    IFS1bits.U2RXIF = 0;
    if (!U2STAbits.FERR) {
        u8 d = U2RXREG;
        blueRX[blueRXWr ++] = d;
        blueRXWr &= (BLUE_RXTX_SIZE - 1);
    }
    U2STAbits.OERR = 0;
}

void blueTXInterrupt()
{
    IFS1bits.U2TXIF = 0;
    while(blueTXRd != blueTXWr && !U2STAbits.UTXBF) {
        u8 d = blueTX[blueTXRd ++];
        U2TXREG = d;
        blueTXRd &= (BLUE_RXTX_SIZE - 1);
    }
}
