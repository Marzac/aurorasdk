/*
 * File:   audio.h
 * Author: Marzac, (c) Frederic Meslin 2013 - 2015
 * Date:   03/01/15
 * Brief:  aurora : PCM audio & synthesis routines
 *
 * This module makes use of timer4, DMA2 and DMA3 peripherals
 
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

#ifndef AUDIO_H
#define	AUDIO_H

    #include "../aurora.h"

/******************************************************************************/
/* Audio enums */
    typedef enum {
        CHANNEL_CENTER = 0,
        CHANNEL_LEFT,
        CHANNEL_RIGHT,
    }CHANNELS;
    
/******************************************************************************/
/* RAW audio functions */
    void rawAudioInit(int channel);
    void rawAudioStart(int channel);
    void rawAudioStop(int channel);
    void rawAudioPitch(int channel, int note);
    void rawAudioPitchMod(int channel, int speed, int amount);
    void rawAudioPW(int channel, int pwm);
    void rawAudioPWMod(int channel, int speed, int amount);
    void rawAudioUpdate();

/* PCM audio functions */
    void pcmAudioInit(int channel);
    void pcmAudioPlay(int channel, FlashPtr samples, uint length);
    void pcmAudioStop(int channel);
    void pcmAudioUpdate();
    
#endif	/* AUDIO_H */

