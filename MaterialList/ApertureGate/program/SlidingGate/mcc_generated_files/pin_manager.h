/**
  @Generated Pin Manager Header File

  @Company:
    Microchip Technology Inc.

  @File Name:
    pin_manager.h

  @Summary:
    This is the Pin Manager file generated using MPLAB(c) Code Configurator

  @Description:
    This header file provides implementations for pin APIs for all pins selected in the GUI.
    Generation Information :
        Product Revision  :  MPLAB(c) Code Configurator - 4.15.3
        Device            :  PIC18F26K20
        Version           :  1.01
    The generated drivers are tested against the following:
        Compiler          :  XC8 1.35
        MPLAB             :  MPLAB X 3.40

    Copyright (c) 2013 - 2015 released Microchip Technology Inc.  All rights reserved.

    Microchip licenses to you the right to use, modify, copy and distribute
    Software only when embedded on a Microchip microcontroller or digital signal
    controller that is integrated into your product or third party product
    (pursuant to the sublicense terms in the accompanying license agreement).

    You should refer to the license agreement accompanying this Software for
    additional information regarding your rights and obligations.

    SOFTWARE AND DOCUMENTATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
    EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION, ANY WARRANTY OF
    MERCHANTABILITY, TITLE, NON-INFRINGEMENT AND FITNESS FOR A PARTICULAR PURPOSE.
    IN NO EVENT SHALL MICROCHIP OR ITS LICENSORS BE LIABLE OR OBLIGATED UNDER
    CONTRACT, NEGLIGENCE, STRICT LIABILITY, CONTRIBUTION, BREACH OF WARRANTY, OR
    OTHER LEGAL EQUITABLE THEORY ANY DIRECT OR INDIRECT DAMAGES OR EXPENSES
    INCLUDING BUT NOT LIMITED TO ANY INCIDENTAL, SPECIAL, INDIRECT, PUNITIVE OR
    CONSEQUENTIAL DAMAGES, LOST PROFITS OR LOST DATA, COST OF PROCUREMENT OF
    SUBSTITUTE GOODS, TECHNOLOGY, SERVICES, OR ANY CLAIMS BY THIRD PARTIES
    (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF), OR OTHER SIMILAR COSTS.

*/


#ifndef PIN_MANAGER_H
#define PIN_MANAGER_H

#define INPUT   1
#define OUTPUT  0

#define HIGH    1
#define LOW     0

#define ANALOG      1
#define DIGITAL     0

#define PULL_UP_ENABLED      1
#define PULL_UP_DISABLED     0

// get/set RS aliases
#define RS_TRIS               TRISAbits.TRISA2
#define RS_LAT                LATAbits.LATA2
#define RS_PORT               PORTAbits.RA2
#define RS_ANS                ANSELbits.ANS2
#define RS_SetHigh()            do { LATAbits.LATA2 = 1; } while(0)
#define RS_SetLow()             do { LATAbits.LATA2 = 0; } while(0)
#define RS_Toggle()             do { LATAbits.LATA2 = ~LATAbits.LATA2; } while(0)
#define RS_GetValue()           PORTAbits.RA2
#define RS_SetDigitalInput()    do { TRISAbits.TRISA2 = 1; } while(0)
#define RS_SetDigitalOutput()   do { TRISAbits.TRISA2 = 0; } while(0)
#define RS_SetAnalogMode()  do { ANSELbits.ANS2 = 1; } while(0)
#define RS_SetDigitalMode() do { ANSELbits.ANS2 = 0; } while(0)

// get/set EN aliases
#define EN_TRIS               TRISAbits.TRISA3
#define EN_LAT                LATAbits.LATA3
#define EN_PORT               PORTAbits.RA3
#define EN_ANS                ANSELbits.ANS3
#define EN_SetHigh()            do { LATAbits.LATA3 = 1; } while(0)
#define EN_SetLow()             do { LATAbits.LATA3 = 0; } while(0)
#define EN_Toggle()             do { LATAbits.LATA3 = ~LATAbits.LATA3; } while(0)
#define EN_GetValue()           PORTAbits.RA3
#define EN_SetDigitalInput()    do { TRISAbits.TRISA3 = 1; } while(0)
#define EN_SetDigitalOutput()   do { TRISAbits.TRISA3 = 0; } while(0)
#define EN_SetAnalogMode()  do { ANSELbits.ANS3 = 1; } while(0)
#define EN_SetDigitalMode() do { ANSELbits.ANS3 = 0; } while(0)

