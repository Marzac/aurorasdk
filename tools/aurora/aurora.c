/**
 * Aurora : serial communication utility
 * 19/07/2015 V0.5
 * (c) Frédéric Meslin 2014 - 2015
 * fredericmeslin@hotmail.com
 * Main program
 
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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include <signal.h>

#include "types.h"
#include "rs232.h"

#define size(s) (sizeof(s) - 1)
void __stdcall Sleep(u32 dwMilliseconds);

/*****************************************************************************/
typedef enum {
	WAIT_NOTHING = 0,
	WAIT_COMPORT,
	WAIT_BAUDRATE,
	WAIT_HEXFILE,
} STATES;

typedef struct {
	char * data;
	size_t length;
	uint pos;
	uint line;
	uint state;
} Program;

int ctrlC;
int port;
Program pgm;

/*****************************************************************************/
#define RXTXBUF_SIZE		256
#define UART_BAUDRATE		230400

const char cmdWhoAreYou[]	= "WAY\n";
const char cmdErase[]		= "ERASE\n";
const char cmdReboot[]		= "REBOOT\n";
const char cmdRun[]			= "RUN\n";
const char cmdVersion[]		= "VERSION\n";
const char cmdLED1[]		= "LED1\n";
const char cmdLED2[]		= "LED2\n";

const char auroraBoot[]		= "AURORA-BOOT\n";
const char auroraSoft[]		= "AURORA-SOFT\n";
const char bootAck			= 'A';
const char bootSum			= 'S';
const char bootErr			= 'E';

/*****************************************************************************/
int  auroraConnect(const char * port, int baudrate);
bool auroraCheck(int port);
int  auroraErase(int port);
int  auroraProgram(int port, FILE * hexfile);
void auroraGetVersion(int port);

int    programLoad(Program * pgm, FILE * hexfile);
void   programFree(Program * pgm);
size_t programNextLine(Program * pgm, char * buffer, size_t length);
void   programDrawBar(Program * pgm);
void   programRefreshBar(Program * pgm);

int  getReply(int port, char * buffer, int bufferLen, int timeout);
void flushReply(int port, int timeout);

void waitms(int timeout);
int diffms(struct timeval t1, struct timeval t2);

void displayTime(struct timeval start, struct timeval stop);
void lowercase(char * text);
void signalHandler(int signal);

/*****************************************************************************/
int main(int argc, char * argv[])
{
	int i;
	FILE * hexFile;
	const char * hexName = NULL;
	const char * portName = NULL;
	int  baudrate = UART_BAUDRATE;
	bool list = false;
	bool reboot = false;
	bool run = false;
	bool erase = false;
	bool version = false;
	bool led1 = false;
	bool led2 = false;
// Display information
	printf("aurora : communication / debugging tool\n");
	printf("         19/07/2015 - version 0.5\n");
	printf("(c) Frederic Meslin 2014 - 2015 / fredericmeslin@hotmail.com\n");
	printf("    Please follow me on twitter : @marzacdev\n");
	if (argc <= 1) {
		printf("usage   : aurora.exe [-c auto][-b 230400][-l][-e][-r][-x][-v][-tx][-f program.hex]\n");
		printf("options : -c com port, win32 (COM1, COM2 ...) (default: auto)\n");
		printf("          -b baudrate, speed of serial transmission (default: 230400)\n");
		printf("          -l, list available com ports\n");
		printf("          -e, erase DSP flash memory\n");
		printf("          -r, reboot DSP\n");
		printf("          -x, run DSP user program\n");
        printf("          -v, get console hardware and bootloader revision\n");
		printf("          -tx, x = 1 or 2, toggle debug LEDs state\n");
		printf("          -f hexfile, flash a program in DSP flash\n");
		return -1;
	}
// Setup the signal handler
	ctrlC = 0;
	port = -1;
	memset(&pgm, 0, sizeof(Program));
	signal(SIGINT, signalHandler);
	signal(SIGTERM, signalHandler);
// Parse command line arguments
	STATES state = WAIT_NOTHING;
	for (i = 1; i < argc; i++) {
		switch(state) {
		case WAIT_COMPORT:
			portName = argv[i];
			state = WAIT_NOTHING;
			break;
		case WAIT_BAUDRATE:
			sscanf(argv[i], "%i", &baudrate);
			state = WAIT_NOTHING;
			break;
		case WAIT_HEXFILE:
			hexName = argv[i];
			state = WAIT_NOTHING;
			break;
		default:
			lowercase(argv[i]);
			if (strcmp(argv[i], "-c") == 0) state = WAIT_COMPORT;
			else if (strcmp(argv[i], "-b") == 0) state = WAIT_BAUDRATE;
			else if (strcmp(argv[i], "-l") == 0) list = true;
			else if (strcmp(argv[i], "-e") == 0) erase = true;
			else if (strcmp(argv[i], "-r") == 0) reboot = true;
			else if (strcmp(argv[i], "-x") == 0) run = true;
			else if (strcmp(argv[i], "-f") == 0) state = WAIT_HEXFILE;
			else if (strcmp(argv[i], "-v") == 0) version = true;
			else if (strcmp(argv[i], "-t1") == 0) led1 = true;
			else if (strcmp(argv[i], "-t2") == 0) led2 = true;
			break;
		}
	}
	if (state != WAIT_NOTHING) {
		printf("Error in command line syntax !\n");
		return -1;
	}
// Enumerate available ports
	int noPorts = comEnumerate();
	if (list) {
		printf("Available communication ports:\n");
		for (i = 0; i < noPorts; i++)
			printf("\t %s\n", comGetPortName(i));
	}
// Connect to aurora
	port = auroraConnect(portName, baudrate);
	if (port == -1) {
		printf("Device not attached or not powered !\n");
		return -1;
	}else printf("Device found on port: %s\n", comGetPortName(port));
// Execute some commands
	if (version) auroraGetVersion(port);
// Erase the console
	if (erase) auroraErase(port);
// Program the console
	if (hexName) {
		hexFile = fopen(hexName, "rb");
		if (!hexFile) printf("Unable to open hex file %s !\n", hexName);
		else {
			auroraProgram(port, hexFile);
			fclose(hexFile);
			reboot = false;
		}
	}
// Toggle the LEDs state
	if (led1) comWrite(port, cmdLED1, size(cmdLED1));
	if (led2) comWrite(port, cmdLED2, size(cmdLED2));
// Reboot the console
	if (reboot) comWrite(port, cmdReboot, size(cmdReboot));
// Launch user program
	if (run) comWrite(port, cmdRun, size(cmdRun));
	comClose(port);

	return 0;
}

