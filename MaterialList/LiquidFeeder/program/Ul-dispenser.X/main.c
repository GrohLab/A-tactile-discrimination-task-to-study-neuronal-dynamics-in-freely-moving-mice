/******************************************************************************/
/**********              File:  ULitre_dispenser.c             ****************/
/**********     Author: Lee Embray, Heidelberg Universität     ****************/
/**********  Physiology und Pathophysiology abteilung          ****************/
/**********           Created on 16. October 2017,             ****************/
/******************************************************************************/

/******************************************************************************/
/********************************* DEFINE *************************************/
/******************************************************************************/
#define RS RA2                                                                  // LCD Register Select pin
#define EN RA3                                                                  // LCD Enable pin 
#define D4 RA4                                                                  // LCD DATA 0
#define D5 RA5                                                                  // LCD DATA 1                 
#define D6 RA6                                                                  // LCD DATA 2
#define D7 RA7                                                                  // LCD DATA 3

#define DOSE RB0                                                                // LCD Register Select pin
#define MEN RB1                                                                 // LCD Enable pin 
#define MCLK RB2                                                                // LCD DATA 0
#define MCW RB3                                                                 // LCD DATA 1                 
#define MH RB4                                                                  // LCD DATA 2
#define INC RC0                                                                 // LCD DATA 3  
#define DEC RC1                                                                 // LCD DATA 3 
#define SEL RC2                                                                 // LCD DATA 3 
#define TRIG RC3                                                                // LCD DATA 3 
#define SPOUT1 RC4                                                              // LCD DATA 3 
#define SPOUT2 RC5                                                              // LCD DATA 3 
#define FULL RC6                                                                // LCD DATA 3 
#define EMPTY RC7                                                               // LCD DATA 3 
/******************************************************************************/
/******************************** INCLUDE *************************************/
/******************************************************************************/
#include "mcc_generated_files/mcc.h"
#include "lcd.h"
#include <stdio.h>
#include <time.h>
#include <stdlib.h>
/******************************************************************************/
/************************** DEFINE VARIABLES **********************************/
/******************************************************************************/
unsigned int quantity;
unsigned int steps;
unsigned int quantitytemp;
unsigned int stepstemp;
unsigned int check;
unsigned eeprom char address1 = 0x10;
char s[20];
/**************************** FUNCTION ****************************************/
/************************** DELAY 200mS ***************************************/
/******************************************************************************/
void delay(void)                                                                // function for 200mS delay
{
    __delay_ms(100);
    __delay_ms(100);
}
/**************************** FUNCTION ****************************************/
/************************** DELAY 500mS ***************************************/
/******************************************************************************/
void delay5(void)                                                               // function for 500mS delay
{
    __delay_ms(100);
    __delay_ms(100);
    __delay_ms(100);
    __delay_ms(100);
    __delay_ms(100);
}
/****************************** FUNCTION **************************************/
/****************** eeprom save function 8bit number **************************/
/******************************************************************************/
void eepromsave(void)                                                           // function for saving the values to non volatile memory
{   
DATAEE_WriteByte(address1, quantity);
}
/****************************** FUNCTION **************************************/
/***************** eeprom load delay function 8bit number *********************/
/******************************************************************************/
void eepromload(void)                                                           // function for loading the values from non volatile memory
{ 
quantity = DATAEE_ReadByte(address1);
 }
