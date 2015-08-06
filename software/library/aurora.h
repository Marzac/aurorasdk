/*
 * File:   aurora.h
 * Author: Marzac (Frédéric Meslin)
 * Date:   03/03/14
 * Brief:  Configuration file (pins / constants)
  
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

#ifndef CONFIG_H
#define	CONFIG_H

    #include <p33Exxxx.h>
    #include "types.h"

// Clock related constants
    #define CPU_FRQ         140000000
    #define CPU_FCY         (CPU_FRQ / 2)

// Video pin mapping
    #define VIDEORGB_PORT   PORTC
    #define RED0_PIN        PORTCbits.RC0
    #define RED1_PIN        PORTCbits.RC1
    #define RED2_PIN        PORTCbits.RC2
    #define RED3_PIN        PORTCbits.RC3
    #define GREEN0_PIN      PORTCbits.RC4
    #define GREEN1_PIN      PORTCbits.RC5
    #define GREEN2_PIN      PORTCbits.RC6
    #define GREEN3_PIN      PORTCbits.RC7
    #define BLUE0_PIN       PORTCbits.RC8
    #define BLUE1_PIN       PORTCbits.RC9
    #define BLUE2_PIN       PORTCbits.RC10
    #define BLUE3_PIN       PORTCbits.RC11
    #define VIDEOSYNC_PORT  PORTA
    #define SYNC_PIN        PORTAbits.RA0
    
    #define VIDEORGB_TRIS   TRISC
    #define RED0_TRIS       TRISCbits.TRISC0
    #define RED1_TRIS       TRISCbits.TRISC1
    #define RED2_TRIS       TRISCbits.TRISC2
    #define RED3_TRIS       TRISCbits.TRISC3
    #define GREEN0_TRIS     TRISCbits.TRISC4
    #define GREEN1_TRIS     TRISCbits.TRISC5
    #define GREEN2_TRIS     TRISCbits.TRISC6
    #define GREEN3_TRIS     TRISCbits.TRISC7
    #define BLUE0_TRIS      TRISCbits.TRISC8
    #define BLUE1_TRIS      TRISCbits.TRISC9
    #define BLUE2_TRIS      TRISCbits.TRISC10
    #define BLUE3_TRIS      TRISCbits.TRISC11
    #define VIDEOSYNC_TRIS  TRISA
    #define SYNC_TRIS       TRISAbits.TRISA0
    
// Bluetooth pin mapping
    #define BLUEPAIRED_PIN  PORTEbits.RE14          // = RPI94
    #define BLUERESET_PIN   PORTEbits.RE15          // = RPI95
    #define BLUEAT_PIN      PORTBbits.RB4           // = RP36
    #define BLUERX_PIN      PORTAbits.RA4           // = RP20
    #define BLUETX_PIN      PORTAbits.RA9           // = RPI25
    #define BLUELED_PIN     PORTGbits.RG9

    #define BLUEPAIRED_TRIS TRISEbits.TRISE14
    #define BLUERESET_TRIS  TRISEbits.TRISE15
    #define BLUEAT_TRIS     TRISBbits.TRISB4
    #define BLUERX_TRIS     TRISAbits.TRISA4
    #define BLUETX_TRIS     TRISAbits.TRISA9
    #define BLUELED_TRIS    TRISGbits.TRISG9

// USB pin mapping
    #define USBENUM_PIN     PORTDbits.RD8
    #define USBTX_PIN       PORTBbits.RB5           // = RP37
    #define USBRX_PIN       PORTBbits.RB6           // = RP38

    #define USBENUM_TRIS    TRISDbits.TRISD8
    #define USBTX_TRIS      TRISBbits.TRISB5
    #define USBRX_TRIS      TRISBbits.TRISB6

// Audio PWM mapping
    #define AUDIODAC0_PIN   PORTBbits.RB7           // = RP39
    #define AUDIODAC1_PIN   PORTBbits.RB8           // = RP40
    #define AUDIODAC2_PIN   PORTBbits.RB9           // = RP41

    #define AUDIODAC0_TRIS  TRISBbits.TRISB7
    #define AUDIODAC1_TRIS  TRISBbits.TRISB8
    #define AUDIODAC2_TRIS  TRISBbits.TRISB9
    
// FLASH pin mapping
    #define FLASHSCLK_PIN   PORTGbits.RG6           // = RP118
    #define FLASHMISO_PIN   PORTGbits.RG7           // = RP119
    #define FLASHMOSI_PIN   PORTGbits.RG8           // = RP120
    #define FLASHSCS_PIN    PORTFbits.RF1           // = RP97

    #define FLASHSCLK_TRIS  TRISGbits.TRISG6
    #define FLASHMISO_TRIS  TRISGbits.TRISG7
    #define FLASHMOSI_TRIS  TRISGbits.TRISG8
    #define FLASHSCS_TRIS   TRISGbits.TRISF1

// Game pads pin mapping
    #define GP0_PIN         PORTBbits.RB10
    #define GP1_PIN         PORTBbits.RB11
    #define GP2_PIN         PORTBbits.RB12
    #define GP3_PIN         PORTBbits.RB13
    #define GP4_PIN         PORTBbits.RB14
    #define GP5_PIN         PORTBbits.RB15
    #define GPS0_PIN        PORTDbits.RD5
    #define GPS1_PIN        PORTDbits.RD6
    #define GPSELECT_PIN    PORTAbits.RA10
    #define GPPOWER_PIN     PORTEbits.RE12

    #define GP0_TRIS        TRISBbits.TRISB10
    #define GP1_TRIS        TRISBbits.TRISB11
    #define GP2_TRIS        TRISBbits.TRISB12
    #define GP3_TRIS        TRISBbits.TRISB13
    #define GP4_TRIS        TRISBbits.TRISB14
    #define GP5_TRIS        TRISBbits.TRISB15
    #define GPS0_TRIS       TRISDbits.TRISD5
    #define GPS1_TRIS       TRISDbits.TRISD6
    #define GPSELECT_TRIS   TRISAbits.TRISA10
    #define GPPOWER_TRIS    TRISEbits.TRISE12

// Debug LED pin mapping
    #define DEBUG1_PIN      PORTBbits.RB0
    #define DEBUG2_PIN      PORTBbits.RB1

    #define DEBUG1_TRIS     TRISBbits.TRISB0
    #define DEBUG2_TRIS     TRISBbits.TRISB1

// Special memory sections
    #define PSVPAGE(p)      __attribute__((section(p), space(psv)))
    #define PAGEA           PSVPAGE("PAGEA")
    #define PAGEB           PSVPAGE("PAGEB")
    #define PAGEC           PSVPAGE("PAGEC")
    #define PAGED           PSVPAGE("PAGED")
    #define PAGEE           PSVPAGE("PAGEE")
    #define PAGEF           PSVPAGE("PAGEF")
    #define PAGEG           PSVPAGE("PAGEG")
    #define PAGEH           PSVPAGE("PAGEH")
    #define PAGEI           PSVPAGE("PAGEI")
    #define PAGEJ           PSVPAGE("PAGEJ")
    #define PAGEK           PSVPAGE("PAGEK")
    #define PAGEL           PSVPAGE("PAGEL")
    #define PAGEM           PSVPAGE("PAGEM")
    #define PAGEN           PSVPAGE("PAGEN")
    #define PAGEO           PSVPAGE("PAGEO")
    #define PAGEQ           PSVPAGE("PAGEQ")

#endif	/* CONFIG_H */