/*****************************************************************************/
int auroraConnect(const char * port, int baudrate)
{
	int p;
	if (port) {
	// Open a specific port
		p = comFindPort(port);
		if (p == -1) {
			printf("Port not available: %s !\n", port);
			return -1;
		}
		if (!comOpen(p, baudrate)) {
			printf("Unable to open port %s !\n", port);
			return -1;
		}
		if (auroraCheck(p)) return p;
		else comClose(p);
	}else{
	// Find the port by polling
		int noPorts = comGetNoPorts();
		for (p = 0; p < noPorts; p++) {
			if (!comOpen(p, baudrate)) continue;
			if (auroraCheck(p)) return p;
			else comClose(p);
		}
	}
	return -1;
}

bool auroraCheck(int port)
{
	char buffer[32];
	comWrite(port, cmdWhoAreYou, size(cmdWhoAreYou));
	int res = getReply(port, buffer, size(auroraBoot), 500);
	if (res == size(auroraBoot)) {
	//Check for bootloader
		if (memcmp(auroraBoot, buffer, size(auroraBoot)) == 0) return true;
	//Check for software
		if (memcmp(auroraSoft, buffer, size(auroraSoft)) == 0) {
		// Reboot the machine
			comWrite(port, cmdReboot, size(cmdReboot));
			waitms(500);
		// Ask for bootloader
			for (int t = 0; t < 10; t++) {
				comWrite(port, cmdWhoAreYou, size(cmdWhoAreYou));
				int res = getReply(port, buffer, size(auroraBoot), 500);
				if (res == size(auroraBoot))
					if (memcmp(auroraBoot, buffer, size(auroraBoot)) == 0) return true;
				flushReply(port, 500);
			}
		}
	}
	return false;
}

/*****************************************************************************/
int auroraErase(int port)
{
	char error;
	struct timeval start, stop;
	gettimeofday(&start, NULL);
	comWrite(port, cmdErase, size(cmdErase));
	int res = getReply(port, &error, 1, 30000);
	if (res == 1) {
		if (error == bootAck) {
			gettimeofday(&stop, NULL);
			printf("Erase succeeded !\n");
			displayTime(start, stop);
			return 1;
		}
	}else if (res == 0) {
		printf("No reply, erase failed !\n");
		return 0;
	}
	printf("Unknown reply !\n");
	return 0;
}

void auroraGetVersion(int port)
{
	char buffer[65];
	comWrite(port, cmdVersion, size(cmdVersion));
	int res = getReply(port, buffer, 64, 5000);
	buffer[res] = '\0';
	printf(buffer);
}