// get/set D4 aliases
#define D4_TRIS               TRISAbits.TRISA4
#define D4_LAT                LATAbits.LATA4
#define D4_PORT               PORTAbits.RA4
#define D4_SetHigh()            do { LATAbits.LATA4 = 1; } while(0)
#define D4_SetLow()             do { LATAbits.LATA4 = 0; } while(0)
#define D4_Toggle()             do { LATAbits.LATA4 = ~LATAbits.LATA4; } while(0)
#define D4_GetValue()           PORTAbits.RA4
#define D4_SetDigitalInput()    do { TRISAbits.TRISA4 = 1; } while(0)
#define D4_SetDigitalOutput()   do { TRISAbits.TRISA4 = 0; } while(0)

// get/set D5 aliases
#define D5_TRIS               TRISAbits.TRISA5
#define D5_LAT                LATAbits.LATA5
#define D5_PORT               PORTAbits.RA5
#define D5_ANS                ANSELbits.ANS4
#define D5_SetHigh()            do { LATAbits.LATA5 = 1; } while(0)
#define D5_SetLow()             do { LATAbits.LATA5 = 0; } while(0)
#define D5_Toggle()             do { LATAbits.LATA5 = ~LATAbits.LATA5; } while(0)
#define D5_GetValue()           PORTAbits.RA5
#define D5_SetDigitalInput()    do { TRISAbits.TRISA5 = 1; } while(0)
#define D5_SetDigitalOutput()   do { TRISAbits.TRISA5 = 0; } while(0)
#define D5_SetAnalogMode()  do { ANSELbits.ANS4 = 1; } while(0)
#define D5_SetDigitalMode() do { ANSELbits.ANS4 = 0; } while(0)

// get/set D6 aliases
#define D6_TRIS               TRISAbits.TRISA6
#define D6_LAT                LATAbits.LATA6
#define D6_PORT               PORTAbits.RA6
#define D6_SetHigh()            do { LATAbits.LATA6 = 1; } while(0)
#define D6_SetLow()             do { LATAbits.LATA6 = 0; } while(0)
#define D6_Toggle()             do { LATAbits.LATA6 = ~LATAbits.LATA6; } while(0)
#define D6_GetValue()           PORTAbits.RA6
#define D6_SetDigitalInput()    do { TRISAbits.TRISA6 = 1; } while(0)
#define D6_SetDigitalOutput()   do { TRISAbits.TRISA6 = 0; } while(0)

// get/set D7 aliases
#define D7_TRIS               TRISAbits.TRISA7
#define D7_LAT                LATAbits.LATA7
#define D7_PORT               PORTAbits.RA7
#define D7_SetHigh()            do { LATAbits.LATA7 = 1; } while(0)
#define D7_SetLow()             do { LATAbits.LATA7 = 0; } while(0)
#define D7_Toggle()             do { LATAbits.LATA7 = ~LATAbits.LATA7; } while(0)
#define D7_GetValue()           PORTAbits.RA7
#define D7_SetDigitalInput()    do { TRISAbits.TRISA7 = 1; } while(0)
#define D7_SetDigitalOutput()   do { TRISAbits.TRISA7 = 0; } while(0)

// get/set B0 aliases
#define B0_TRIS               TRISBbits.TRISB0
#define B0_LAT                LATBbits.LATB0
#define B0_PORT               PORTBbits.RB0
#define B0_WPU                WPUBbits.WPUB0
#define B0_ANS                ANSELHbits.ANS12
#define B0_SetHigh()            do { LATBbits.LATB0 = 1; } while(0)
#define B0_SetLow()             do { LATBbits.LATB0 = 0; } while(0)
#define B0_Toggle()             do { LATBbits.LATB0 = ~LATBbits.LATB0; } while(0)
#define B0_GetValue()           PORTBbits.RB0
#define B0_SetDigitalInput()    do { TRISBbits.TRISB0 = 1; } while(0)
#define B0_SetDigitalOutput()   do { TRISBbits.TRISB0 = 0; } while(0)
#define B0_SetPullup()      do { WPUBbits.WPUB0 = 1; } while(0)
#define B0_ResetPullup()    do { WPUBbits.WPUB0 = 0; } while(0)
#define B0_SetAnalogMode()  do { ANSELHbits.ANS12 = 1; } while(0)
#define B0_SetDigitalMode() do { ANSELHbits.ANS12 = 0; } while(0)