/**************************** FUNCTION ****************************************/
/************************** set quantity **************************************/
/******************************************************************************/
void SETQUANTITY(void)                                                          // function for setting the pulse duration and to save in "trig1 and trig2"
{
delay5();                                                                        // anti bounce
Lcd_Clear();                                                                    // clear the LCD    
while(SEL != 0)                                                                 // until select button is pressed stay in function "PULSE SET"
    {
    if(quantity > 250)                                                          // if time is out of range then set to 250
        quantity = 250;
    sprintf(s, "QUANTITY=%u Ul", quantity);                                     // make s = "time"
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor to line 1 position 1
    Lcd_Write_String(s);                                                        // write text "s" to line 1
    if(INC == 0 && quantity < 250)                                              // allow maximum of 250mSec                     
        {                      
        quantity = quantity+1;                                                  // if left button pressed then increment "time" by 1
        __delay_ms(30);                                                         // set delay to fix key bounce and auto increment on hold speed
        Lcd_Clear();                                                            // clear the LCD 
        }   
    if(DEC == 0 && quantity > 1)                                                // allow minimum of 1mSec
        {
        quantity = quantity-1;                                                  // if right button pressed then decrement "time" by 1
        __delay_ms(30);                                                         // set delay to fix key bounce and auto increment on hold speed
        Lcd_Clear();                                                            // clear the LCD                                                        
        }
    quantitytemp = quantity;                                                // save time in temp
    }
Lcd_Clear();                                                                    // clear LCD
eepromsave();                                                                   // save all values to eeprom using eepromsave function
}
/**************************** FUNCTION ****************************************/
/***************************** EMPTY ******************************************/
/******************************************************************************/
void EMPTYSYRINGE(void)                                                         // menu function for selecting amount to dispense
{
Lcd_Clear();
Lcd_Set_Cursor(1,1);                                                            // set LCD cursor on line 1 position 1
Lcd_Write_String("EMPTYING SYRINGE");                                           // write text to line 1
Lcd_Set_Cursor(2,1);                                                            // set LCD cursor on line 1 position 1
Lcd_Write_String("SEL = STOP");                                                 // write text to line 1
MCW = 0;                                                                        // SET MOTOR TO CLOCKWISE
MEN = 1;                                                                        // ENABLE MOTOR
while(SEL != 0 && EMPTY != 0)                                                   // until select button is pressed stay in function "EMPTY FILL"
    {
    MCLK = 1;                                                                   // SEND PULSES TO MOTOR
    __delay_us(500);
    MCLK = 0;
    __delay_us(500);
    }
MEN = 0;                                                                        // DISABLE MOTOR
Lcd_Clear();
}
/**************************** FUNCTION ****************************************/
/****************************** FILL ******************************************/
/******************************************************************************/
void FILLSYRINGE(void)                                                          // menu function for selecting amount to dispense
{
Lcd_Clear();
Lcd_Set_Cursor(1,1);                                                            // set LCD cursor on line 1 position 1
Lcd_Write_String("FILLING SYRINGE");                                            // write text to line 1
Lcd_Set_Cursor(2,1);                                                            // set LCD cursor on line 1 position 1
Lcd_Write_String("SEL = STOP");                                                 // write text to line 1
MCW = 1;                                                                        // SET MOTOR TO ANTI-CLOCKWISE 
MEN = 1;                                                                        // ENABLE MOTOR
while(SEL != 0 && FULL != 0)                                                    // until select button is pressed stay in function "EMPTY FILL"
    {           
    MCLK = 1;                                                                   // SEND PULSES TO MOTOR
    __delay_us(500);
    MCLK = 0;
    __delay_us(500);
    }
MEN = 0;                                                                        // DISABLE MOTOR
Lcd_Clear();
}
/**************************** FUNCTION ****************************************/
/*************************** EMPTY FILL ***************************************/
/******************************************************************************/
void EMPTYFILL(void)
{
delay5();
Lcd_Clear();
while(SEL != 0)                                                                 // until select button is pressed stay in function "EMPTY FILL"
    {
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String("INC = FILL");                                             // write text to line 1
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String("DEC = EMPTY");                                            // write text to line 1
    delay5();
    if(INC == 0)                                                                // if INC button pressed then goto "FILL" function
    FILLSYRINGE();                                                              // goto FILL function
    if(DEC == 0)                                                                // if DEC button pressed then goto "EMPTY" function
    EMPTYSYRINGE();                                                             // goto EMPTY function 
    }
Lcd_Clear();                                                                    // clear LCD
}
/**************************** FUNCTION ****************************************/
/***************************** SETUP ******************************************/
/******************************************************************************/
void SETUP(void)
{
delay5();    
Lcd_Set_Cursor(1,1);                                                            // set LCD cursor on line 1 position 1
Lcd_Write_String("INC = SET AMOUNT ");                                          // write text to line 1 
Lcd_Set_Cursor(2,1);                                                            // set LCD cursor on line 2 position 1
Lcd_Write_String("DEC = EMPTY/FILL     ");                                      // write text to line 2
while(SEL != 0)                                                                 // until select button is pressed stay in function "EMPTY FILL"
    {
    if(INC == 0)                                                                    // if INC button pressed then goto "SET QUANTITY" function
    SETQUANTITY();                                                              // goto setup1 function
    if(DEC == 0)                                                                    // if DEC button pressed then goto "DROP" function
    EMPTYFILL();
    }
Lcd_Clear();
}
/**************************** FUNCTION ****************************************/
/***************************EMPTY MESSAGE *************************************/
/******************************************************************************/
void EMPTYMESSAGE(void)
{
Lcd_Clear();
    while(SEL !=0)
    {
    Lcd_Set_Cursor(1,1);                                                            // set LCD cursor on line 1 position 1
    Lcd_Write_String("SYRINGE EMPTY");                                           // write text to line 1
    Lcd_Set_Cursor(2,1);                                                            // set LCD cursor on line 1 position 1
    Lcd_Write_String("SEL = EXIT");                                                 // write text to line 1
    }
}
/**************************** FUNCTION ****************************************/
/*************************** ADMINISTER ***************************************/
/******************************************************************************/
void ADMINISTER(void)
{
while(EMPTY != 0 && SEL !=0 && check != 1)
    {
    quantitytemp = quantity;
    stepstemp = 13;
    Lcd_Clear();
    Lcd_Set_Cursor(1,1);                                                            // set LCD cursor on line 1 position 1
    Lcd_Write_String("DISPENSING");                                           // write text to line 1
    MCW = 0;
    MEN = 1;                                                                                         // ENABLE MOTOR
    while(quantitytemp != 0)           
        {   
        if(EMPTY ==0)
            {
            MEN = 0;
            }
        MCLK = 1;                                                           // SEND PULSES TO MOTOR
        __delay_us(500);                                                      // --------------------
        MCLK = 0;                                                           // --------------------
        __delay_us(500);                                                      // --------------------
        if(stepstemp != 0)                                                  // IF 1Ul IS DISPENSED THE START DECREMEMTING VARIABLE "QUANTITYTEMP" 
            {
            stepstemp = stepstemp-1;                                        // DECREMENT STEPSTEMP UNTIL 1Ulitre IS DISPENSED
            }
        if(stepstemp == 0)
            {
            quantitytemp = quantitytemp-1;                                  // DECREMENT "QUANTITYTEMP" VARIABLE
            stepstemp = 13;                                                 // RESTORE STEPS TEMP TO 13 FOR NEXT UNIT OF 1Ulitre
            }
        if(quantitytemp == 0)
            {
            check =1;
            }
        }
    MEN = 0;
    }
if(EMPTY == 0)
    {                                                                
    EMPTYMESSAGE();
    }
Lcd_Clear();
}
/**************************** FUNCTION ****************************************/
/****************************** RUN *******************************************/
/******************************************************************************/
void RUN(void)
{
    Lcd_Clear();
while(SEL !=0)
    {
    Lcd_Set_Cursor(1,1);                                                            // set LCD cursor on line 1 position 1
    Lcd_Write_String("AWAITING TRIGGER");                                           // write text to line 1
    Lcd_Set_Cursor(2,1);                                                            // set LCD cursor on line 1 position 1
    Lcd_Write_String("SEL = EXIT");                                                 // write text to line 1
    if(TRIG == 1 || DOSE == 0)
        {
        check = 0;
        ADMINISTER();
        }
    }
Lcd_Clear();
}    
/******************************************************************************/
/******************** MAIN PROGRAM STARTS RUNNING HERE ************************/
/******************************************************************************/
void main(void)                                                                 // start of main program
{ 
SYSTEM_Initialize();                                                            // Initialize the device 
MH = 1;                                                                         // SET MOTOR TO HALF STEP MODE
steps = 13;
eepromload();
quantitytemp = quantity;
/***************************** STARTUP RUN ONCE *******************************/
/******************************** LCD INTRO ***********************************/
/******************************************************************************/   
Lcd_Init();                                                                     // initialize the LCD
Lcd_Clear();                                                                    // clear LCD
Lcd_Set_Cursor(1,1);                                                            // set LCD cursor on line 1 position 1
Lcd_Write_String("  Ul Dispensor  ");                                            // write text to line 1
Lcd_Set_Cursor(2,1);                                                            // set LCD cursor on line 2 position 1
Lcd_Write_String("    L.Embray     ");                                           // write text to line 2
delay5();                                                                       // hold display for 750mS
delay5();                                                                       // hold display for 750mS
Lcd_Clear();                                                                    // clear LCD
Lcd_Set_Cursor(1,1);                                                            // set LCD cursor on line 1 position 1
Lcd_Write_String("    Ver 1.0     ");                                            // write text to line 1
Lcd_Set_Cursor(2,1);                                                            // set LCD cursor on line 2 position 1
Lcd_Write_String("   26/01/2021   ");                                           // write text to line 2
delay5();                                                                       // hold display for 750mS
delay5();                                                                       // hold display for 750mS
Lcd_Clear();                                                                    // clear LCD
Lcd_Set_Cursor(1,1);                                                            // set LCD cursor on line 1 position 1
Lcd_Write_String("   Heidelberg");                                              // write text to line 1
Lcd_Set_Cursor(2,1);                                                            // set LCD cursor on line 2 position 1
Lcd_Write_String("  Universitaet");                                             // write text to line 2
delay5();                                                                       // hold display for 750mS
delay5();                                                                       // hold display for 750mS  
Lcd_Clear();                                                                    // clear LCD
Lcd_Set_Cursor(1,1);                                                            // set LCD cursor on line 1 position 1
Lcd_Write_String(" Institut fuer");                                             // write text to line 1
Lcd_Set_Cursor(2,1);                                                            // set LCD cursor on line 2 position 1
Lcd_Write_String("  Physiologie");                                              // write text to line 2
delay5();                                                                       // hold display for 750mS
delay5();                                                                       // hold display for 750mS
Lcd_Clear();                                                                    // clear LCD
/******************************************************************************/
/**************************** MAIN PROGRAM ************************************/
/******************************************************************************/ 
while (1)   
    {
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String("INC = RUN ");                                             // write text to line 1 
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("DEC = SETUP     ");                                       // write text to line 2
    if(INC == 0)                                                                // if INC button pressed then goto "SET QUANTITY" function
        RUN();                                                                  // goto setup1 function
    if(DEC == 0)                                                                // if DEC button pressed then goto "DROP" function
        SETUP(); 
    }
}




