/**
 * Aurora : serial communication utility
 * 19/07/2015 V0.5
 * (c) Fr�d�ric Meslin 2014 - 2015
 * fredericmeslin@hotmail.com
 * Main program

  The MIT License (MIT)
  Copyright (c) 2007 - 2015 Fr�d�ric Meslin
  Contact: fredericmeslin@hotmail.com, @marzacdev
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.

*/

/****************************************************************************/
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "types.h"
#include "rs232.h"

/****************************************************************************/
#ifndef WIN32
	#ifndef LINUX
		#error rs232 : unsupported architecture
	#endif
#endif

#ifdef WIN32
	#include "rs232_win.c"
#endif

#ifdef LINUX
	#include "rs232_linux.c"
#endif

#ifdef MACOS
	#include "rs232_win.c"
#endif