// get/set MEN aliases
#define MEN_TRIS               TRISBbits.TRISB1
#define MEN_LAT                LATBbits.LATB1
#define MEN_PORT               PORTBbits.RB1
#define MEN_WPU                WPUBbits.WPUB1
#define MEN_ANS                ANSELHbits.ANS10
#define MEN_SetHigh()            do { LATBbits.LATB1 = 1; } while(0)
#define MEN_SetLow()             do { LATBbits.LATB1 = 0; } while(0)
#define MEN_Toggle()             do { LATBbits.LATB1 = ~LATBbits.LATB1; } while(0)
#define MEN_GetValue()           PORTBbits.RB1
#define MEN_SetDigitalInput()    do { TRISBbits.TRISB1 = 1; } while(0)
#define MEN_SetDigitalOutput()   do { TRISBbits.TRISB1 = 0; } while(0)
#define MEN_SetPullup()      do { WPUBbits.WPUB1 = 1; } while(0)
#define MEN_ResetPullup()    do { WPUBbits.WPUB1 = 0; } while(0)
#define MEN_SetAnalogMode()  do { ANSELHbits.ANS10 = 1; } while(0)
#define MEN_SetDigitalMode() do { ANSELHbits.ANS10 = 0; } while(0)

// get/set MCLK aliases
#define MCLK_TRIS               TRISBbits.TRISB2
#define MCLK_LAT                LATBbits.LATB2
#define MCLK_PORT               PORTBbits.RB2
#define MCLK_WPU                WPUBbits.WPUB2
#define MCLK_ANS                ANSELHbits.ANS8
#define MCLK_SetHigh()            do { LATBbits.LATB2 = 1; } while(0)
#define MCLK_SetLow()             do { LATBbits.LATB2 = 0; } while(0)
#define MCLK_Toggle()             do { LATBbits.LATB2 = ~LATBbits.LATB2; } while(0)
#define MCLK_GetValue()           PORTBbits.RB2
#define MCLK_SetDigitalInput()    do { TRISBbits.TRISB2 = 1; } while(0)
#define MCLK_SetDigitalOutput()   do { TRISBbits.TRISB2 = 0; } while(0)
#define MCLK_SetPullup()      do { WPUBbits.WPUB2 = 1; } while(0)
#define MCLK_ResetPullup()    do { WPUBbits.WPUB2 = 0; } while(0)
#define MCLK_SetAnalogMode()  do { ANSELHbits.ANS8 = 1; } while(0)
#define MCLK_SetDigitalMode() do { ANSELHbits.ANS8 = 0; } while(0)

// get/set MCWCCW aliases
#define MCWCCW_TRIS               TRISBbits.TRISB3
#define MCWCCW_LAT                LATBbits.LATB3
#define MCWCCW_PORT               PORTBbits.RB3
#define MCWCCW_WPU                WPUBbits.WPUB3
#define MCWCCW_ANS                ANSELHbits.ANS9
#define MCWCCW_SetHigh()            do { LATBbits.LATB3 = 1; } while(0)
#define MCWCCW_SetLow()             do { LATBbits.LATB3 = 0; } while(0)
#define MCWCCW_Toggle()             do { LATBbits.LATB3 = ~LATBbits.LATB3; } while(0)
#define MCWCCW_GetValue()           PORTBbits.RB3
#define MCWCCW_SetDigitalInput()    do { TRISBbits.TRISB3 = 1; } while(0)
#define MCWCCW_SetDigitalOutput()   do { TRISBbits.TRISB3 = 0; } while(0)
#define MCWCCW_SetPullup()      do { WPUBbits.WPUB3 = 1; } while(0)
#define MCWCCW_ResetPullup()    do { WPUBbits.WPUB3 = 0; } while(0)
#define MCWCCW_SetAnalogMode()  do { ANSELHbits.ANS9 = 1; } while(0)
#define MCWCCW_SetDigitalMode() do { ANSELHbits.ANS9 = 0; } while(0)

