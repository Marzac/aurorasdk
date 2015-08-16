/*
 * File:   bluetooth.h
 * Author: Marzac, (c) Frederic Meslin 2013 - 2015
 * Date:   18/11/14
 * Brief:  aurora : Bluetooth serial communications
 *
 * This module makes use of UART2 peripheral
  
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

#ifndef USB_H
#define	USB_H

    #include "../aurora.h"

    #define USB_RXTX_SIZE    64    /** Receiving and transmitting buffer sizes */

/******************************************************************************/
    typedef enum {
        USB_4800    = 0,
        USB_9600    = 1,
        USB_19200   = 2,
        USB_38400   = 3,
        USB_57600   = 4,
        USB_115200  = 5,
        USB_230400  = 6,
        USB_460800  = 7,
        USB_921600  = 8,
        USB_1382400 = 9,
    }USB_BAUDS;

/******************************************************************************/
    void usbInit();
    void usbSetRate(int baudrate);

    int usbRead(void * buffer, int size);
    int usbWrite(const void * buffer, int size);
    int usbWriteString(const char * string);

    void usbSetDebug(int enable);

#endif	/* USB */
