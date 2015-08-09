/**
 * Aurora : bitmap tileset converter
 * 03/01/2015 V0.3
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
  
 * TODO: bitmap export should preserve alpha channel
*/

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#define __USE_XOPEN_EXTENDED // for strdup
#include <string.h>

/*****************************************************************************/
typedef int8_t      	s8;
typedef int16_t     	s16;
typedef int32_t     	s32;
typedef int64_t     	s64;
typedef uint8_t     	u8;
typedef uint16_t    	u16;
typedef uint32_t    	u32;
typedef uint64_t   		u64;
typedef unsigned int	uint;

/*****************************************************************************/
#pragma pack(push, 1)
typedef struct  __attribute__((__packed__)) {
	u16 bfType;
	u32 bfSize;
	s16 bfReserved1;
	s16 bfReserved2;
	u32 bfOffBits;
} BITMAPFILEHEADER;
#pragma pack(pop)

#pragma pack(push, 1)
typedef struct  __attribute__((__packed__)) {
	u32 biSize;
	s32 biWidth;
	s32 biHeight;
	s16 biPlanes;
	s16 biBitCount;
	u32 biCompression;
	u32 biSizeImage;
	s32 biXPelsPerMeter;
	s32 biYPelsPerMeter;
	u32 biClrUsed;
	u32 biClrImportant;
} BITMAPINFOHEADER;
#pragma pack(pop)

#pragma pack(push, 1)
typedef struct {
	u32 mR;
	u32 mG;
	u32 mB;	
	u32 mA;
} BITMAPCOLORMASK;
#pragma pack(pop)

#ifndef BI_RGB
	#define BI_RGB			0
	#define BI_BITFIELDS	3
#endif

typedef struct {
	s32 tx, ty;
	size_t len;
	void * data;
} BMP;

typedef enum {
	WAIT_NOTHING = 0,
	WAIT_GRID,
	WAIT_PAGE,
	WAIT_RADICAL,
	WAIT_COLOR,
} STATES;

#define PAGE_SIZE	0x8000

/*****************************************************************************/
int   bmpRead(FILE * file, BMP * bitmap, u32 color, int noalpha);
void  bmpWrite(FILE * file, BMP * bitmap);

BMP * bmpCut(BMP * bitmap, s32 grid, int * nb);
void  bmpGlue(BMP * bitmap, BMP * tiles, int nb);
void  bmpDiscretise(BMP * bitmap, int bits);

void  writeProto(FILE * hFile, const char * page, const char * name, BMP * bitmap);
void  writeArray(FILE * cFile, const char * page, const char * name, BMP * bitmap);

u16  pixtoport(const u8 * rgb);
u32  getcolor(const char * text);
void lowercase(char * text);
void uppercase(char * text);

