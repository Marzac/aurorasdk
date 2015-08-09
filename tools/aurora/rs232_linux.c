/*
    Cross-platform serial / RS232 library
    Version 0.1, 16/06/2015
    -> LINUX and MacOS implementation
    -> rs232-linux.c

	The MIT License (MIT)

	Copyright (c) 2013-2015 Frédéric Meslin, Florent Touchard
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

#if defined(__unix__) || defined(__unix) || \
	defined(__APPLE__) && defined(__MACH__)

#define _DARWIN_C_SOURCE

#include <unistd.h>
#include <termios.h>
#include <fcntl.h>
#include <string.h>

int comEnumerate();
int comGetNoPorts();

const char * comGetPortName(int index);
int comFindPort(const char * name);
const char * comGetInternalName(int index);

/*****************************************************************************/
typedef struct {
	const char * port;
	int handle;
} COMDevice;

static COMDevice comDevices[] = { // TODO: Real enumeration
    {"/dev/ttyS0",   -1},
    {"/dev/ttyS1",   -1},
    {"/dev/ttyS2",   -1},
    {"/dev/ttyUSB0", -1},
    {"/dev/ttyUSB1", -1},
    {"/dev/ttyUSB2", -1},
    {"/dev/rfcomm0", -1}
};

static unsigned int noDevices = sizeof(comDevices)/sizeof(*comDevices);

/*****************************************************************************/
int _BaudFlag(int BaudRate)
{
    switch(BaudRate)
    {
        case 50:      return B50; break;
        case 110:     return B110; break;
        case 134:     return B134; break;
        case 150:     return B150; break;
        case 200:     return B200; break;
        case 300:     return B300; break;
        case 600:     return B600; break;
        case 1200:    return B1200; break;
        case 1800:    return B1800; break;
        case 2400:    return B2400; break;
        case 4800:    return B4800; break;
        case 9600:    return B9600; break;
        case 19200:   return B19200; break;
        case 38400:   return B38400; break;
        case 57600:   return B57600; break;
        case 115200:  return B115200; break;
        case 230400:  return B230400; break;
        default : return B0; break;
    }
}

/*****************************************************************************/
int comEnumerate()
{
    return noDevices;
}

int comGetNoPorts()
{
    return noDevices;
}

int comFindPort(const char * name)
{
    int p;
    for (p = 0; p < noDevices; p++)
        if (strcmp(name, comDevices[p].port) == 0)
            return p;
    return -1;
}

const char * comGetInternalName(int index)
{
    return comGetPortName(index);
}

const char * comGetPortName(int index) {
    if (index >= noDevices || index < 0)
        return 0;
    return comDevices[index].port;
}

int comOpen(int index, int baudrate)
{
    if (index >= noDevices || index < 0)
        return 0;
// Open port
	COMDevice * com = &comDevices[index];
    const char * name = com->port;
    int handle = open(name, O_RDWR | O_NOCTTY | O_NDELAY);
    if (handle < 0)
        return 0;
// General configuration
    struct termios config;
    memset(&config, 0, sizeof(config));
    tcgetattr(handle, &config);
    config.c_cflag &= ~(PARENB | PARODD | CSTOPB | CSIZE | CRTSCTS);
    config.c_cflag |= CLOCAL | CREAD | CS8;
    config.c_lflag &= ~(ICANON | ISIG | ECHO);
    config.c_iflag |= IGNPAR | IGNBRK;
    config.c_oflag &= ~OPOST;
    int flag = _BaudFlag(baudrate);
    cfsetospeed(&config, flag);
    cfsetispeed(&config, flag);
// Timeouts configuration
    config.c_cc[VTIME] = 1;
    config.c_cc[VMIN]  = 0;
    //fcntl(handle, F_SETFL, FNDELAY);
// Validate configuration
    if (tcsetattr(handle, TCSANOW, &config) < 0) {
        close(handle);
        return 0;
    }
    com->handle = handle;
    return 1;
}

void comClose(int index)
{
    if (index >= noDevices || index < 0)
    	return;
    COMDevice * com = &comDevices[index];
    if (com->handle < 0) 
    	return;
    tcflush(com->handle, TCIOFLUSH);
    close(com->handle);
    com->handle = -1;
}

void comCloseAll()
{
	for (int i = 0; i < noDevices; i++)
		comClose(i);
	
}

int comWrite(int index, const char * buffer, size_t len)
{
    if (index >= noDevices || index < 0)
    	return 0;
	if (comDevices[index].handle <= 0)
        return 0;
    int res = write(comDevices[index].handle, buffer, len);
    if (res < 0)
        res = 0;
    return res;
}

int comRead(int index, char * buffer, size_t len)
{
    if (index >= noDevices || index < 0)
    	return 0;
	if (comDevices[index].handle <= 0)
        return 0;
    int res = read(comDevices[index].handle, buffer, len);
    if (res < 0)
        res = 0;
    return res;
}

#endif // unix