// get/set MH aliases
#define MH_TRIS               TRISBbits.TRISB4
#define MH_LAT                LATBbits.LATB4
#define MH_PORT               PORTBbits.RB4
#define MH_WPU                WPUBbits.WPUB4
#define MH_ANS                ANSELHbits.ANS11
#define MH_SetHigh()            do { LATBbits.LATB4 = 1; } while(0)
#define MH_SetLow()             do { LATBbits.LATB4 = 0; } while(0)
#define MH_Toggle()             do { LATBbits.LATB4 = ~LATBbits.LATB4; } while(0)
#define MH_GetValue()           PORTBbits.RB4
#define MH_SetDigitalInput()    do { TRISBbits.TRISB4 = 1; } while(0)
#define MH_SetDigitalOutput()   do { TRISBbits.TRISB4 = 0; } while(0)
#define MH_SetPullup()      do { WPUBbits.WPUB4 = 1; } while(0)
#define MH_ResetPullup()    do { WPUBbits.WPUB4 = 0; } while(0)
#define MH_SetAnalogMode()  do { ANSELHbits.ANS11 = 1; } while(0)
#define MH_SetDigitalMode() do { ANSELHbits.ANS11 = 0; } while(0)

// get/set INC aliases
#define INC_TRIS               TRISCbits.TRISC0
#define INC_LAT                LATCbits.LATC0
#define INC_PORT               PORTCbits.RC0
#define INC_SetHigh()            do { LATCbits.LATC0 = 1; } while(0)
#define INC_SetLow()             do { LATCbits.LATC0 = 0; } while(0)
#define INC_Toggle()             do { LATCbits.LATC0 = ~LATCbits.LATC0; } while(0)
#define INC_GetValue()           PORTCbits.RC0
#define INC_SetDigitalInput()    do { TRISCbits.TRISC0 = 1; } while(0)
#define INC_SetDigitalOutput()   do { TRISCbits.TRISC0 = 0; } while(0)

// get/set DEC aliases
#define DEC_TRIS               TRISCbits.TRISC1
#define DEC_LAT                LATCbits.LATC1
#define DEC_PORT               PORTCbits.RC1
#define DEC_SetHigh()            do { LATCbits.LATC1 = 1; } while(0)
#define DEC_SetLow()             do { LATCbits.LATC1 = 0; } while(0)
#define DEC_Toggle()             do { LATCbits.LATC1 = ~LATCbits.LATC1; } while(0)
#define DEC_GetValue()           PORTCbits.RC1
#define DEC_SetDigitalInput()    do { TRISCbits.TRISC1 = 1; } while(0)
#define DEC_SetDigitalOutput()   do { TRISCbits.TRISC1 = 0; } while(0)

// get/set SEL aliases
#define SEL_TRIS               TRISCbits.TRISC2
#define SEL_LAT                LATCbits.LATC2
#define SEL_PORT               PORTCbits.RC2
#define SEL_SetHigh()            do { LATCbits.LATC2 = 1; } while(0)
#define SEL_SetLow()             do { LATCbits.LATC2 = 0; } while(0)
#define SEL_Toggle()             do { LATCbits.LATC2 = ~LATCbits.LATC2; } while(0)
#define SEL_GetValue()           PORTCbits.RC2
#define SEL_SetDigitalInput()    do { TRISCbits.TRISC2 = 1; } while(0)
#define SEL_SetDigitalOutput()   do { TRISCbits.TRISC2 = 0; } while(0)

// get/set BACK aliases
#define BACK_TRIS               TRISCbits.TRISC3
#define BACK_LAT                LATCbits.LATC3
#define BACK_PORT               PORTCbits.RC3
#define BACK_SetHigh()            do { LATCbits.LATC3 = 1; } while(0)
#define BACK_SetLow()             do { LATCbits.LATC3 = 0; } while(0)
#define BACK_Toggle()             do { LATCbits.LATC3 = ~LATCbits.LATC3; } while(0)
#define BACK_GetValue()           PORTCbits.RC3
#define BACK_SetDigitalInput()    do { TRISCbits.TRISC3 = 1; } while(0)
#define BACK_SetDigitalOutput()   do { TRISCbits.TRISC3 = 0; } while(0)