/*****************************************************************************/
int main(int argc, char * argv[])
{
	char name[512];
	BMP bitmap;
	BMP * tiles = NULL;
	int noTiles = 0;
	FILE * bmpFile = NULL;
	FILE * hFile = NULL;
	FILE * cFile = NULL;
// Tool configuration	
	char * bmpName = "in.bmp";
	char * cName   = "out.c";
	char * hName   = NULL;
	char * hDefine = NULL;
	char * radical = "tiles";
	char * page = NULL;
	u32  color = 0xFF00FF;
	uint grid = 16;
	int extract = 0;
	int compact = 0;
	int noalpha = 0;
	int export = 0;
	int errCode = 0;
// Display information	
	printf("bmp2c : utility to convert bitmaps in c/h files\n");
	printf("        09/06/2015 - version 0.3\n");
	printf("(c) Frederic Meslin 2014 - 2015 / fredericmeslin@hotmail.com\n");
	printf("    Please follow me on twitter : @marzacdev\n\n");
	if (argc <= 1) {
		printf("usage   : bmp2c.exe [in.bmp] [out.c] [-g 16] [-p PAGEA] [-r tile] [-t 0xFF00FF]\n");
		printf("                    [-d] [-x] [-c] [-b]\n");
		printf("options : -g gridsize, size of a single square tile (default: 16)\n");
		printf("          -p page, start page (PAGEA, PAGEB ...) (default: PAGEA)\n");
		printf("          -r radical, radical name for arrays (default: tiles)\n");
		printf("          -t color, transparent color key (default: pink = 0xFF00FF)\n");
		printf("          -d, disable alpha channel and color key\n");
		printf("          -x, extract tiles in individual arrays (for sprites)\n");
		printf("          -c, compact tiles in a column (for tilesets)\n");
		printf("          -b, export the result(s) in bitmap(s)\n");
		printf("          available color formats: 0xRRGGBB or r.g.b\n");
		printf("          example (pink): 0xFF00FF or 255.0.255\n");
		return -1;
	}
// Parse the basic arguments
	if (argc >= 2 && *argv[1] != '-') bmpName = argv[1];
	if (argc >= 3 && *argv[2] != '-') cName = argv[2];
// Check and construct header name	
	int len = strlen(cName);
	if (len > 2 && cName[len-2] == '.' && cName[len-1] == 'c') {
		hName = strdup(cName);
		hName[len-1] = 'h';
		hDefine = strdup(hName);
		uppercase(hDefine);
		hDefine[len-2] = '_';
	}else{
		printf("C output file name is invalid !\n");
		return -1;
	}
	bitmap.data = NULL;
	page = strdup("PAGEA");
// Parse the options	
	STATES state = WAIT_NOTHING;
	for (int i = 1; i < argc; i++) {
		switch (state) {
			case WAIT_GRID:
				sscanf(argv[i], "%u", &grid);
				if (grid < 4) grid = 4;
				state = WAIT_NOTHING;
				break;
			case WAIT_RADICAL:
				radical = argv[i];
				state = WAIT_NOTHING;
				break;
			case WAIT_PAGE:
				uppercase(argv[i]);
				page = argv[i];
				state = WAIT_NOTHING;
				break;
			case WAIT_COLOR:
				color = getcolor(argv[i]);
				state = WAIT_NOTHING;
				break;
			default: 
				lowercase(argv[i]);
				if (strcmp(argv[i], "-g") == 0)  state = WAIT_GRID;
				else if (strcmp(argv[i], "-p") == 0) state = WAIT_PAGE;
				else if (strcmp(argv[i], "-r") == 0) state = WAIT_RADICAL;
				else if (strcmp(argv[i], "-t") == 0) state = WAIT_COLOR;
				else if (strcmp(argv[i], "-d") == 0) noalpha = 1;
				else if (strcmp(argv[i], "-x") == 0) extract = 1;
				else if (strcmp(argv[i], "-c") == 0) compact = 1;
				else if (strcmp(argv[i], "-b") == 0) export = 1;
				else if (i > 2 || argv[i][0] == '-')
					printf("Unknown argument %s !\n\n", argv[i]);
		}
	}
// Check the parsing state	
	if (state != WAIT_NOTHING) {
		printf("Error in command line syntax !\n\n");
		errCode = -1;
		goto finish;
	}
// Open input / output files
	bmpFile = fopen(bmpName, "rb");
	if (!bmpFile) {
		printf("Unable to open image file %s!\n", bmpName);
		errCode = -1;
		goto finish;
	}
	cFile = fopen(cName, "wb");
	if (!cFile) {
		printf("Unable to open code file %s!\n", cName);
		errCode = -1;
		goto finish;
	}
	hFile = fopen(hName, "wb");
	if (!hFile) {
		printf("Unable to open header file %s!\n", hName);
		errCode = -1;
		goto finish;
	}
// Read and format data
	printf("Convert %s -> %s / %s\n", bmpName, cName, hName);
	if (!bmpRead(bmpFile, &bitmap, color, noalpha)) {
		errCode = -1;
		goto finish;
	}		
	if (extract || compact) {
		tiles = bmpCut(&bitmap, grid, &noTiles);
		if (!tiles) {
			errCode = -1;
			goto finish;
		}
		printf("Cut %u tiles\n", noTiles);
	}
	if (compact) {
		bmpGlue(&bitmap, tiles, noTiles);
		printf("Glued %u tiles\n", noTiles);
	}
// Write file headers
	fprintf(hFile, "#ifndef %s\n#define %s\n\n", hDefine, hDefine);
	fprintf(hFile, "\t#include \"aurora.h\"\n\n");
	fprintf(cFile, "#include \"%s\"\n\n", hName);
// Export the pixels
	if (extract){
		int pos = strlen(page) - 1;
		s32 totalLen = PAGE_SIZE;
		s32 tileLen = tiles[0].len >> 1;
		printf("Len %u\n", tileLen);
		int noPages = 1;
		if (tileLen > PAGE_SIZE)
			printf("Warning: single tile too big for a 32k page !\n");
		printf("On flash page %s:", page);
		for (int i = 0; i < noTiles; i++) {
			if (!(i & 0x3)) putchar('\n');
			sprintf(name, "%s%u", radical, i);
			printf("- %s\t", name);
			writeProto(hFile, page, name, &tiles[i]);
			writeArray(cFile, page, name, &tiles[i]);
			if (export) {
				sprintf(name, "x%s%u.bmp", radical, i);
				printf("Export: %s file\n", name);
				FILE * exbmpFile = fopen(name, "wb");
				bmpDiscretise(&tiles[i], 4);
				bmpWrite(exbmpFile, &tiles[i]);
				fclose(exbmpFile);
			}
			totalLen -= tileLen;
			if (totalLen < tileLen) {
				page[pos] ++;
				noPages ++;
				if (i != noTiles - 1) {
					printf("On flash page %s:\n", page);
					totalLen = PAGE_SIZE;
				}
			}
		}
		printf("\nTiles fit on %u page(s) !\n", noPages);
		putc('\n', hFile);
	}else{
		if ((bitmap.len >> 1) > PAGE_SIZE)
			printf("Warning: image too big for a 32k page !\n");
		writeProto(hFile, page, radical, &bitmap);
		writeArray(cFile, page, radical, &bitmap);
		if (export) {
			sprintf(name, "x%s.bmp", radical);
			printf("Export: %s file\n", name);
			FILE * exbmpFile = fopen(name, "wb");
			bmpDiscretise(&bitmap, 4);
			bmpWrite(exbmpFile, &bitmap);
			fclose(exbmpFile);
		}
		putc('\n', hFile);
	}
// Write file footers
	fprintf(hFile, "#endif\n", hDefine);
	printf("Done\n", noTiles);
// Free the ressources	
finish:
	free(page);
	free(hName);
	free(hDefine);
	if (bmpFile) fclose(bmpFile);
	if (cFile) fclose(cFile);
	if (hFile) fclose(hFile);
	if (bitmap.data) free(bitmap.data);
	if (tiles) {
		for (int i = 0; i < noTiles; i++)
			free(tiles[i].data);
		free(tiles);
	}
	return errCode;
}

