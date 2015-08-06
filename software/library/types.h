/*
 * File:   types.h
 * Author: Marzac (Frédéric Meslin)
 * Date:   18/11/14
 * Brief:  Handy types and macros
 
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

#ifndef TYPES_H
#define	TYPES_H

    #include <stdint.h>

    typedef int8_t          s8;
    typedef int16_t         s16;
    typedef int32_t         s32;
    typedef int64_t         s64;
    typedef uint8_t         u8;
    typedef uint16_t        u16;
    typedef uint32_t        u32;
    typedef uint32_t        u64;

    typedef unsigned int    uint;
    typedef int16_t         bool;
    #define true            -1
    #define false           0

    typedef void *          RamPtr;
    typedef uint16_t        FlashPtr;
    typedef uint16_t        FlashPage;
    typedef uint16_t        FunctionPtr;
    typedef uint16_t        FunctionPage;

    #define FLASHPTR(p)     ((FlashPtr) __builtin_psvoffset(p))
    #define FLASHPAGE(p)    ((FlashPage) __builtin_psvpage(p))
    #define FUNCTIONPTR(p)  ((FunctionPtr) __builtin_tbloffset(p))
    #define FUNCTIONPAGE(p) ((FunctionPage) __builtin_tblpage(p))


#endif	/* TYPES_H */

