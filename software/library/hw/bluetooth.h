/*
 * File:   bluetooth.h
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

#ifndef BLUETOOTH_H
#define	BLUETOOTH_H

    #include "../aurora.h"

    #define BLUE_RXTX_SIZE    64    /** Receiving and transmitting buffer sizes */

/******************************************************************************/
    typedef enum {
        BLUE_4800    = 0,
        BLUE_9600    = 1,
        BLUE_19200   = 2,
        BLUE_38400   = 3,
        BLUE_57600   = 4,
        BLUE_115200  = 5,
        BLUE_230400  = 6,
        BLUE_460800  = 7,
        BLUE_921600  = 8,
        BLUE_1382400 = 9,
    }BLUE_BAUDS;

    typedef enum {
        BLUE_MODE_COM = 0,
        BLUE_MODE_AT = 1
    }BLUE_MODES;

    typedef enum {
        BLUE_ROLE_SLAVE = 0,
        BLUE_ROLE_MASTER = 1,
        BLUE_ROLE_SLAVE_LOOP = 2,
    }BLUE_ROLES;

/******************************************************************************/
    void blueInit();
    void blueConfigure();

    void blueSetMode(int mode);
    void blueSetRole(int role);
    void blueSetName(const char * name);
    void blueSetPassword(const char * pass);
    void blueSetRate(int baud);

    int blueRead(void * buffer, int size);
    int blueWrite(const void * buffer, int size);
    int blueWriteText(const char * text);

    void blueEnableDebug(int enable);

#endif	/* BLUETOOTH_H */