/*****************************************************************************/
u16 pixtoport(const u8 * rgb)
{
// Extract components
	u16 b = rgb[0] >> 4;
	u16 g = rgb[1] >> 4;
	u16 r = rgb[2] >> 4;
	u16 a = rgb[3] >> 4;
// Build the port value
	u16 p = r | (g << 4) | (b << 8) | (a << 12);
	return p;
}

/*****************************************************************************/
BMP * bmpCut(BMP * bitmap, s32 grid, int * nb)
{
	BMP * tiles;
// Get number of subdivisions
	s32 nx = bitmap->tx / grid;
	if (nx * grid != bitmap->tx) return NULL;
	s32 ny = bitmap->ty / grid;
	if (ny * grid != bitmap->ty) return NULL;
// Allocate tile table
	tiles = (BMP *) malloc(sizeof(BMP) * nx * ny);
// Cut the tiles
	s32 x, y, i = 0;
	for (y = 0; y < ny; y++) {
		for (x = 0; x < nx; x++) {
		// Allocate the bitmap
			BMP * tile = &tiles[i++];
			tile->tx = grid;
			tile->ty = grid;
			tile->len  = grid * grid * sizeof(u32);
			tile->data = malloc(tile->len);
		// Extract the pixels
			s32 px, py;
			u32 * src = bitmap->data;
			src += (y * bitmap->tx + x) * grid;
			u32 * dst = (u32 *)tile->data;
			for (py = 0; py < grid; py ++) {
				memcpy(dst, src, grid * 4);
				dst += tile->tx;
				src += bitmap->tx;
			}
		}
	}
	* nb = nx * ny;
	return tiles;
}

