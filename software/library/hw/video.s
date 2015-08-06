/*
 * File:   video.s
 * Author: Marzac, (c) Frederic Meslin 2013 - 2015
 * Date:   15/06/15
 * Brief:  aurora : SECAM video routines
 *
 * This module only makes use of timer5 peripheral.
 *
 * Until this project is publicly released under an open-source or creative,
 * commons licence these sources remains PROPRIETARY and CONFIDENTIAL.
 * Please do not distribute without prior agreement.
 *
 * Please respect this work by making your best use of it. As you will notice,
 * this program has required a great dose of patience, passion and dedication
 * to be written properly.
 *
 * This is damned cycle precise assembly folks !
 
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

; SpriteStr structure:
; 0  : u16 * raster (x * 2 + #raster)
; 2  : u16 y
; 4  : u16 * pixels (pixels pointer in SRAM)
; 6  : u16 * line (current line pointer in SRAM)
; 8  : u16 * prev (previous sprite (display queue))
; 10 : u16 * prev (next sprite (display queue))
; 12 : u16 zorder (display order)
; 14 : u16 flags (additionnal flags)

.equ SPR_RASTER,			#0									; attribute: raster
.equ SPR_Y,					#2									; attribute: y
.equ SPR_PIXELS,			#4									; attribute: pixels (sprite pixel data)
.equ SPR_LINE,				#6									; attribute: line (current pixel pointer)
.equ SPR_PREV,				#8									; attribute: previous (display queue)
.equ SPR_NEXT,				#10									; attribute: next (display queue)
.equ SPR_ZORDER,			#12									; attribute: zorder
.equ SPR_FLAGS,				#14									; attribute: flags
;
; typedef struct {
;	u16 * raster;
;   int y;
;   u16 * pixels;
;   u16 * line;
;   SpriteStr * prev;
;   SpriteStr * next;
;   int zorder;
;   uint flags;
; }SpriteStr;
;
; This sprite structure is organised to speed up the rendering routine.

; o raster attribute represents the sprite x position, forming a direct pointer
; to the raster line so no offset needs to be calculated during rendering.

; o y attribute represents the sprite y position, used for sprite slots allocation.

; o line attribute is a pointer to the sprite pixels used on next scan line.
; This pointer is automatically incremented by the rendering routine and rewinded
; to the pixels pointer before a new frame is drawn.

; o pixels attribute is the pointer to sprite pixels data. This attribute can be
; corrected by the videoSpriteMove routine for a negative y sprite. In this case
; first scan line does not display sprite first line of pixels. The address is
; reverted when the sprite move back to positive y.

; Bottom layer uses tiles in FLASH only, providing EDS/PSV addresses.
; Top layer uses tiles in SRAM only
; Sprite data must be located in SRAM

; ADS/PSV addresses start at 0x8000 and are mapped to a single 32k memory page.
; The page the rendering routine use can be set by the videoSetPage function.
; Symbols associated page number can be retrieved with psvpage(name) macro in
; XC16 assembler or with __builtin_psvpage(p) in XC16 C compiler.
; Please report to dsPIC datasheets about memory organisation & EDS/PSV for
; more information about the 16 bits address space and window mapping.

; The memory pointers requirements are due to CPU cycles and video timing:
; - accesses to SRAM require 1 cycle
; - accesses to FLASH via PSV require 4 cycles

/******************************************************************************/
.include "aurora.inc"
.include "interrupts.inc"

; Video exported functions
.global _videoInit
.global _videoWaitVSYNC
.global _videoBorderColor

.global _videoSpriteSetPixels
.global _videoSpriteSetPosition
.global _videoSpriteClear
.global _videoSpriteSetVisible
.global _videoSpriteSetZOrder

.global _videoTileBotSetTable
.global _videoTileBotSet
.global _videoTileBotFill

.global _videoTileTopSetTable
.global _videoTileTopSet
.global _videoTileTopFill

.global _videoUpdate
.global _videoSync

; Video exported variables
.global _botLayer
.global _topLayer

/******************************************************************************/
; Video resolution and mode
.equ FRAME_W,				#256								; horizontal resolution
.equ FRAME_H,				#240								; vertical resolution

; Tile layers configuration
.equ TILE_W,				#16									; resolution of tiles (pixels)
.equ TILE_H,				#16
.equ TILE_SIZE,				TILE_W * TILE_H * #2				; size of tiles date (bytes)
.equ LAYER_W,				(FRAME_W / TILE_W)					; horizontal number of tiles
.equ LAYER_H,				(FRAME_H / TILE_H)					; vertical number of tiles
.equ LAYER_SIZE,			LAYER_W * LAYER_H * #2				; layer memory size (bytes)

; Video synchronisation timings
.equ SCAN_LEN,				#4480								; 4480 cycles (64us)
.equ HSYNC_LEN,				#329								; 329 cycles (4.7us)
.equ HBACK_LEN,				#660								; 683 cycles (9.7us)
.equ VFRONT_LEN,			#29									; 29 scans (1.856 ms)
.equ VSYNC_LEN,				#3									; 3 scans (192 us)
.equ VBACK_LEN,				#40									; 40 scans (2.56 ms)