int auroraProgram(int port, FILE * hexfile)
{
	char error;
	char line[RXTXBUF_SIZE];
	struct timeval start, stop;
	gettimeofday(&start, NULL);
	if (!programLoad(&pgm, hexfile)) return 0;
	programDrawBar(&pgm);
	size_t size;
	while ((size = programNextLine(&pgm, line, sizeof(line)))) {
		int res, retries = 4;
		do {
			comWrite(port, line, size);
			res = getReply(port, &error, 1, 5000);
			if (ctrlC) {
				printf("\nUser break, flashing aborted !\n");
				programFree(&pgm);
				return 0;
			}
			if (res) {
				if (error == bootSum) {
					printf("\nChecksum error line %i\n", pgm.line);
					programDrawBar(&pgm);
					res = 0;
				}else if (error == bootErr) {
					printf("\nGeneric error line %i\n", pgm.line);
					programDrawBar(&pgm);
					res = 0;
				}
			}else {
				printf("\nNo reply line %i\n", pgm.line);
				programDrawBar(&pgm);
			}
		} while (!res && retries --);
		if (!res) {
			printf("\nToo many errors, flashing aborted !\n");
			programFree(&pgm);
			return 0;
		}
		programRefreshBar(&pgm);
	}
	gettimeofday(&stop, NULL);
	printf("\nFlashing succeeded\n");
	displayTime(start, stop);
	programFree(&pgm);
	return 1;
}

/*****************************************************************************/
int programLoad(Program * pgm, FILE * hexfile)
{
	fseek(hexfile, 0, SEEK_END);
	pgm->length = ftell(hexfile);
	fseek(hexfile, 0, SEEK_SET);
	if (!pgm->length) {
		printf("Program file empty !\n");
		return 0;
	}
	pgm->data = (char *) malloc (pgm->length);
	if (!pgm->data) {
		printf("Cannot allocate enough memory : 0x%X bytes !\n", pgm->length);
		return 0;
	}
	if (fread(pgm->data, pgm->length, 1, hexfile) == 0) {
		printf("Cannot read program file !\n");
		free(pgm->data);
		return 0;
	}
	printf("Program file loaded, size 0x%X\n", pgm->length);
	return 1;
}

size_t programNextLine(Program * pgm, char * buffer, size_t length)
{
	size_t len = length;
	if (pgm->pos == pgm->length) return 0;
	while (len) {
	// End of program
		if (pgm->pos == pgm->length) {
			printf("\nUnexpected end of file on line : %i !\n", pgm->line);
			return 0;
		}
	// Load a character
		char c = pgm->data[pgm->pos++];
		if (c == '\r') continue;
		* buffer ++ = c; len --;
		if (c == '\n') {
			pgm->line ++;
			return length - len;
		}
	}
	printf("\nToo many characters on line : %i !\n", pgm->line);
	return 0;
}

void programFree(Program * pgm)
{
	if (pgm->data) free(pgm->data);
}

/*****************************************************************************/
void programDrawBar(Program * pgm)
{
	int i;
	printf("--------------------------------------------------\n");
	printf("Flashing program:\n");
	printf("0%%                                            100%%\n");
	for (i = 0; i < pgm->state; i++)
		putchar('=');
}

void programRefreshBar(Program * pgm)
{
	uint d;
	d = (50 * pgm->pos + pgm->length / 2) / pgm->length;
	d -= pgm->state;
	if (!d) return;
	pgm->state += d;
	while (d --) putchar('=');
}

void displayTime(struct timeval start, struct timeval stop)
{
	int delta = (int) diffms(stop, start);
	int minutes = delta / 60000;
	int seconds = (delta % 60000) / 1000;
	printf("Elapsed time: %i'%02i\"\n\n", minutes, seconds);
}

/*****************************************************************************/
int getReply(int port, char * buffer, int length, int timeout)
{
	struct timeval start, now;
	int remain = length;
	gettimeofday(&start, NULL);
	while (!ctrlC) {
		int nb = comRead(port, buffer, remain);
		buffer += nb;
		remain -= nb;
		gettimeofday(&now, NULL);
		if (!remain || diffms(now, start) > timeout) break;
		Sleep(0);
	}
	return length - remain;
}

void flushReply(int port, int timeout)
{
	struct timeval start, now;
	char buffer[16];
	gettimeofday(&now, NULL);
	while (!ctrlC) {
		while (comRead(port, buffer, 16));
		gettimeofday(&now, NULL);
		if (diffms(now, start) > timeout) break;
		Sleep(0);
	}
}

/*****************************************************************************/
void waitms(int timeout)
{
	struct timeval start, now;
	gettimeofday(&start, NULL);
	while (!ctrlC) {
		gettimeofday(&now, NULL);
		if (diffms(now, start) > timeout) break;
		Sleep(0);
	}
}

int diffms(struct timeval t1, struct timeval t2)
{
	int ms = (t1.tv_sec - t2.tv_sec) * 1000;
	ms += (t1.tv_usec - t2.tv_usec + 500) / 1000;
    return ms;
}

/*****************************************************************************/
void signalHandler(int signal)
{
	if (signal == SIGINT) {
		if (++ ctrlC < 5) return;
	}else if (signal != SIGTERM) return;
	if (port != -1) comClose(port);
	if (pgm.data) free(pgm.data);
	_fcloseall();
	exit(0);
}

/*****************************************************************************/
void lowercase(char * text)
{
	char * p = text;
	while (*p) {
		if (*p >= 'A' && *p <= 'Z') *p += 'a'- 'A';
		p++;
	}
}