void bmpGlue(BMP * bitmap, BMP * tiles, int nb)
{
// Reallocate memory if needed
	size_t len = tiles[0].len * nb;
	if (bitmap->data) {
		if (bitmap->len < len) {
			void * p = realloc(bitmap->data, len);
			if (p != bitmap->data) {
				free(bitmap->data);
				bitmap->data = (u8 *) p;
			}
		}
	}else bitmap->data = (u8 *) malloc(len);
// Reconfigure the bitmap
	bitmap->len = len;
	bitmap->tx = tiles[0].tx;
	bitmap->ty = tiles[0].ty * nb;
// Glue the tiles
	len = tiles[0].len;
	u32 * dst = (u32 *)bitmap->data;
	for (int i = 0; i < nb; i++) {
		u32 * src = tiles[i].data;
		memcpy(dst, src, len);
		dst += len >> 2;
	}
}

void bmpDiscretise(BMP * bitmap, int bits)
{
	u8 * pix = (u8 *)bitmap->data;
	u8 res[4];
	int shift = 8 - bits;
	for (size_t i = 0; i < bitmap->len; i++) {
		res[0] = (pix[0] >> shift) << shift;
		res[1] = (pix[1] >> shift) << shift;
		res[2] = (pix[2] >> shift) << shift;
		res[3] = (pix[3] >> shift) << shift;
		*(u32 *) pix = *(u32*) res;
	}
}

/*****************************************************************************/
int bmpRead(FILE * file, BMP * bitmap, u32 color, int noalpha)
{
	BITMAPFILEHEADER header;
	BITMAPINFOHEADER info;
	BITMAPCOLORMASK mask = {
		0x00FF0000,
		0x0000FF00,
		0x000000FF,
		0xFF000000
	};
// Read the headers
	fread(&header, sizeof(BITMAPFILEHEADER), 1, file);
	fread(&info, sizeof(BITMAPINFOHEADER), 1, file);
// Check bitmap format
	if (strncmp((char *) &header.bfType, "BM", 2)){
		printf("File not a bitmap !\n");
		return 0;
	}
	if (info.biBitCount != 24 && info.biBitCount != 32) {
		printf("Only 24bits and 32bits bitmaps are supported !\n");
		return 0;
	}
	if (info.biCompression != BI_RGB && info.biCompression != BI_BITFIELDS){
		printf("Compressed bitmaps are not supported !\n");
		return 0;
	}
// Load the bitmasks
	int shiftA = 24;
	int shiftR = 16;
	int shiftG = 8;
	int shiftB = 0;
	if (info.biCompression == BI_BITFIELDS) {
		fread(&mask, sizeof(BITMAPCOLORMASK), 1, file);
		shiftR = __builtin_ffs(mask.mR) - 1;
		shiftG = __builtin_ffs(mask.mG) - 1;
		shiftB = __builtin_ffs(mask.mB) - 1;
		shiftA = __builtin_ffs(mask.mA) - 1;
	}
	
// Retrieve bitmap size
	bitmap->tx = info.biWidth;
	bitmap->ty = info.biHeight;
	u8 upsidedown = 1;
	if (bitmap->ty < 0) {
		bitmap->ty = -bitmap->ty;
		upsidedown = 0;
	}
// Allocate bitmap memory
	s32 srcScan;
	srcScan = bitmap->tx * (info.biBitCount >> 3);
	srcScan = (srcScan + 0x3) & ~0x3;
	bitmap->len = bitmap->tx * bitmap->ty * sizeof(u32);
	bitmap->data = malloc(bitmap->len);
	u8 * buffer = (u8 *) malloc(srcScan);
	u8 * data = (u8 *) bitmap->data;
// Load bitmap data
	s32 dstScan = bitmap->tx * sizeof(u32);
	fseek(file, header.bfOffBits, SEEK_SET);
	if (upsidedown)
		data += dstScan * (bitmap->ty - 1);
	if (info.biBitCount == 32) {
	// Parse a 32 bits image
		u32 alpha = noalpha ? 0xFF : 0x00;
		for (int y = 0; y < bitmap->ty; y ++) {
			u32 a, r, g, b;
			fread(buffer, srcScan, 1, file);
			u32 * d = (u32 *) data;
			u32 * s = (u32 *) buffer;
			for (int i = 0; i < bitmap->tx; i ++) {
				u32 c = *s++;
				a = (c & mask.mA) >> shiftA;
				r = (c & mask.mR) >> shiftR;
				g = (c & mask.mG) >> shiftG;
				b = (c & mask.mB) >> shiftB;
				a |= alpha;
				*d++ = (a == 0 ? c = 0 : (a << 24) | (r << 16) | (g << 8) | b);
			}
			if (upsidedown) 
				data -= dstScan;
			else data += dstScan;
		}
	}else{
	// Parse a 24 bits image
		for (size_t y = 0; y < bitmap->ty; y ++) {
			u32 r, g, b;
			fread(buffer, srcScan, 1, file);
			u32 * d = (u32 *) data;
			u8  * s = buffer;
			for (int i = 0; i < bitmap->tx; i ++) {
				b = * s++;
				g = * s++;
				r = * s++;
				u32 c = (r << 16) | (g << 8) | b;
				* d++ = (c == color ? 0 : (0xFF << 24) | c);
			}
			if (upsidedown) 
				data -= dstScan;
			else data += dstScan;
		}
	}
	free(buffer);
	return 1;
}
/*****************************************************************************/
#define HEAD_LEN sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER) + sizeof(BITMAPCOLORMASK)
void bmpWrite(FILE * file, BMP * bitmap)
{
	s32 y;
	BITMAPFILEHEADER header;
	BITMAPINFOHEADER info;
	BITMAPCOLORMASK mask = {
		0x00FF0000,
		0x0000FF00,
		0x000000FF,
		0xFF000000
	};
// Prepare the headers
	header.bfType = 0x4D42;
	header.bfSize = HEAD_LEN + bitmap->len;
	header.bfReserved1 = 0;
	header.bfReserved2 = 0;
	header.bfOffBits = HEAD_LEN;
	info.biSize = sizeof(BITMAPINFOHEADER);
	info.biWidth = bitmap->tx;
	info.biHeight = -bitmap->ty;
	info.biPlanes = 1;
	info.biBitCount = 32;
	info.biCompression = BI_BITFIELDS;
	info.biSizeImage = 0;
	info.biXPelsPerMeter = 96;
	info.biYPelsPerMeter = 96;
	info.biClrUsed = 0;
	info.biClrImportant = 0;
// Write the headers
	fwrite(&header, sizeof(BITMAPFILEHEADER), 1, file);
	fwrite(&info, sizeof(BITMAPINFOHEADER), 1, file);
	fwrite(&mask, sizeof(BITMAPCOLORMASK), 1, file);
// Save the picture
	s32 scan = bitmap->tx * sizeof(u32);
	u8 * data = bitmap->data;
	for (y = 0; y < bitmap->ty; y ++) {
		fwrite(data, scan, 1, file);
		data += scan;
	}
}