// get/set IO_RC4 aliases
#define IO_RC4_TRIS               TRISCbits.TRISC4
#define IO_RC4_LAT                LATCbits.LATC4
#define IO_RC4_PORT               PORTCbits.RC4
#define IO_RC4_SetHigh()            do { LATCbits.LATC4 = 1; } while(0)
#define IO_RC4_SetLow()             do { LATCbits.LATC4 = 0; } while(0)
#define IO_RC4_Toggle()             do { LATCbits.LATC4 = ~LATCbits.LATC4; } while(0)
#define IO_RC4_GetValue()           PORTCbits.RC4
#define IO_RC4_SetDigitalInput()    do { TRISCbits.TRISC4 = 1; } while(0)
#define IO_RC4_SetDigitalOutput()   do { TRISCbits.TRISC4 = 0; } while(0)

// get/set IO_RC5 aliases
#define IO_RC5_TRIS               TRISCbits.TRISC5
#define IO_RC5_LAT                LATCbits.LATC5
#define IO_RC5_PORT               PORTCbits.RC5
#define IO_RC5_SetHigh()            do { LATCbits.LATC5 = 1; } while(0)
#define IO_RC5_SetLow()             do { LATCbits.LATC5 = 0; } while(0)
#define IO_RC5_Toggle()             do { LATCbits.LATC5 = ~LATCbits.LATC5; } while(0)
#define IO_RC5_GetValue()           PORTCbits.RC5
#define IO_RC5_SetDigitalInput()    do { TRISCbits.TRISC5 = 1; } while(0)
#define IO_RC5_SetDigitalOutput()   do { TRISCbits.TRISC5 = 0; } while(0)

// get/set SWITCH_FULL aliases
#define SWITCH_FULL_TRIS               TRISCbits.TRISC6
#define SWITCH_FULL_LAT                LATCbits.LATC6
#define SWITCH_FULL_PORT               PORTCbits.RC6
#define SWITCH_FULL_SetHigh()            do { LATCbits.LATC6 = 1; } while(0)
#define SWITCH_FULL_SetLow()             do { LATCbits.LATC6 = 0; } while(0)
#define SWITCH_FULL_Toggle()             do { LATCbits.LATC6 = ~LATCbits.LATC6; } while(0)
#define SWITCH_FULL_GetValue()           PORTCbits.RC6
#define SWITCH_FULL_SetDigitalInput()    do { TRISCbits.TRISC6 = 1; } while(0)
#define SWITCH_FULL_SetDigitalOutput()   do { TRISCbits.TRISC6 = 0; } while(0)

// get/set SWITCH_EMPTY aliases
#define SWITCH_EMPTY_TRIS               TRISCbits.TRISC7
#define SWITCH_EMPTY_LAT                LATCbits.LATC7
#define SWITCH_EMPTY_PORT               PORTCbits.RC7
#define SWITCH_EMPTY_SetHigh()            do { LATCbits.LATC7 = 1; } while(0)
#define SWITCH_EMPTY_SetLow()             do { LATCbits.LATC7 = 0; } while(0)
#define SWITCH_EMPTY_Toggle()             do { LATCbits.LATC7 = ~LATCbits.LATC7; } while(0)
#define SWITCH_EMPTY_GetValue()           PORTCbits.RC7
#define SWITCH_EMPTY_SetDigitalInput()    do { TRISCbits.TRISC7 = 1; } while(0)
#define SWITCH_EMPTY_SetDigitalOutput()   do { TRISCbits.TRISC7 = 0; } while(0)

/**
   @Param
    none
   @Returns
    none
   @Description
    GPIO and peripheral I/O initialization
   @Example
    PIN_MANAGER_Initialize();
 */
void PIN_MANAGER_Initialize (void);

/**
 * @Param
    none
 * @Returns
    none
 * @Description
    Interrupt on Change Handling routine
 * @Example
    PIN_MANAGER_IOC();
 */
void PIN_MANAGER_IOC(void);



#endif // PIN_MANAGER_H
/**
 End of File
*/