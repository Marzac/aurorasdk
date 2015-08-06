/*
 * File:   video.h
 * Author: Marzac, (c) Frederic Meslin 2013 - 2015
 * Date:   03/01/15
 * Brief:  aurora : SECAM video routines
 *
 * This module makes use of timer5 peripheral.
  
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

#ifndef VIDEO_H
#define	VIDEO_H

    #include "../aurora.h"

/******************************************************************************/
/* Video mode constants */
    #define VIDEO_FRAME_W       256
    #define VIDEO_FRAME_H       240

    #define VIDEO_TILE_W        16
    #define VIDEO_TILE_H        16
    #define VIDEO_TILE_SIZE     (VIDEO_TILE_W * VIDEO_TILE_H * sizeof(u16))

    #define VIDEO_LAYER_W       (VIDEO_FRAME_W / VIDEO_TILE_W)
    #define VIDEO_LAYER_H       (VIDEO_FRAME_H / VIDEO_TILE_H)
    #define VIDEO_LAYER_SIZE    (VIDEO_LAYER_W * VIDEO_LAYER_H * sizeof(u16))

    #define VIDEO_SPRITE_W      16
    #define VIDEO_SPRITE_H      16
	#define VIDEO_SPRITE_SIZE	(VIDEO_SPRITE_W * VIDEO_SPRITE_H * sizeof(u16))
		
    #define VIDEO_SPRITES_MAX   96

/******************************************************************************/
/* Video mode functions */
    void videoInit();
    void videoWaitVSYNC();
    void videoUpdate();

    void videoSpriteClear(int sprite);
    void videoSpriteSetVisible(int sprite, int visible);

    void videoSpriteSetPixels(int sprite, const RamPtr pixels);
    void videoSpriteSetPosition(int sprite, int x, int y);
    void videoSpriteSetZOrder(int sprite, int zorder);
    
    void videoTileTopSetTable(const RamPtr pointer);
    void videoTileTopSet(int x, int y, int tile);
    void videoTileTopFill(int tile);
    
    void videoTileBotSetTable(const FlashPage page, const FlashPtr pointer);
    void videoTileBotSet(int x, int y, int tile);
    void videoTileBotFill(int tile);

/******************************************************************************/
/* Video mode memory tables */
    extern RamPtr    topLayer[VIDEO_LAYER_H][VIDEO_LAYER_W];
    extern FlashPtr  botLayer[VIDEO_LAYER_H][VIDEO_LAYER_W];

#endif	/* VIDEO_H */

