/**
 * Aurora : wavefile converter
 * 19/10/2014 V0.1
 * (c) Frédéric Meslin 2007 - 2014
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
#include <stdint.h>
#include <string.h>

/*****************************************************************************/
typedef int8_t      s8;
typedef int16_t     s16;
typedef int32_t     s32;
typedef int64_t     s64;
typedef uint8_t     u8;
typedef uint16_t    u16;
typedef uint32_t    u32;
typedef uint32_t    u64;

/*****************************************************************************/
#ifndef _WAVEFORMATEX
#define _WAVEFORMATEX
typedef struct {
	u16 wFormatTag;
	u16 nChannels;
	u32 nSamplesPerSec;
	u32 nAvgBytesPerSec;
	u16 nBlockAlign;
	u16 wBitsPerSample;
	u16 cbSize;
} WAVEFORMATEX;
#endif

#ifndef _RIFFCHUNK
#define _RIFFCHUNK
typedef struct {
	u32 ID;
	u32 size;
} RIFFCHUNK;
#endif

#define MAX_CHANNELS	8
typedef struct {
	u8 channels;
	size_t len;
	s16 * data[MAX_CHANNELS];
} WAV;

/*****************************************************************************/
int  wavRead(FILE * file, WAV * wav);
void wavMixMono(WAV * wav);

void hWriteProto(FILE * file, WAV * wav, const char * varName);
void hWriteSamples(FILE * file, WAV * wav, int channel, const char * varName);
void hWriteSize(FILE * file, WAV * wav, const char * varName);

u16 smp2pwm(s16 s);

size_t findChunk(FILE * file, u32 ID, size_t length);
void lowercase(char * text);

/*****************************************************************************/
const u32 riffID   = 0x46464952; // "RIFF" string
const u32 riffWAVE = 0x45564157; // "WAVE" string
const u32 fmtID    = 0x20746d66; // "fmt " string
const u32 dataID   = 0x61746164; // "data" string

int main(int argc, char * argv[])
{
	int i;
	FILE * wavFile;
	FILE * headerFile;
	char * wavName = "in.wav";
	char * headerName = "out.h";
	char * dataName = "sample";
	u8 toMono = 0;
	WAV waveform;

// Display information	
	printf("wav2h : utility to convert wavefiles in h files\n");
	printf("        18/11/2014 - version 0.1\n");
	printf("(c) Frederic Meslin 2014 - fredericmeslin@hotmail.com\n");
	printf("    Please follow me on twitter : @marzacdev\n");
	if (argc <= 1) {
		printf("usage   : wav2h.exe [in.wav] [out.h] [-n sample] [-m]\n");
		printf("options : -n, constant name, (default: sample)\n");
		printf("          -m, mixdown stereo format to mono format\n");
		return -1;
	}
// Parse the basic arguments
	if (argc >= 2 && *argv[1] != '-') wavName = argv[1];
	if (argc >= 3 && *argv[2] != '-') headerName = argv[2];
// Parse the options
	for (i = 1; i < argc; i++) {
		if (strcmp(argv[i], "-m") == 0) toMono = 1;
		else if (strcmp(argv[i], "-M") == 0) toMono = 1;
	}
// Open the required files
	wavFile = fopen(wavName, "rb");
	if (!wavFile) {
		printf("Unable to open wav file %s!\n", wavName);
		return -1;
	}
	headerFile = fopen(headerName, "wb");
	if (!headerFile) {
		printf("Unable to open header file %s!\n", headerFile);
		fclose(wavFile);
		return -1;
	}
// Process the audio data
	memset(&waveform, 0, sizeof(WAV));
	wavRead(wavFile, &waveform);
	if (toMono) wavMixMono(&waveform);
	hWriteProto(headerFile, &waveform, dataName);
	for (i = 0; i < waveform.channels; i++) {
		hWriteSamples(headerFile, &waveform, i, dataName);
		free(waveform.data[i]);
	}
	hWriteSize(headerFile, &waveform, dataName);
// Free the ressources
	fclose(wavFile);
	fclose(headerFile);
	return 0;
}


