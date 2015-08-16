/*
 * File:   pads.h
 * Author: Marzac, (c) Frederic Meslin 2013 - 2015
 * Date:   03/01/15
 * Brief:  aurora : gamepads routines
 
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

#ifndef PADS_H
#define	PADS_H

    #include "../aurora.h"

/******************************************************************************/
/* Gamepads names and controls groups */
    typedef enum {
        PAD1 = 0,
        PAD2 = 1,
        PAD3 = 2,
        PAD4 = 3
    }PADS;

    typedef enum {
        GROUPA = 0,
        GROUPB = 1
    }GROUPS;

/* Gamepads controls bitmasks */
    typedef enum {
        DPAD_UP     = 0x1,
        DPAD_DOWN   = 0x2,
        DPAD_LEFT   = 0x4,
        DPAD_RIGHT  = 0x8,
        BUT_B       = 0x10,
        BUT_C       = 0x20
    }GROUPA_BITS;

    typedef enum {
        BUT_A       = 0x10,
        BUT_START   = 0x20
    }GROUPB_BITS;

/******************************************************************************/
/* Gamepads functions */
    void padsPower(int enable);
    int  padsRead(int pad, int group);


#endif	/* PADS_H */