/*****************************************************************************/
void writeProto(FILE * hFile, const char * page, const char * name, BMP * bitmap)
{
	fprintf(hFile, "\textern const u16 %s %s[%u];\n", page, name, bitmap->len / sizeof(u32));
}

void writeArray(FILE * cFile, const char * page, const char * name, BMP * bitmap)
{
	s32 x, y;
	fprintf(cFile, "const u16 %s %s[%u] = {\n", page, name, bitmap->len / sizeof(u32));
	u8 * data = bitmap->data;
	for (y = 0; y < bitmap->ty; y++) {
		fprintf(cFile, "\t");
		for (x = 0; x < bitmap->tx; x++) {
			fprintf(cFile, "0x%04X, ", pixtoport(data));
			data += 4;
		}
		fprintf(cFile, "\n");
	}
	fprintf(cFile, "};\n");
}

/*****************************************************************************/
u32 getcolor(const char * text)
{
	u32 color;
	unsigned int r, g ,b;
	int len = strlen(text);
	if (text[0] == '0' && text[1] == 'x' && len >= 8) {
		sscanf(&text[2], "%x", &color);
		return color;
	}else if (len >= 5){
		int n = sscanf(text, "%u.%u.%u", &r, &g, &b);
		if (n == 3) {
			r &= 0xff;
			g &= 0xff;
			b &= 0xff;
			color = (r << 16) | (g << 8) | b;
			return color;
		}
	}
	printf("Unknown color format !\n");
	return 0;
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

void uppercase(char * text)
{
	char * p = text;
	while (*p) {
		if (*p >= 'a' && *p <= 'z') *p += 'A'- 'a';
		p++;
	}
}