/*****************************************************************************/
int wavRead(FILE * file, WAV * wav)
{
	int i;
	RIFFCHUNK riffChunk;
	RIFFCHUNK formatChunk;
	RIFFCHUNK dataChunk;
	WAVEFORMATEX wavFormat;
	u32 rifffmt = 0;
// Find the RIFF chunk
	size_t size = findChunk(file, riffID, 0);
	fread(&rifffmt, 4, 1, file);
	if (rifffmt != riffWAVE) return 0;
	long pos = ftell(file);
// Find the format chunk	
	fseek(file, pos, SEEK_SET);
	findChunk(file, fmtID, size);
	fread(&wavFormat, sizeof(WAVEFORMATEX), 1, file);
	if (wavFormat.nChannels > MAX_CHANNELS) return 0;
// Find the data chunk		
	fseek(file, pos, SEEK_SET);
	size = findChunk(file, dataID, size);
// Allocate the audio buffers
	wav->len  = size / wavFormat.nChannels;
	wav->len /= wavFormat.wBitsPerSample >> 3;
	wav->len *= sizeof(u16);
	for (i = 0; i < wavFormat.nChannels; i ++)
		wav->data[i] = malloc(wav->len);
	wav->channels = wavFormat.nChannels;
// Display informations
	printf("Wave file format :\n");
	printf("  Channels : %i\n", wav->channels);
	printf("  Bits per sample : %i bits\n", wavFormat.wBitsPerSample);
	printf("  Length : %i \n", wav->len >> 1);
// Load and convert audio data
	s32 v = 0;
	u32 s, smp = wav->len >> 1;
	u32 bps = wavFormat.wBitsPerSample >> 3; 
	s32 shift = 32 - wavFormat.wBitsPerSample;
	s32 offset = bps == 1 ? -128 : 0;
	for (s = 0; s < smp; s++) {
		for (i = 0; i < wavFormat.nChannels; i ++) {
			fread(&v, bps, 1, file);
			v = (v + offset) << shift;
			(wav->data[i])[s] = (s16) (v >> 16); 
		}
	}
	return wav->channels;
}

/*****************************************************************************/
void wavMixMono(WAV * wav)
{
	u8 c;
	u32 s, smp = wav->len >> 1;
	for (s = 0; s < smp; s++) {
		s32 acc = 0;
		for (c = 0; c < wav->channels; c++)
			acc += (wav->data[c])[s];
		acc /= wav->channels;
		wav->data[0][s] = (s16) acc;
	}
	for (c = 1; c < wav->channels; c++)
		free(wav->data[c]);
	wav->channels = 1;
}

/*****************************************************************************/
void hWriteProto(FILE * file, WAV * wav, const char * varName)
{
	if (wav->channels == 1) {
		fprintf(file, "extern const u16 SFX %s[];\n", varName);
	}else{
		u8 c;
		for (c = 0; c < wav->channels; c++)
			fprintf(file, "extern const u16 SFX %sChan%i[];\n", varName, c + 1);
	}
	fprintf(file, "extern const u32 SFX %sSize;\n\n", varName);
}

#define BLOCKS_SIZE	16
void hWriteSamples(FILE * file, WAV * wav, int channel, const char * varName)
{
	u32 b, i;
	u16 * p = wav->data[channel];
	u32 smp = wav->len >> 1;
	u32 cnt = smp / BLOCKS_SIZE;
	if (wav->channels == 1)
		fprintf(file, "const u16 SFX %s[] = {\n", varName);
	else
		fprintf(file, "const u16 SFX %sChan%i[] = {\n", varName, channel + 1);
	for (b = 0; b < cnt; b ++) {
		for (i = 0; i < BLOCKS_SIZE; i ++)
			fprintf(file, "0x%04X, ", smp2pwm(*p++));
		fprintf(file, "\n");
	}
	cnt = smp - cnt * BLOCKS_SIZE;
	for (i = 0; i < cnt; i ++)
		fprintf(file, "0x%04X, ", smp2pwm(*p++));
	fprintf(file, "};\n\n");
}

void hWriteSize(FILE * file, WAV * wav, const char * varName)
{
	fprintf(file, "const u32 SFX %sSize = %i;\n", varName, wav->len);
}

/*****************************************************************************/
u16 smp2pwm(s16 s)
{
	return (u16) (0x8000 + s) >> 4;
}

/*****************************************************************************/
size_t findChunk(FILE * file, u32 ID, size_t length)
{
	size_t pos = 0;
	RIFFCHUNK chunk;
	while (pos < length || !length) {
		fread(&chunk, sizeof(RIFFCHUNK), 1, file);
		if (chunk.ID == ID) return chunk.size;
		fseek(file, chunk.size, SEEK_CUR);
		pos += sizeof(RIFFCHUNK) + chunk.size;
		if (feof(file)) break; 
	}
	return 0;
}

void lowercase(char * text)
{
	char * p = text;
	while (*p) {
		if (*p >= 'A' && *p <= 'Z') *p += 'a'- 'A';
		p++;
	}
}