; Sprite configuration
.equ SPRITE_W,				#16									; resolution of sprites (pixels)
.equ SPRITE_H,				#16
.equ SPRITE_SIZE,			SPRITE_W * SPRITE_H * #2			; size of sprites data (bytes)
.equ RASTER_SIZE,			(FRAME_W + SPRITE_W * #2) * #2		; raster line size (bytes)

; Sprite structure
.equ SPRITE_STR_SIZE,		#16									; sprite structure size (bytes)
.equ SPR_RASTER,			#0									; attribute: raster
.equ SPR_Y,					#2									; attribute: y
.equ SPR_PIXELS,			#4									; attribute: pixels
.equ SPR_LINE,				#6									; attribute: line
.equ SPR_PREV,				#8									; attribute: previous (display queue)
.equ SPR_NEXT,				#10									; attribute: next (display queue)
.equ SPR_ZORDER,			#12									; attribute: zorder
.equ SPR_FLAGS,				#14									; attribute: flags

; Sprite display flags
.equ FLAG_HIDDEN,			#0									; bit 0: sprite is hidden

; Sprites rendering
.equ SPRITES_MAX,			#17									; maximal number of sprites per scanline
.equ SPRITES_GROUPB,		#5									; sprites rendered in sync time
.equ SPRITES_GROUPC,		#11									; sprites rendered in back porch
.equ SPRITES_SUBBC,			SPRITES_GROUPB + SPRITES_GROUPC		; subtotal of sprites
.equ SPRITES_GROUPA,		SPRITES_MAX - SPRITES_SUBBC			; sprites rendered in front porch
.equ SPRITES_SUBAB,			SPRITES_GROUPA + SPRITES_GROUPB		; subtotal of sprites
.equ SPRITES_STORE,			#96									; number of sprites in store
.equ SPRITES_STORE_SIZE,	SPRITES_STORE * SPRITE_STR_SIZE		; size of store (bytes)

; Video memory & registers
.pushsection .bss
_topLayer:			.space LAYER_SIZE						; top tile layer
_botLayer:			.space LAYER_SIZE						; bottom tile layer

spriteFirst:		.space SPRITE_STR_SIZE					; dummy first sprite
_sprites:			.space SPRITES_STORE_SIZE				; sprite table
spriteLast:			.space SPRITE_STR_SIZE					; dummy last sprite

blankSprite:		.space SPRITE_STR_SIZE					; transparent sprite
blankBuffer:		.space SPRITE_SIZE						; transparent sprite buffer
blankRamTile:		.space TILE_SIZE						; foreground tile

spritesTabFront:	.space SPRITES_MAX * SPRITE_H * #2		; trash buffer (top off-screen sprites)
spritesTab:			.space SPRITES_MAX * FRAME_H * #2		; sprites on scanline table
spritesTabBack:		.space SPRITES_MAX * SPRITE_H * #2		; trash buffer (bottom off-screen sprites)

spritesCountFront:	.space SPRITE_H							; trash buffer
spritesCount:		.space FRAME_H							; number of sprites on scanline
spritesCountBack:	.space SPRITE_H							; trash buffer

rasterFront:		.space SPRITE_W * #2					; trash buffer (off-screen sprites)
raster:				.space FRAME_W * #2						; sprite raster line
rasterBack:			.space SPRITE_W * #2					; trash buffer (off-screen sprites)

botTilePage:		.space 2								; bot tileset FLASH PSV / EDS page
botTilePointer:		.space 2								; bot tileset pointer
topTilePointer:		.space 2								; top tileset pointer
borderColor:		.space 2								; screen border color
.popsection

.pushsection .nbss, bss, near
scan:				.space 2								; current scanline
hvsync:				.space 2								; next sync line level
vsync:				.space 2								; vertical sync flag
.popsection

.pushsection .text
blankFlashTile:		.space TILE_SIZE, 0x00					; background tile
.popsection

.text
/******************************************************************************/
; void videoInit()
; Initialise SECAM / RGB video subsystem
; return nothing
; Registers:
; w0 temporary
; w1 temporary
_videoInit:
push w0
push w1
push w2
push DSRPAG							; save current PSV page
;Initialise global configuration
clr w0								; load a zero
bclr hvsync, #0						; set short synchronisation
mov w0, scan						; clear current scan
mov w0, borderColor					; set border color to black
mov w0, botTilePointer				; set bot tile pointer
mov w0, topTilePointer				; set top tile pointer
mov #psvpage(blankFlashTile), w0	; load blank tile page
mov w0, botTilePage					; set default PSV page
; Initialise the blank buffer
clr w0
mov #blankBuffer, w1				; load blank buffer address
repeat (#SPRITE_SIZE / #2) - #1		; fill with transparent color
mov w0, [w1++]
; Initialise the blank sprite
mov #blankSprite, w1				; load blank sprite address
mov #raster, w0						; load raster line address
mov w0, [w1+#SPR_RASTER]			; set raster to raster line
clr w0								; load a zero
mov w0, [w1+#SPR_Y]					; set sprite to top
mov #blankBuffer, w0				; load blank buffer address
mov w0, [w1+#SPR_PIXELS]			; set pixels to blank buffer
mov w0, [w1+#SPR_LINE]				; set line to blank buffer
clr w0								; load a zero
mov w0, [w1+#SPR_PREV]				; set out of the queue
mov w0, [w1+#SPR_NEXT]
mov w0, [w1+#SPR_ZORDER]			; lowest z-order
mov w0, [w1+#SPR_FLAGS]				; default flags
; Initialise sprites queue extremities
mov #_sprites, w0					; load first sprite address
sub w0, #SPRITE_STR_SIZE, w1		; load dummy address
mov w0, [w1+#SPR_NEXT]				; next is first sprite
mov #_sprites + #SPRITES_STORE_SIZE - #SPRITE_STR_SIZE, w0	; load last sprite address
add w0, #SPRITE_STR_SIZE, w1		; load dummy address
mov w0, [w1+#SPR_PREV]				; next is first sprite
; Initialise the other sprites
mov #_sprites, w1					; load sprites address
clr w2								; clear zorder cursor
do #SPRITES_STORE - #1, 1f			; initialise every sprite in store
mov #raster, w0						; load raster line address
mov w0, [w1+#SPR_RASTER]			; set raster to raster line
clr w0								; load a zero
mov w0, [w1+#SPR_Y]					; set sprite to top
mov w0, [w1+#SPR_FLAGS]				; reset all flags
mov w2, [w1+#SPR_ZORDER]			; set default z-order
mov #blankBuffer, w0				; load blank buffer address
mov w0, [w1+#SPR_LINE]				; set line to blank buffer
mov w0, [w1+#SPR_PIXELS]			; set pixels to blank buffer
sub w1, #SPRITE_STR_SIZE, w0		; get previous sprite
mov w0, [w1+#SPR_PREV]				; attribute previous sprite
add w1, #SPRITE_STR_SIZE, w0		; get next sprite
mov w0, [w1+#SPR_NEXT]				; attribute next sprite
add #SPRITE_STR_SIZE, w1			; load next sprite
1:
inc w2, w2							; increment z-order
; Initialise the sprite table
mov #blankSprite, w0				; load blank sprite address
mov #spritesTab, w1					; load sprite table address
repeat (#SPRITES_MAX * #FRAME_H) - #1	; set default sprite
mov w0, [w1++]
; Initialise the blank tile
clr w0
mov #blankRamTile, w1				; load blank tile address
repeat (#TILE_SIZE / #2) - #1		; fill with transparent color
mov w0, [w1++]
; Initialise the top tile layer
mov #blankRamTile, w0				; set blank buffer as default
mov #_topLayer, w1					; load topLayer address
repeat (#LAYER_SIZE / #2) - #1		; fill with default sprite
mov w0, [w1++]
; Initialise the bottom tile layer
mov #psvoffset(blankFlashTile), w0	; set blank tile as default
mov #_botLayer, w1					; load botLayer address
repeat (#LAYER_SIZE / #2) - #1		; fill with default sprite
mov w0, [w1++]
; Install interrupt vector
mov #T5VECTOR, w0
mov #tblpage(_videoSync), w1
mov #tbloffset(_videoSync), w2
call _intInstallVector
; Configure and start the timer
clr T5CON							; grab timer 5 for secam
mov #SCAN_LEN, w0					; load scan period
mov w0, PR5							; set the scan period
bset IEC1, #T5IE					; start the timer
bset T5CON, #TON
pop DSRPAG							; restore PSV page
pop w2
pop w1
pop w0
return

/******************************************************************************/
; void videoTileTopSetTable(RamPointer pointer)
; Set the top layer SRAM base pointer
; w0 rqm pointer
_videoTileTopSetTable:
btsc w0, #15							; check for SRAM address
return									; return if PSV/EDS address
mov w0, topTilePointer
return

; void videoTileTopSet(int x, int y, int tile)
; param[in] w0 x
; param[in] w1 y
; param[in] w2 tile index
; return nothing
_videoTileTopSet:
push w2
push w4
push w5
mov topTilePointer, w5					; load base pointer
mov #TILE_W * #TILE_H * #2, w4			; load tile size
mulw.uu w4, w2, w4						; compute data address 
add w4, w5, w2  
mov #LAYER_W, w4						; load layer width
mulw.uu w1, w4, w4						; compute tile offset
add w0, w4, w4
sl w4, #1, w4
mov #_topLayer, w5						; load top layer address
mov w2, [w4+w5]							; store tile pointer
pop w5
pop w4
pop w2
return

; void videoTileTopFill(int tile)
; Fill the top layer with a single tile
; param[in] w0 tile index
; return nothing
_videoTileTopFill:
push w1
push w2
mov #TILE_W * #TILE_H * #2, w1			; load tile size
mulw.uu w1, w0, w2						; compute data address
mov topTilePointer, w1					; load base pointer
add w1, w2, w1  
mov #_topLayer, w2						; load top layer address
repeat (#LAYER_SIZE / #2) - #1			; for all tiles in layer
mov w1, [w2++]							; replace all tiles
pop w2
pop w1
return

/******************************************************************************/
; void videoTileBotSetTable(FlashPage page, FlashPointer pointer)
; Set the bottom layer PSV FLASH page and pointer
; param[in] w0 PSV / EDS FLASH page
; param[in] w1 PSV / EDS FLASH pointer
_videoTileBotSetTable:
btss w1, #15							; check for PSV/EDS address
return									; return if SRAM address
mov w0, botTilePage
mov w1, botTilePointer
return

; void videoTileBotSet(int x, int y, int tile)
; param[in] w0 x
; param[in] w1 y
; param[in] w2 tile index
; return nothing
_videoTileBotSet:
push w2
push w4
push w5
mov botTilePointer, w5					; load base pointer
mov #TILE_W * #TILE_H * #2, w4			; load tile size
mulw.uu w4, w2, w4						; compute data address 
add w4, w5, w2  
mov #LAYER_W, w5						; load layer width
mulw.uu w1, w5, w4						; compute tile offset
add w0, w4, w4
sl w4, #1, w4
mov #_botLayer, w5						; load bottom layer address
mov w2, [w4+w5]							; store tile pointer
pop w5
pop w4
pop w2
return

; void videoTileBotFill(int tile)
; Fill the bottom layer with a single tile
; param[in] w0 tile index (in current page)
; return nothing
_videoTileBotFill:
push w1
push w2
mov #TILE_W * #TILE_H * #2, w1			; load tile size
mulw.uu w1, w0, w2						; compute data address
mov botTilePointer, w1					; load base pointer
add w1, w2, w1  
mov #_botLayer, w2						; load bottom layer address
repeat (#LAYER_SIZE / #2) - #1			; for all tiles in layer
mov w1, [w2++]							; replace all tiles
pop w2
pop w1
return

/******************************************************************************/
; void videoWaitVSYNC()
; Wait until end of next video frame
; return nothing
_videoWaitVSYNC:
push w0
bset vsync, #0							; set the vsync flag
1:
btsc vsync, #0							; test vsync flag
bra 1b									; loop while no retrace
pop w0
return

/******************************************************************************/
; void videoSpritePixels(int sprite, const RamPtr pixels)
; Set a sprite pixels RAM pointer
; param[in] w0 sprite index
; param[in] w1 pixels pointer
; return nothing
_videoSpriteSetPixels:
btsc w1, #15							; check for real address
return									; return if PSV address
push w0
push w2
mov #_sprites, w2						; load sprites base address
mulw.uu w0, #SPRITE_STR_SIZE, w0		; compute sprite offset
add w0, w2, w0							; compute sprite address
mov [w0+#SPR_Y], w2						; load y position
cp0 w2									; check vertical position
bra lt, 1f								; jump if y > 0
mov w1, [w0+#SPR_PIXELS]				; set pixels pointer
pop w2
pop w0
return
1:
push w3									; need an additionnal register
mov #SPRITE_W * #2, w3					; load line size
mulw.ss w2, w3, w2						; compute offset
sub w1, w2, w2							; move pixel address
mov w2, [w0+#SPR_PIXELS]				; set pixels pointer
pop w3
pop w2
pop w0
return

/******************************************************************************/
; void videoSpriteSetPosition(int sprite, int x, int y)
; Set a sprite position
; param[in] w0 sprite index
; param[in] w1 x horizontal position
; param[in] w2 y vertical position
; return nothing
_videoSpriteSetPosition:
push w0
push w1
push w2
push w3
push w4
push w5
push w6
push w7
; Clip sprite coordinates
mov -#SPRITE_W, w3					; load left border
cpsgt w1, w3						; compare x to border
mov w3, w1							; adjust if needed
mov -#SPRITE_H, w3					; load top border
cpsgt w2, w3						; compare y to border
mov w3, w2							; adjust if needed
mov #FRAME_W, w3					; load right border
cpslt w1, w3						; compare x to border
mov w3, w1							; adjust if needed
mov #FRAME_H, w3					; load bottom border
cpslt w2, w3						; compare y to border
mov w3, w2							; adjust if needed
; Load sprite configuration
mov #_sprites, w3					; load sprites address
mulw.uu w0, #SPRITE_STR_SIZE, w4	; compute sprite offset
add w3, w4, w5						; get sprite address
mov [w5+#SPR_Y], w6					; load sprite y
cp w2, w6							; y == sprite->y ?
bra Z, 3f							; yes => skip translation
; Revert translation (negative y)
1:
cp0 w6								; compare former y to 0
bra ge, 2f							; jump if y > 0
mov [w5+#SPR_PIXELS], w3			; load pixel address
mov #SPRITE_W * #2, w4				; load line size
mulw.ss w4, w6, w4					; compute offset
add w3, w4, w3						; add to pixel address
mov w3, [w5+#SPR_PIXELS]			; store pixel address
; Apply translation (negative y)
2:
cp0 w2								; compare new y to 0
bra ge, 3f							; jump if y > 0
mov [w5+#SPR_PIXELS], w3			; load pixel address
mov #SPRITE_W * #2, w4				; load line size
mulw.ss w4, w2, w4					; compute offset
sub w3, w4, w3						; add to pixel address
mov w3, [w5+#SPR_PIXELS]			; store pixel address
; Configure the sprite
3:
mov #raster, w4						; load raster address
sl w1, #1, w3						; multiply x by 2
add w4, w3, w3						; add the offset
mov w3, [w5+#SPR_RASTER]			; store new x location
mov w2, [w5+#SPR_Y]					; store new y location
pop w7
pop w6
pop w5
pop w4
pop w3
pop w2
pop w1
pop w0
return

/******************************************************************************/
; void videoSpriteClear(int sprite)
; Deactivate a sprite (make it blank sprite)
; param[in] w0 sprite index
; return nothing
_videoSpriteClear:
push w0
push w1
push w2
push w3
mulw.uu w0, #SPRITE_STR_SIZE, w0	; compute sprite address
mov #_sprites, w1
add w0, w1, w0
mov [w0+#SPR_Y], w1					; load sprite y
clr w2								; clear address offset
cp0 w1								; compare y to 0
bra ge, 1f							; jump if y > 0
mov #SPRITE_W * #2, w2				; load line size
mul.uu w1, w2, w2					; compute offset
1:
mov #blankBuffer, w3				; load the blank buffer
sub w3, w2, w3						; apply potential offset
mov w3, [w0+#SPR_PIXELS]			; store new pixel address
pop w3
pop w2
pop w1
pop w0
return

/******************************************************************************/
; void videoSpriteSetVisible(int sprite, int visible)
; Show or hide a sprite
; param[in] w0 sprite index
; param[in] w1 visible state
; return nothing
_videoSpriteSetVisible:
push w0
push w2
mulw.uu w0, #SPRITE_STR_SIZE, w0	; compute sprite offset
mov #_sprites, w2
add w0, w2, w0
mov [w0+#SPR_FLAGS], w2				; load sprite flags
bclr w2, #FLAG_HIDDEN				; show sprite
btss w1, #0
bset w2, #FLAG_HIDDEN				; hide sprite
mov w2, [w0+#SPR_FLAGS]				; save sprite flags
pop w2
pop w0
return

/******************************************************************************/
; void videoSpriteSetZOrder(int sprite, int zorder)
; Show or hide a sprite
; param[in] w0 sprite index
; param[in] w1 zorder value
; return nothing
_videoSpriteSetZOrder:
push w0
push w1
push w2
push w3
; Get sprite properties
mulw.uu w0, #SPRITE_STR_SIZE, w0	; compute sprite address
mov #_sprites, w2
add w0, w2, w0
mov [w0+#SPR_PREV], w2				; load previous sprite
mov [w0+#SPR_NEXT], w3				; load next sprite
; Extract sprite from queue
mov w3, [w2+#SPR_NEXT]				; connect previous to next
mov w2, [w3+#SPR_PREV]				; connect next to previous
; Find the right place
mov #spriteFirst, w2				; load first sprite (dummy)
mov [w2+#SPR_NEXT], w2				; start with real sprite
mov #spriteLast, w3					; load last sprite (dummy)
bra 2f
1:
mov [w2+#SPR_ZORDER], w5			; load current z-order
cpbgt w5, w1, 3f					; break if greater
2:
mov [w2+#SPR_NEXT], w2				; load next sprite
cpbne w2, w3, 1b					; check for last sprite
3:
; Set sprite properties
mov [w2+#SPR_PREV], w3				; load previous sprite
mov w1, [w0+#SPR_ZORDER]			; store new z-order
mov w2, [w0+#SPR_NEXT]				; connect next
mov w3, [w0+#SPR_PREV]				; connect next
; Insert sprite in queue
mov w0, [w3+#SPR_NEXT]				; connect previous to next
mov w0, [w2+#SPR_PREV]				; connect next to previous
pop w3
pop w2
pop w1
pop w0
return

/******************************************************************************/
; void videoUpdate()
; Update the video system:
; - allocate the scanlines for sprites
; return nothing
_videoUpdate:
push w0
push w1
push w2
push w3
push w4
push w5
push w6
push w7
push w8
push w9
; Clear the sprites scanline table
mov #spritesTab, w2					; load sprites scanlines address
mov #blankSprite, w3				; load blank sprite
repeat (#SPRITES_MAX * #FRAME_H) - #1
mov w3, [w2++]						; clear the table
; Clear the sprites count table
clr w0								; load a zero
mov #spritesCountFront, w2			; load sprites count address
repeat (((#SPRITE_H * #2) + #FRAME_H) / #2) - #1
;repeat #135
mov w0, [w2++]						; clear count table
; Prepare allocation loop
mov #spritesTab, w1					; load sprites scanlines address
mov #spritesCount, w2				; load sprites count address
mov #spriteFirst, w3				; load first sprite (dummy)
mov [w3+#SPR_NEXT], w3				; start with real sprite
mov #spriteLast, w4					; load last sprite (dummy)
mov (#SPRITES_MAX - #1) * #2, w5	; load max. number of sprites
bra 3f								; get the sprite
; Allocate every sprite
1:
mov [w3+#SPR_FLAGS], w8				; get sprite flags
btsc w8, #FLAG_HIDDEN				; check sprite visibility
bra 3f								; jump if not visible
mov [w3+#SPR_Y], w9					; get sprite y
add w9, w2, w6						; get first count address
add w6, #SPRITE_H, w7				; get count limit
mov #SPRITES_MAX * #2, w8			; load scanline size
mulw.ss w9, w8, w8					; compute the offset
add w8, w1, w8						; get first scanline address
; Allocate every scanline
2:
mov.b [w6], w0						; load sprites count
cpsgt w0, w5						; space left ?
mov w3, [w8+w0]						; yes => register the sprite
inc2 w0, w0							; increment the count
mov.b w0, [w6++]					; store the count
add #SPRITES_MAX * #2, w8			; increment scanline
cpblt w6, w7, 2b					; check last scanline
3:
mov [w3+#SPR_NEXT], w3				; load next sprite address
cpbne w3, w4, 1b					; check for last sprite
pop w9
pop w8
pop w7
pop w6
pop w5
pop w4
pop w3
pop w2
pop w1
pop w0
return

/******************************************************************************/
; void videoSync()
; Display the video memory (called from T5 interrupt)
; return nothing
; Registers :
; w0 temp
; w1 scan/port
; w2 botLayer pointer
; w3 topLayer pointer
; w4 bottom tile
; w5 top tile
; w6 raster
; w7 drawn pixel
; w8 temp pixel

_videoSync:
; Generate synchro edge
bclr VIDEOSYNC_PORT, #SYNC_PIN			;1* set sync low
push RCOUNT								;1
push w0									;1 save work registers
push w1									;1

; Increment and check scanline
mov scan, w1							;1
inc w1, w0								;1
mov w0, scan							;1
sub #FRAME_H, w1						;1
bra ge, __frontporch					;1(4)
add #FRAME_H, w1						;1

; Save work registers
push w2									;1
push w3									;1
push w4									;1
push w5									;1
push w6									;1
push w7									;1
push w8									;1
push w9									;1

; Pre-render group B sprites
mov #spritesTab, w0						;1 load table address
mov #SPRITES_MAX * #2, w2				;1 load maximum of sprites
mul.uu w1, w2, w2						;1 compute scan offset
add w0, w2, w2							;1 add to offset
mov #SPRITES_GROUPA * #2, w0			;1 fetch group b sprites (skip group a)
add w0, w2, w2							;1 add to offset
clr w0									;1 load transparency color
mov #SPRITE_W * #2, w7					;1 load line increment
mov [w2++], w3							;1 load first sprite
mov #blankBuffer, w8					;1 load blank buffer address
do #SPRITES_GROUPB - #1, 2f				;2 render every group b sprites
mov [w3+#SPR_RASTER], w4				;1 load sprite raster address
mov [w3+#SPR_LINE], w5					;1 load sprite line address
add w5, w7, w6							;1 increment line address
mov w6, [w3+#SPR_LINE]					;1 store new line address
mov w8, blankSprite + #SPR_LINE			;1 hack for blank sprite
mov [w5++], w6							;1 load first pixel
sub w4, w5, w4							;1 get the address difference
do #SPRITE_W - #1, 1f					;2 render every pixel
cpseq w6, w0							;1-2 check for transparency
mov w6, [w5+w4]							;1 draw the pixel
1:
mov [w5++], w6							;1 load next pixel
2:
mov [w2++], w3							;1 load next sprite

; Generate sync pulse
repeat #HSYNC_LEN - ((#58 * #SPRITES_GROUPB) + #34)
nop
btsc hvsync, #0							;1 test sync level
bset VIDEOSYNC_PORT, #0					;1 set sync level

; Pre-render group C sprites
clr w0									;1 load transparency color
mov #SPRITE_W * #2, w7					;1 load line increment
mov #blankBuffer, w8					;1 load blank buffer address
do #SPRITES_GROUPC - #1, 2f				;2 render every group c sprites
mov [w3+#SPR_RASTER], w4				;1 load sprite raster address
mov [w3+#SPR_LINE], w5					;1 load sprite line address
add w5, w7, w6							;1 increment line address
mov w6, [w3+#SPR_LINE]					;1 store new line address
mov w8, blankSprite + #SPR_LINE			;1 hack for blank sprite
mov [w5++], w6							;1 load first pixel
sub w4, w5, w4							;1 get the address difference
do #SPRITE_W - #1, 1f					;2 render every pixel
cpseq w6, w0							;1-2 check for transparency
mov w6, [w5+w4]							;1 draw the pixel
1:
mov [w5++], w6							;1 load next pixel
2:
mov [w2++], w3							;1 load next sprite

; Prepare the pointers
push DSRPAG								;1 save current PSV page
mov botTilePage, w0						;1 load PSV page address
movpag w0, DSRPAG						;3 configure PSV window
.if #TILE_W == #4
asr w1, #2, w0							;1 get tile row (4 pixels)
sl w0, #7, w0							;1 compute tile offset (64 tiles)
.elseif #TILE_W == #8
asr w1, #3, w0							;1 get tile row (8 pixels)
sl w0, #6, w0							;1 compute tile offset (32 tiles)
.elseif #TILE_W == #16
asr w1, #4, w0							;1 get tile row (16 pixels)
sl w0, #5, w0							;1 compute tile offset (16 tiles)
.endif
mov #_botLayer, w2						;1 load botLayer address
mov #_topLayer, w3						;1 load topLayer address
add w2, w0, w2							;1 add tile offset
add w3, w0, w3							;1 add tile offset
mov #raster, w6							;1 load raster address

; Load first tiles
mov [w2++], w8							;1 load bottile address
mov [w3++], w5							;1 load toptile address
and w1, #TILE_H - #1, w1				;1 get tile line
.if #TILE_W == #4
sl w1, #3, w1							;1 compute pixel offset, 4 pixels x 2 bytes
.elseif #TILE_W == #8
sl w1, #4, w1							;1 compute pixel offset, 8 pixels x 2 bytes
.elseif #TILE_W == #16
sl w1, #5, w1							;1 compute pixel offset, 15 pixels x 2 bytes
.endif
add w5, w1, w5							;1 add pixel offset
clr w0									;1 load a zero

; Draw the complete frame
do (#FRAME_W / #TILE_W) - #1, pixelLoop	;2

; Pixel 1
mov [w5++], w7							;1 load top pixel
add w8, w1, w4							;1 load next bottom line
cpsne w7, w0							;1/2 check for transparency
mov [w6], w7							;1 load sprite pixel instead
mov [w4++], [w6++]						;5 load bottom pixel / increment w6
cpsne w7, w0							;1/2 check for transparency
mov [w6-#2], w7							;1 use bottom pixel
mov w7, VIDEORGB_PORT					;1 draw pixel

.if #TILE_W > #4
	; Pixel 2
	mov [w5++], w7							;1 load top pixel
	nop										;1 empty slot for preloading
	cpsne w7, w0							;1/2 check for transparency
	mov [w6], w7							;1 load sprite pixel instead
	mov [w4++], [w6++]						;5 load bottom pixel / increment w6
	cpsne w7, w0							;1/2 check for transparency
	mov [w6-#2], w7							;1 use bottom pixel
	mov w7, VIDEORGB_PORT					;1 draw pixel

	; Pixel 3
	mov [w5++], w7							;1 load top pixel
	nop										;1 empty slot for preloading
	cpsne w7, w0							;1/2 check for transparency
	mov [w6], w7							;1 load sprite pixel instead
	mov [w4++], [w6++]						;5 load bottom pixel / increment w6
	cpsne w7, w0							;1/2 check for transparency
	mov [w6-#2], w7							;1 use bottom pixel
	mov w7, VIDEORGB_PORT					;1 draw pixel

	; Pixel 4
	mov [w5++], w7							;1 load top pixel
	nop										;1 empty slot for preloading
	cpsne w7, w0							;1/2 check for transparency
	mov [w6], w7							;1 load sprite pixel instead
	mov [w4++], [w6++]						;5 load bottom pixel / increment w6
	cpsne w7, w0							;1/2 check for transparency
	mov [w6-#2], w7							;1 use bottom pixel
	mov w7, VIDEORGB_PORT					;1 draw pixel

	; Pixel 5
	mov [w5++], w7							;1 load top pixel
	nop										;1 empty slot for preloading
	cpsne w7, w0							;1/2 check for transparency
	mov [w6], w7							;1 load sprite pixel instead
	mov [w4++], [w6++]						;5 load bottom pixel / increment w6
	cpsne w7, w0							;1/2 check for transparency
	mov [w6-#2], w7							;1 use bottom pixel
	mov w7, VIDEORGB_PORT					;1 draw pixel

	.if #TILE_W > #8
		; Pixel 6
		mov [w5++], w7							;1 load top pixel
		nop										;1 empty slot for preloading
		cpsne w7, w0							;1/2 check for transparency
		mov [w6], w7							;1 load sprite pixel instead
		mov [w4++], [w6++]						;5 load bottom pixel / increment w6
		cpsne w7, w0							;1/2 check for transparency
		mov [w6-#2], w7							;1 use bottom pixel
		mov w7, VIDEORGB_PORT					;1 draw pixel

		; Pixel 7
		mov [w5++], w7							;1 load top pixel
		nop										;1 empty slot for preloading
		cpsne w7, w0							;1/2 check for transparency
		mov [w6], w7							;1 load sprite pixel instead
		mov [w4++], [w6++]						;5 load bottom pixel / increment w6
		cpsne w7, w0							;1/2 check for transparency
		mov [w6-#2], w7							;1 use bottom pixel
		mov w7, VIDEORGB_PORT					;1 draw pixel

		; Pixel 8
		mov [w5++], w7							;1 load top pixel
		nop										;1 empty slot for preloading
		cpsne w7, w0							;1/2 check for transparency
		mov [w6], w7							;1 load sprite pixel instead
		mov [w4++], [w6++]						;5 load bottom pixel / increment w6
		cpsne w7, w0							;1/2 check for transparency
		mov [w6-#2], w7							;1 use bottom pixel
		mov w7, VIDEORGB_PORT					;1 draw pixel

		; Pixel 9
		mov [w5++], w7							;1 load top pixel
		nop										;1 empty slot for preloading
		cpsne w7, w0							;1/2 check for transparency
		mov [w6], w7							;1 load sprite pixel instead
		mov [w4++], [w6++]						;5 load bottom pixel / increment w6
		cpsne w7, w0							;1/2 check for transparency
		mov [w6-#2], w7							;1 use bottom pixel
		mov w7, VIDEORGB_PORT					;1 draw pixel

		; Pixel 10
		mov [w5++], w7							;1 load top pixel
		nop										;1 empty slot for preloading
		cpsne w7, w0							;1/2 check for transparency
		mov [w6], w7							;1 load sprite pixel instead
		mov [w4++], [w6++]						;5 load bottom pixel / increment w6
		cpsne w7, w0							;1/2 check for transparency
		mov [w6-#2], w7							;1 use bottom pixel
		mov w7, VIDEORGB_PORT					;1 draw pixel

		; Pixel 11
		mov [w5++], w7							;1 load top pixel
		nop										;1 empty slot for preloading
		cpsne w7, w0							;1/2 check for transparency
		mov [w6], w7							;1 load sprite pixel instead
		mov [w4++], [w6++]						;5 load bottom pixel / increment w6
		cpsne w7, w0							;1/2 check for transparency
		mov [w6-#2], w7							;1 use bottom pixel
		mov w7, VIDEORGB_PORT					;1 draw pixel

		; Pixel 12
		mov [w5++], w7							;1 load top pixel
		nop										;1 empty slot for preloading
		cpsne w7, w0							;1/2 check for transparency
		mov [w6], w7							;1 load sprite pixel instead
		mov [w4++], [w6++]						;5 load bottom pixel / increment w6
		cpsne w7, w0							;1/2 check for transparency
		mov [w6-#2], w7							;1 use bottom pixel
		mov w7, VIDEORGB_PORT					;1 draw pixel

		; Pixel 13
		mov [w5++], w7							;1 load top pixel
		nop										;1 empty slot for preloading
		cpsne w7, w0							;1/2 check for transparency
		mov [w6], w7							;1 load sprite pixel instead
		mov [w4++], [w6++]						;5 load bottom pixel / increment w6
		cpsne w7, w0							;1/2 check for transparency
		mov [w6-#2], w7							;1 use bottom pixel
		mov w7, VIDEORGB_PORT					;1 draw pixel
	.endif
.endif

; Pixel 2-6-14
mov [w5++], w7							;1 load top pixel
mov [w2++], w8							;1 load next bottom tile
cpsne w7, w0							;1/2 check for transparency
mov [w6], w7							;1 load sprite pixel instead
mov [w4++], [w6++]						;5 load bottom pixel / increment w6
cpsne w7, w0							;1/2 check for transparency
mov [w6-#2], w7							;1 use bottom pixel
mov w7, VIDEORGB_PORT					;1 draw pixel

; Pixel 3-7-15
mov [w5++], w7							;1 load top pixel
mov [w3++], w9							;1 load next top tile
cpsne w7, w0							;1/2 check for transparency
mov [w6], w7							;1 load sprite pixel instead
mov [w4++], [w6++]						;5 load bottom pixel / increment w6
cpsne w7, w0							;1/2 check for transparency
mov [w6-#2], w7							;1 use bottom pixel
mov w7, VIDEORGB_PORT					;1 draw pixel

; Pixel 4-8-16
mov [w5++], w7							;1 load top pixel
add w9, w1, w5							;1 load next top line
cpsne w7, w0							;1/2 check for transparency
mov [w6], w7							;1 load sprite pixel instead
mov [w4++], [w6++]						;5 load bottom pixel / increment w6
cpsne w7, w0							;1/2 check for transparency
mov [w6-#2], w7							;1 use bottom pixel
pixelLoop:
mov w7, VIDEORGB_PORT					;1 draw pixel

; Clear raster line
clr VIDEORGB_PORT						;1* clear the border
clr w0									;1 load a zero
mov #raster, w2							;1* get raster address
repeat #FRAME_W - #1					;1* fill with zeros
mov w0, [w2++]

; Skip sprites for last scanline
mov scan, w1							;1* load scan line
mov #FRAME_H, w2						;1* load last scan
cpsne w1, w2							;1* compare with resolution
bclr vsync, #0							;1* clear the vsync flag
cpbeq w1, w2, __endofscan				;1* compare with resolution

; Pre-render group A sprites
mov #spritesTab, w0						;1 load table address
mov scan, w1							;1 load scan address
mov #SPRITES_MAX * #2, w2				;1 load maximum of sprites
mul.uu w1, w2, w2						;1 compute scan offset
add w0, w2, w2							;1 add to offset
clr w0									;1 load transparency color
mov #SPRITE_W * #2, w7					;1 load line increment
mov [w2++], w3							;1 load first sprite
mov #blankBuffer, w8					;1 load blank buffer address
do #SPRITES_GROUPA - #1, 2f				;2 render every group a sprites
mov [w3+#SPR_RASTER], w4				;1 load sprite raster address
mov [w3+#SPR_LINE], w5					;1 load sprite line address
add w5, w7, w6							;1 increment line address
mov w6, [w3+#SPR_LINE]					;1 store new line address
mov w8, blankSprite + #SPR_LINE			;1 hack for blank sprite
mov [w5++], w6							;1 load first pixel
sub w4, w5, w4							;1 get the address difference
do #SPRITE_W - #1, 1f					;2 render every pixel
cpseq w6, w0							;1-2 check for transparency
mov w6, [w5+w4]							;1 draw the pixel
1:
mov [w5++], w6							;1 load next pixel
2:
mov [w2++], w3							;1 load next sprite

__endofscan:
pop DSRPAG								;1* restore PSV page
pop w9									;1* restore work registers
pop w8									;1*
pop w7									;1*
pop w6									;1*
pop w5									;1*
pop w4									;1*
pop w3									;1*
pop w2									;1*
pop w1									;1*
pop w0									;1*
pop RCOUNT								;1*
bclr IFS1, #T5IF						;1* clear interrupt flag
;retfr
return									;5-6* return

; Prepare the vertical front porch
__frontporch:

; Generate the sync pulse
repeat #HSYNC_LEN - #15					;1 wait remaining sync time
nop
btsc hvsync, #0							;1 test sync level
bset VIDEOSYNC_PORT, #0					;1 set sync level

; Check scanline
sub #VFRONT_LEN - #1, w1				;1*
bra ge, __synchro						;1-4*

pop w1									;1*
pop w0									;1*
pop RCOUNT								;1*
bclr IFS1, #T5IF						;1* clear interrupt flag
;retfr
return									;5-6* return

; Prepare the vertical synchronisation
__synchro:
sub #VSYNC_LEN, w1						;1*
bra ge, __backporch						;1-4*
bclr hvsync, #0							;1* long synchronisation
pop w1									;1*
pop w0									;1*
pop RCOUNT								;1*
bclr IFS1, #T5IF						;1* clear interrupt flag
;retfr
return									;5-6* return

; Prepare the vertical back porch
__backporch:
sub #VBACK_LEN, w1						;1*
bra ge, __newframe						;1-4*
bset hvsync, #0							;1* short synchronisation
pop w1									;1*
pop w0									;1*
pop RCOUNT								;1*
bclr IFS1, #T5IF						;1* clear interrupt flag
;retfr
return									;5-6* return

; Prepare the new frame
__newframe:
push w2									;1*
push w3									;1*
push w4									;1*
push w5									;1*
push w6									;1*
push w7									;1*
push w8									;1*

; Reset the scanline
clr w0									;1* reset the scanline
mov w0, scan							;1*

; Rewind sprite address
mov #_sprites + #SPR_PIXELS, w1			;1* load first sprite / pixels attribute
mov #SPR_LINE - #SPR_PIXELS, w3			;1* load attributes offset (line - pixels)
do #SPRITES_STORE - #1, 1f				;2* rewind every sprite
mov [w1], [w1+w3]						;1* reset line address
1:
add #SPRITE_STR_SIZE, w1				;1* load next sprite

; Pre-render group A sprites
mov #spritesTab, w0						;1 load table address
mov scan, w1							;1 load scan address
mov #SPRITES_MAX * #2, w2				;1 load maximum of sprites
mul.uu w1, w2, w2						;1 compute scan offset
add w0, w2, w2							;1 add to offset
clr w0									;1 load transparency color
mov #SPRITE_W * #2, w7					;1 load line increment
mov [w2++], w3							;1 load first sprite
mov #blankBuffer, w8					;1 load blank buffer address
do #SPRITES_GROUPA - #1, 2f				;2 render every group a sprites
mov [w3+#SPR_RASTER], w4				;1 load sprite raster address
mov [w3+#SPR_LINE], w5					;1 load sprite line address
add w5, w7, w6							;1 increment line address
mov w6, [w3+#SPR_LINE]					;1 store new line address
mov w8, blankSprite + #SPR_LINE			;1 hack for blank sprite
mov [w5++], w6							;1 load first pixel
sub w4, w5, w4							;1 get the address difference
do #SPRITE_W - #1, 1f					;2 render every pixel
cpseq w6, w0							;1-2 check for transparency
mov w6, [w5+w4]							;1 draw the pixel
1:
mov [w5++], w6							;1 load next pixel
2:
mov [w2++], w3							;1 load next sprite

pop w8									;1*
pop w7									;1*
pop w6									;1*
pop w5									;1*
pop w4									;1*
pop w3									;1*
pop w2									;1*
pop w1									;1*
pop w0									;1*
pop RCOUNT								;1*
bclr IFS1, #T5IF						;1* clear interrupt flag
return									;5-6* return
;retfr

.end
