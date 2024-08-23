/******************************************************************************/
/**********                File:  Sliding Door.c               ****************/
/**********     Author: Lee Embray, Heidelberg Universität     ****************/
/**********  Physiology und Pathophysiology abteilung          ****************/
/**********           Created on 19. July 2021,             ****************/
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
#define B0 RB0                                                                  // INPUT BIT 0
#define MEN RB1                                                                 // MOTOR ENABLE 
#define MCLK RB2                                                                // MOTOR CLOCK
#define MCW RB3                                                                 // MOTOR DIRECTION                 
#define MH RB4                                                                  // MOTOR STEP
#define INC RC0                                                                 // INC/YELLOW BUTTON  
#define DEC RC1                                                                 // DEC/GREEN BUTTON 
#define SEL RC2                                                                 // SEL/RED BUTTON 
#define BACK RC3                                                                // BACK/BLUE BUTTON 
#define B1 RC4                                                                  // INPUT BIT 1 
#define B2 RC5                                                                  // INPUT BIT 2 
#define OPEN RC6                                                                // FULLY OPEN SWITCH 
#define CLOSED RC7                                                              // FULLY CLOSED SWITCH 
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
unsigned int pos0;
unsigned int pos1;
unsigned int pos2;
unsigned int pos3;
unsigned int pos4;
unsigned int pos5;
unsigned int pos6;
unsigned int pos7;
unsigned int fake;
unsigned int pos0temp;
unsigned int pos1temp;
unsigned int pos2temp;
unsigned int pos3temp;
unsigned int pos4temp;
unsigned int pos5temp;
unsigned int pos6temp;
unsigned int pos7temp;
unsigned int faketemp;
unsigned int current;
unsigned int count;
unsigned int clock;
unsigned int multiplier;
unsigned int input;
unsigned eeprom char address1 = 0x10;
unsigned eeprom char address2 = 0x11;
unsigned eeprom char address3 = 0x12;
unsigned eeprom char address4 = 0x13;
unsigned eeprom char address5 = 0x14;
unsigned eeprom char address6 = 0x15;
unsigned eeprom char address7 = 0x16;
unsigned eeprom char address8 = 0x20;
char s[20];

/**************************** FUNCTION ****************************************/
/************************** DELAY 200mS ***************************************/
/******************************************************************************/
void delay2(void)                                                               // function for 200mS delay
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
DATAEE_WriteByte(address1, pos0);
DATAEE_WriteByte(address2, pos1);
DATAEE_WriteByte(address3, pos2);
DATAEE_WriteByte(address4, pos3);
DATAEE_WriteByte(address5, pos4);
DATAEE_WriteByte(address6, pos5);
DATAEE_WriteByte(address7, pos6);
DATAEE_WriteByte(address8, pos7);
}
/****************************** FUNCTION **************************************/
/****************** eeprom load function 8bit number **************************/
/******************************************************************************/
void eepromload(void)                                                           // function for loading the values from non volatile memory
{ 
pos0 = DATAEE_ReadByte(address1);
pos1 = DATAEE_ReadByte(address2);
pos2 = DATAEE_ReadByte(address3);
pos3 = DATAEE_ReadByte(address4);
pos4 = DATAEE_ReadByte(address5);
pos5 = DATAEE_ReadByte(address6);
pos6 = DATAEE_ReadByte(address7);
pos7 = DATAEE_ReadByte(address7);
}
/*************************** SET POSITION 0 ***********************************/
/******************************************************************************/
void set0(void)
{
delay2();
Lcd_Clear();                                                                    // clear the LCD    
while(SEL != 0)                                                                 // until select button is pressed stay in function "PULSE SET"
    {
    if(pos0 > 55)                                                               // if time is out of range then set to 250
        pos0 = 55;
    sprintf(s, "POSITION0=%umm", pos0);                                         // make s = "time"
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor to line 1 position 1
    Lcd_Write_String(s);                                                        // write text "s" to line 1
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("+   -    SEL     ");                                       // write text to line 2 
    if(INC == 0 && pos0 < 55)                                                   // allow maximum of 250mSec                     
        {                      
        pos0 = pos0+1;                                                          // if left button pressed then increment "time" by 1
        __delay_ms(30);                                                         // set delay to fix key bounce and auto increment on hold speed
        Lcd_Clear();                                                            // clear the LCD 
        }   
    if(DEC == 0 && pos0 > 0)                                                    // allow minimum of 1mSec
        {
        pos0 = pos0-1;                                                          // if right button pressed then decrement "time" by 1
        __delay_ms(30);                                                         // set delay to fix key bounce and auto increment on hold speed
        Lcd_Clear();                                                            // clear the LCD                                                        
        }
    }
Lcd_Clear();                                                                    // clear LCD
eepromsave();                                                                   // save all values to eeprom using eepromsave function
}
/*************************** SET POSITION 1 ***********************************/
/******************************************************************************/
void set1(void)
{
delay2();
Lcd_Clear();                                                                    // clear the LCD    
while(SEL != 0)                                                                 // until select button is pressed stay in function "PULSE SET"
    {    
    if(pos1 > 55)                                                               // if time is out of range then set to 250
        pos1 = 55;
    sprintf(s, "POSITION1=%umm", pos1);                                         // make s = "time"
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor to line 1 position 1
    Lcd_Write_String(s);                                                        // write text "s" to line 1
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("+   -    SEL     ");                                       // write text to line 2 
    if(INC == 0 && pos1 < 55)                                                   // allow maximum of 250mSec                     
        {                      
        pos1 = pos1+1;                                                          // if left button pressed then increment "time" by 1
        __delay_ms(30);                                                         // set delay to fix key bounce and auto increment on hold speed
        Lcd_Clear();                                                            // clear the LCD 
        }   
    if(DEC == 0 && pos1 > 0)                                                    // allow minimum of 1mSec
        {
        pos1 = pos1-1;                                                          // if right button pressed then decrement "time" by 1
        __delay_ms(30);                                                         // set delay to fix key bounce and auto increment on hold speed
        Lcd_Clear();                                                            // clear the LCD                                                        
        }
    }
Lcd_Clear();                                                                    // clear LCD
eepromsave();                                                                   // save all values to eeprom using eepromsave function
}
/*************************** SET POSITION 2 ***********************************/
/******************************************************************************/
void set2(void)
{
delay2();
Lcd_Clear();                                                                    // clear the LCD    
while(SEL != 0)                                                                 // until select button is pressed stay in function "PULSE SET"
    {
    if(pos2 > 55)                                                               // if time is out of range then set to 250
        pos2 = 55;
    sprintf(s, "POSITION2=%umm", pos2);                                         // make s = "time"
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor to line 1 position 1
    Lcd_Write_String(s);                                                        // write text "s" to line 1
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("+   -   SEL     ");                                       // write text to line 2 
    if(INC == 0 && pos2 < 55)                                                   // allow maximum of 250mSec                     
        {                      
        pos2 = pos2+1;                                                          // if left button pressed then increment "time" by 1
        __delay_ms(30);                                                         // set delay to fix key bounce and auto increment on hold speed
        Lcd_Clear();                                                            // clear the LCD 
        }   
    if(DEC == 0 && pos2 > 0)                                                    // allow minimum of 1mSec
        {
        pos2 = pos2-1;                                                          // if right button pressed then decrement "time" by 1
        __delay_ms(30);                                                         // set delay to fix key bounce and auto increment on hold speed
        Lcd_Clear();                                                            // clear the LCD                                                        
        }                                           
    }
Lcd_Clear();                                                                    // clear LCD
eepromsave();                                                                   // save all values to eeprom using eepromsave function
}
/*************************** SET POSITION 3 ***********************************/
/******************************************************************************/
void set3(void)
{
delay2();
Lcd_Clear();                                                                    // clear the LCD    
while(SEL != 0)                                                                 // until select button is pressed stay in function "PULSE SET"
    {
    if(pos3 > 55)                                                               // if time is out of range then set to 250
        pos3 = 55;
    sprintf(s, "POSITION3=%umm", pos3);                                         // make s = "time"
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor to line 1 position 1
    Lcd_Write_String(s);                                                        // write text "s" to line 1
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("+   -   SEL     ");                                       // write text to line 2 
    if(INC == 0 && pos3 < 55)                                                   // allow maximum of 250mSec                     
        {                      
        pos3 = pos3+1;                                                          // if left button pressed then increment "time" by 1
        __delay_ms(30);                                                         // set delay to fix key bounce and auto increment on hold speed
        Lcd_Clear();                                                            // clear the LCD 
        }   
    if(DEC == 0 && pos3 > 0)                                                    // allow minimum of 1mSec
        {
        pos3 = pos3-1;                                                          // if right button pressed then decrement "time" by 1
        __delay_ms(30);                                                         // set delay to fix key bounce and auto increment on hold speed
        Lcd_Clear();                                                            // clear the LCD                                                        
        }
    }
Lcd_Clear();                                                                    // clear LCD
eepromsave();                                                                   // save all values to eeprom using eepromsave function
}
/*************************** SET POSITION 4 ***********************************/
/******************************************************************************/
void set4(void)
{
delay2();
Lcd_Clear();                                                                    // clear the LCD    
while(SEL != 0)                                                                 // until select button is pressed stay in function "PULSE SET"
    {
    if(pos4 > 55)                                                               // if time is out of range then set to 250
        pos4 = 55;
    sprintf(s, "POSITION4=%umm", pos4);                                         // make s = "time"
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor to line 1 position 1
    Lcd_Write_String(s);                                                        // write text "s" to line 1
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("+   -   SEL     ");                                       // write text to line 2 
    if(INC == 0 && pos4 < 55)                                                   // allow maximum of 250mSec                     
        {                      
        pos4 = pos4+1;                                                          // if left button pressed then increment "time" by 1
        __delay_ms(30);                                                         // set delay to fix key bounce and auto increment on hold speed
        Lcd_Clear();                                                            // clear the LCD 
        }   
    if(DEC == 0 && pos4 > 0)                                                    // allow minimum of 1mSec
        {
        pos4 = pos4-1;                                                          // if right button pressed then decrement "time" by 1
        __delay_ms(30);                                                         // set delay to fix key bounce and auto increment on hold speed
        Lcd_Clear();                                                            // clear the LCD                                                        
        }
    }
Lcd_Clear();                                                                    // clear LCD
eepromsave();                                                                   // save all values to eeprom using eepromsave function
}
/*************************** SET POSITION 5 ***********************************/
/******************************************************************************/
void set5(void)
{
delay2();
Lcd_Clear();                                                                    // clear the LCD    
while(SEL != 0)                                                                 // until select button is pressed stay in function "PULSE SET"
    {
    if(pos5 > 55)                                                               // if time is out of range then set to 250
        pos5 = 55;
    sprintf(s, "POSITION5=%u mm", pos5);                                        // make s = "time"
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor to line 1 position 1
    Lcd_Write_String(s);                                                        // write text "s" to line 1
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("+   -   SEL     ");                                       // write text to line 2 
    if(INC == 0 && pos5 < 55)                                                   // allow maximum of 250mSec                     
        {                      
        pos5 = pos5+1;                                                          // if left button pressed then increment "time" by 1
        __delay_ms(30);                                                         // set delay to fix key bounce and auto increment on hold speed
        Lcd_Clear();                                                            // clear the LCD 
        }   
    if(DEC == 0 && pos5 > 0)                                                    // allow minimum of 1mSec
        {
        pos5 = pos5-1;                                                          // if right button pressed then decrement "time" by 1
        __delay_ms(30);                                                         // set delay to fix key bounce and auto increment on hold speed
        Lcd_Clear();                                                            // clear the LCD                                                        
        }
    }
Lcd_Clear();                                                                    // clear LCD
eepromsave();                                                                   // save all values to eeprom using eepromsave function
}
/*************************** SET POSITION 6 ***********************************/
/******************************************************************************/
void set6(void)
{
delay2();
Lcd_Clear();                                                                    // clear the LCD    
while(SEL != 0)                                                                 // until select button is pressed stay in function "PULSE SET"
    {
    if(pos6 > 55)                                                          // if time is out of range then set to 250
        pos6 = 55;
    sprintf(s, "POSITION6=%u mm", pos6);                                        // make s = "time"
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor to line 1 position 1
    Lcd_Write_String(s);                                                        // write text "s" to line 1
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("+   -   SEL     ");                                       // write text to line 2 
    if(INC == 0 && pos6 < 55)                                                   // allow maximum of 250mSec                     
        {                      
        pos6 = pos6+1;                                                          // if left button pressed then increment "time" by 1
        __delay_ms(30);                                                         // set delay to fix key bounce and auto increment on hold speed
        Lcd_Clear();                                                            // clear the LCD 
        }   
    if(DEC == 0 && pos6 > 0)                                                    // allow minimum of 1mSec
        {
        pos6 = pos6-1;                                                          // if right button pressed then decrement "time" by 1
        __delay_ms(30);                                                         // set delay to fix key bounce and auto increment on hold speed
        Lcd_Clear();                                                            // clear the LCD                                                        
        }
    }
Lcd_Clear();                                                                    // clear LCD
eepromsave();                                                                   // save all values to eeprom using eepromsave function
}
/*************************** SET POSITION 7 ***********************************/
/******************************************************************************/
void set7(void)
{
delay2();
Lcd_Clear();                                                                    // clear the LCD    
while(SEL != 0)                                                                 // until select button is pressed stay in function "PULSE SET"
    {
    if(pos7 > 55)                                                               // if time is out of range then set to 250
        pos7 = 55;
    sprintf(s, "POSITION7=%u mm", pos7);                                        // make s = "time"
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor to line 1 position 1
    Lcd_Write_String(s);                                                        // write text "s" to line 1
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("+   -   SEL     ");                                       // write text to line 2 
    if(INC == 0 && pos7 < 55)                                                   // allow maximum of 250mSec                     
        {                      
        pos7 = pos7+1;                                                          // if left button pressed then increment "time" by 1
        __delay_ms(30);                                                         // set delay to fix key bounce and auto increment on hold speed
        Lcd_Clear();                                                            // clear the LCD 
        }   
    if(DEC == 0 && pos7 > 0)                                                    // allow minimum of 1mSec
        {
        pos7 = pos7-1;                                                          // if right button pressed then decrement "time" by 1
        __delay_ms(30);                                                         // set delay to fix key bounce and auto increment on hold speed
        Lcd_Clear();                                                            // clear the LCD                                                        
        }
    }
Lcd_Clear();                                                                    // clear LCD
eepromsave();                                                                   // save all values to eeprom using eepromsave function
}
/************************************ menu7 ***********************************/
/******************************************************************************/
void menu7(void)
{
Lcd_Clear();    
while(BACK != 0)
    {
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String("SET POSITION 7");                                         // write text to line 1 
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("NEXT    SEL BACK");                                       // write text to line 2 
    __delay_ms(150);
    if(SEL == 0) 
        set7();
    if(INC == 0)
        delay5();  
    }
}
/************************************ menu6 ***********************************/
/******************************************************************************/
void menu6(void)
{
Lcd_Clear();    
while(BACK != 0)
    {
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String("SET POSITION 6");                                         // write text to line 1 
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("NEXT    SEL BACK");                                       // write text to line 2 
    __delay_ms(150);
    if(SEL == 0) 
        set6();
    if(INC == 0)
        delay5();                                                               // set to set7 to use all 8 presets
    }
}
/************************************ menu5 ***********************************/
/******************************************************************************/
void menu5(void)
{
Lcd_Clear();    
while(BACK != 0)
    {
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String("SET POSITION 5");                                         // write text to line 1 
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("NEXT    SEL BACK");                                       // write text to line 2 
    __delay_ms(150);
    if(SEL == 0) 
        set5();
    if(INC == 0)
        menu6();    
    }
}
/************************************ menu4 ***********************************/
/******************************************************************************/
void menu4(void)
{
Lcd_Clear();    
while(BACK != 0)
    {
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String("SET POSITION 4");                                         // write text to line 1 
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("NEXT    SEL BACK");                                       // write text to line 2 
    __delay_ms(150);
    if(SEL == 0) 
        set4();
    if(INC == 0)
        menu5();    
    }
}
/************************************ menu3 ***********************************/
/******************************************************************************/
void menu3(void)
{
Lcd_Clear();    
while(BACK != 0)
    {
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String("SET POSITION 3");                                         // write text to line 1 
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("NEXT    SEL BACK");                                       // write text to line 2
    __delay_ms(150);
    if(SEL == 0) 
        set3();
    if(INC == 0)
        menu4();    
    }
}
/************************************ menu2 ***********************************/
/******************************************************************************/
void menu2(void)
{
Lcd_Clear();    
while(BACK != 0)
    {
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String("SET POSITION 2");                                         // write text to line 1 
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("NEXT    SEL BACK");                                       // write text to line 2 
    __delay_ms(150);
    if(SEL == 0) 
        set2();
    if(INC == 0)
        menu3();    
    }
}
/************************************ menu1 ***********************************/
/******************************************************************************/
void menu1(void)
{
Lcd_Clear();
while(BACK != 0)
    {   
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String("SET POSITION 1");                                         // write text to line 1 
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("NEXT    SEL BACK");                                       // write text to line 2
    __delay_ms(150);
    if(SEL == 0) 
        set1();
    if(INC == 0)
        menu2();    
    }
}
/************************************ menu0 ***********************************/
/******************************************************************************/
void menu0(void)
{
Lcd_Clear();
while(BACK != 0)
    {
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String("SET POSITION 0");                                         // write text to line 1 
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("NEXT    SEL BACK");                                       // write text to line 2
    __delay_ms(150);
    if(SEL == 0) 
        set0();
    if(INC == 0)
        menu1();               
    }
}
/**************************** FUNCTION ****************************************/
/************************* HOME POSITION **************************************/
/******************************************************************************/
void home(void)                                                                 // function to return to home/closed position
{
MCW = 0;                                                                        // set motor to anti-clockwise 
MEN = 1;                                                                        // enable motor
while(CLOSED != 0)                                                              // move doors to closed position
    {           
    MCLK = 0;                                                                   // set motor pulse to low
    __delay_us(10);                                                            // set duration of pulse low
    MCLK = 1;                                                                   // set motor pulse to high
    __delay_us(570);                                                            // set duration of pulse high
    }
count = 0;
MEN = 0;
input = 7;
}
/**************************** FUNCTION ****************************************/
/*******************************test ******************************************/
/******************************************************************************/
void test(void)
{
Lcd_Clear();
    while(BACK !=0)
    {
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String(" TESTING MOTOR  ");                                       // write text to line 1
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String("            BACK");                                                 // write text to line 1
    MCW = 1;                                                                    // SET MOTOR TO CLOCKWISE 
    MEN = 1;                                                                    // ENABLE MOTOR
        while(BACK != 0 && OPEN != 0)                                           // until select button is pressed stay in function "EMPTY FILL"
            {           
            MCLK = 0;                                                           // SET PULSE TO LOW
            __delay_us(10);                                                    // SET DURATION OF OFF PERIOD       
            MCLK = 1;                                                           // SET PULSE TO HIGH
            __delay_us(570);                                                    // SET DURATION OF ON PERIOD        
            }       
        MEN = 0;                                                                // DISABLE MOTOR
                        
        MCW = 0;                                                                // SET MOTOR TO ANTI-CLOCKWISE 
        MEN = 1;                                                                // ENABLE MOTOR
        while(BACK != 0 && CLOSED != 0)                                         // until select button is pressed stay in function "EMPTY FILL"
            {           
            MCLK = 0;                                                           // SET PULSE TO LOW
            __delay_us(10);                                                    // SET DURATION OF OFF PERIOD
            MCLK = 1;                                                           // SET PULSE TO HIGH
            __delay_us(570);                                                    // SET DURATION OF ON PERIOD
            }
        MEN = 0;                                                                // DISABLE MOTOR           
    }
}
/**************************** FUNCTION ****************************************/
/***************************** SETUP ******************************************/
/******************************************************************************/
void setup(void)
{
Lcd_Clear();    
Lcd_Set_Cursor(1,1);                                                            // set LCD cursor on line 1 position 1
Lcd_Write_String("      MENU       ");                                           // write text to line 1 
Lcd_Set_Cursor(2,1);                                                            // set LCD cursor on line 2 position 1
Lcd_Write_String("SET  MT  HM BACK");                                           // write text to line 2
delay2();
while(BACK != 0)                                                                // until BACK/RED button is pressed run program
    {       
    if(SEL == 0)            
        home();       
    if(INC == 0)
        menu0();
    if(DEC == 0)
        test();
    }
Lcd_Clear();        
}
/**************************** FUNCTION ****************************************/
/********************************000 ******************************************/
/******************************************************************************/
void position0(void)
{
while(input != 0)                                                                // until BACK/RED button is pressed run program
    {
    Lcd_Clear();
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String("   POSITION 0   ");                                        // write text to line 1 
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("     RUNNING    ");                                        // write text to line 2        
    if(pos0 > count)
        {
        pos0temp = pos0 - count;
        MCW = 1;
        count = count + pos0temp;
        }
    else if(count > pos0)
        {
        pos0temp = count - pos0;
        MCW = 0;
        count = count - pos0temp;
        }
    MEN = 1;
    while(pos0temp != 0)                                                        // new position in mm
        {
        multiplier = 2;
        while(multiplier != 0)           
            { 
            clock = 67;
            while(clock != 0)           
                {
                MCLK = 0;                                                                   // set motor pulse to low
                __delay_us(10);                                                            // set duration of pulse low
                MCLK = 1;                                                                   // set motor pulse to high
                __delay_us(570);
                clock = clock -1;
                }
            multiplier = multiplier -1;
            }       
        pos0temp = pos0temp -1;                                              // DECREMENT STEPSTEMP UNTIL 1Ulitre IS DISPENSED            
        }
    MEN = 0;
    input = 0;
    }
}
/**************************** FUNCTION ****************************************/
/********************************001 ******************************************/
/******************************************************************************/
void position1(void)
{
while(input != 1)                                                            // until BACK/RED button is pressed run program
    {
    Lcd_Clear();
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String("   POSITION 1   ");                                       // write text to line 1 
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("     RUNNING    ");                                       // write text to line 2   
    if(pos1 > count)
        {
        pos1temp = pos1 - count;
        MCW = 1;
        count = count + pos1temp;
        }
    else if(count > pos1)
        {
        pos1temp = count - pos1;
        MCW = 0;
        count = count - pos1temp;
        }       
    MEN = 1;
    while(pos1temp != 0)                                                        // new position in mm
        {
        multiplier = 2;
        while(multiplier != 0)           
            { 
            clock = 67;
            while(clock != 0)           
                {
                MCLK = 0;                                                                   // set motor pulse to low
                __delay_us(10);                                                            // set duration of pulse low
                MCLK = 1;                                                                   // set motor pulse to high
                __delay_us(570);
                clock = clock -1;
                }
            multiplier = multiplier -1;
            }       
        pos1temp = pos1temp -1;                                              // DECREMENT STEPSTEMP UNTIL 1Ulitre IS DISPENSED            
        }
    MEN = 0;
    input = 1;
    }
}
/**************************** FUNCTION ****************************************/
/********************************002 ******************************************/
/******************************************************************************/
void position2(void)
{
while(input != 2)                                                                // until BACK/RED button is pressed run program
    {
    Lcd_Clear();
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String("   POSITION 2   ");                                        // write text to line 1 
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("     RUNNING    ");                                        // write text to line 2        
    if(pos2 > count)
        {
        pos2temp = pos2 - count;
        MCW = 1;
        count = count + pos2temp;
        }
    else if(count > pos2)
        {
        pos2temp = count - pos2;
        MCW = 0;
        count = count - pos2temp;
        }
    MEN = 1;
    while(pos2temp != 0)                                                        // new position in mm
        {
        multiplier = 2;
        while(multiplier != 0)           
            { 
            clock = 67;
            while(clock != 0)           
                {
                MCLK = 0;                                                                   // set motor pulse to low
                __delay_us(10);                                                            // set duration of pulse low
                MCLK = 1;                                                                   // set motor pulse to high
                __delay_us(570);
                clock = clock -1;
                }
            multiplier = multiplier -1;
            }       
        pos2temp = pos2temp -1;                                              // DECREMENT STEPSTEMP UNTIL 1Ulitre IS DISPENSED            
        }
    MEN = 0;
    input = 2;
    }
}
/**************************** FUNCTION ****************************************/
/********************************003 ******************************************/
/******************************************************************************/
void position3(void)
{    
    while(input != 3)                                                                // until BACK/RED button is pressed run program
    {
    Lcd_Clear();
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String("   POSITION 3   ");                                        // write text to line 1 
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("     RUNNING    ");                                        // write text to line 2        
    if(pos3 > count)
        {
        pos3temp = pos3 - count;
        MCW = 1;
        count = count + pos3temp;
        }
    else if(count > pos3)
        {
        pos3temp = count - pos3;
        MCW = 0;
        count = count - pos3temp;
        }
    MEN = 1;
    while(pos3temp != 0)                                                        // new position in mm
        {
        multiplier = 2;
        while(multiplier != 0)           
            { 
            clock = 67;
            while(clock != 0)           
                {
                MCLK = 0;                                                                   // set motor pulse to low
                __delay_us(10);                                                            // set duration of pulse low
                MCLK = 1;                                                                   // set motor pulse to high
                __delay_us(570);
                clock = clock -1;
                }
            multiplier = multiplier -1;
            }       
        pos3temp = pos3temp -1;                                              // DECREMENT STEPSTEMP UNTIL 1Ulitre IS DISPENSED            
        }
    MEN = 0;
    input = 3;
    }
}
/**************************** FUNCTION ****************************************/
/********************************004 ******************************************/
/******************************************************************************/
void position4(void)
{
while(input != 4)                                                                // until BACK/RED button is pressed run program
    {
    Lcd_Clear();
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String("   POSITION 4   ");                                        // write text to line 1 
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("     RUNNING    ");                                        // write text to line 2        
    if(pos4 > count)
        {
        pos4temp = pos4 - count;
        MCW = 1;
        count = count + pos4temp;
        }
    else if(count > pos4)
        {
        pos4temp = count - pos4;
        MCW = 0;
        count = count - pos4temp;
        }
    MEN = 1;
    while(pos4temp != 0)                                                        // new position in mm
        {
        multiplier = 2;
        while(multiplier != 0)           
            { 
            clock = 67;
            while(clock != 0)           
                {
                MCLK = 0;                                                                   // set motor pulse to low
                __delay_us(10);                                                            // set duration of pulse low
                MCLK = 1;                                                                   // set motor pulse to high
                __delay_us(570);
                clock = clock -1;
                }
            multiplier = multiplier -1;
            }       
        pos4temp = pos4temp -1;                                              // DECREMENT STEPSTEMP UNTIL 1Ulitre IS DISPENSED            
        }
    MEN = 0;
    input = 4;
    }
}
/**************************** FUNCTION ****************************************/
/********************************005 ******************************************/
/******************************************************************************/
void position5(void)
{
while(input != 5)                                                                // until BACK/RED button is pressed run program
    {
    Lcd_Clear();
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String("   POSITION 5   ");                                        // write text to line 1 
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("     RUNNING    ");                                        // write text to line 2        
    if(pos5 > count)
        {
        pos5temp = pos5 - count;
        MCW = 1;
        count = count + pos5temp;
        }
    else if(count > pos5)
        {
        pos5temp = count - pos5;
        MCW = 0;
        count = count - pos5temp;
        }
    MEN = 1;
    while(pos5temp != 0)                                                        // new position in mm
        {
        multiplier = 2;
        while(multiplier != 0)           
            { 
            clock = 67;
            while(clock != 0)           
                {
                MCLK = 0;                                                                   // set motor pulse to low
                __delay_us(10);                                                            // set duration of pulse low
                MCLK = 1;                                                                   // set motor pulse to high
                __delay_us(570);
                clock = clock -1;
                }
            multiplier = multiplier -1;
            }       
        pos5temp = pos5temp -1;                                              // DECREMENT STEPSTEMP UNTIL 1Ulitre IS DISPENSED            
        }
    MEN = 0;
    input = 5;
    }
}
/**************************** FUNCTION ****************************************/
/********************************006 ******************************************/
/******************************************************************************/
void position6(void)
{
while(input != 6)                                                                // until BACK/RED button is pressed run program
    {
    Lcd_Clear();
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String("   POSITION 6   ");                                        // write text to line 1 
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("     RUNNING    ");                                        // write text to line 2        
    if(pos6 > count)
        {
        pos6temp = pos6 - count;
        MCW = 1;
        count = count + pos6temp;
        }
    else if(count > pos6)
        {
        pos6temp = count - pos6;
        MCW = 0;
        count = count - pos6temp;
        }
    MEN = 1;
    while(pos6temp != 0)                                                        // new position in mm
        {
        multiplier = 2;
        while(multiplier != 0)           
            { 
            clock = 67;
            while(clock != 0)           
                {
                MCLK = 0;                                                                   // set motor pulse to low
                __delay_us(10);                                                            // set duration of pulse low
                MCLK = 1;                                                                   // set motor pulse to high
                __delay_us(570);
                clock = clock -1;
                }
            multiplier = multiplier -1;
            }       
        pos6temp = pos6temp -1;                                              // DECREMENT STEPSTEMP UNTIL 1Ulitre IS DISPENSED            
        }
    MEN = 0;
    input = 6;
    }
}
/**************************** FUNCTION ****************************************/
/**************************** fake move ***************************************/
/******************************************************************************/
void fakemove(void)
{
    Lcd_Clear();
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String("   FAKE MOVE   ");                                        // write text to line 1 
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String("     RUNNING    ");                                        // write text to line 2        
    faketemp = fake;
    MCW = 1;        
    MEN = 1;
    while(faketemp != 0)                                                        // new position in mm
        {
        multiplier = 2;
        while(multiplier != 0)           
            { 
            clock = 67;
            while(clock != 0)           
                {
                MCLK = 0;                                                       // set motor pulse to low
                __delay_us(10);                                                 // set duration of pulse low
                MCLK = 1;                                                       // set motor pulse to high
                __delay_us(570);
                clock = clock -1;
                }
            multiplier = multiplier -1;
            }       
        faketemp = faketemp -1;                                                          
        }
    MEN = 0;
    
    __delay_ms(50);
    
    faketemp = fake;
    MCW = 0;        
    MEN = 1;
    while(faketemp != 0)                                                        
        {
        multiplier = 2;
        while(multiplier != 0)           
            { 
            clock = 67;
            while(clock != 0)           
                {
                MCLK = 0;                                                       // set motor pulse to low
                __delay_us(10);                                                 // set duration of pulse low
                MCLK = 1;                                                       // set motor pulse to high
                __delay_us(570);
                clock = clock -1;
                }
            multiplier = multiplier -1;
            }       
        faketemp = faketemp -1;                                                          
        }
    MEN = 0;    
}
/******************** MAIN PROGRAM STARTS RUNNING HERE ************************/
/******************************************************************************/
void main(void)                                                                 // start of main program
{ 
SYSTEM_Initialize();                                                            // Initialize the device 
MH = 1;                                                                         // SET MOTOR TO HALF STEP MODE
eepromload();
/***************************** STARTUP RUN ONCE *******************************/
/******************************** LCD INTRO ***********************************/
/******************************************************************************/   
Lcd_Init();                                                                     // initialise the LCD
Lcd_Clear();                                                                    // clear LCD
Lcd_Set_Cursor(1,1);                                                            // set LCD cursor on line 1 position 1
Lcd_Write_String("  Sliding Door  ");                                           // write text to line 1
Lcd_Set_Cursor(2,1);                                                            // set LCD cursor on line 2 position 1
Lcd_Write_String(" L.Embray 2021  ");                                           // write text to line 2
home();
if (pos0 > 55)
    pos0 = 55;
if (pos1 > 55)
    pos1 = 55;
if (pos2 > 55)
    pos2 = 55;
if (pos3 > 55)
    pos3 = 55;
if (pos4 > 55)
    pos4 = 55;
if (pos5 > 55)
    pos5 = 55;
if (pos6 > 55)
    pos6 = 55;
if (pos7 > 55)
    pos7 = 55;
fake = 5;
count = 0;
Lcd_Clear();
/******************************************************************************/
/**************************** MAIN PROGRAM ************************************/
/******************************************************************************/ 
while (1)   
    {
    Lcd_Set_Cursor(1,1);                                                        // set LCD cursor on line 1 position 1
    Lcd_Write_String("****RUNNING****");                                        // write text to line 1 
    Lcd_Set_Cursor(2,1);                                                        // set LCD cursor on line 2 position 1
    Lcd_Write_String(" BLUE = SETUP  ");                                        // write text to line 2
    __delay_ms(150);
    if(BACK == 0)                                                               // until BACK/BLUE button is pressed run program
        setup();          
        if(B2 == 0 && B1 == 0 && B0 == 0)            
            position0();
    __delay_ms(2);
        if(B2 == 0 && B1 == 0 && B0 == 1)            
            position1();
    __delay_ms(2);
        if(B2 == 0 && B1 == 1 && B0 == 0)            
            position2();
    __delay_ms(2);
        if(B2 == 0 && B1 == 1 && B0 == 1)            
            fakemove();
    __delay_ms(2);
        if(B2 == 1 && B1 == 0 && B0 == 0)            
            position4();
    __delay_ms(2);
        if(B2 == 1 && B1 == 0 && B0 == 1)            
            position5();
    __delay_ms(2);
        if(B2 == 1 && B1 == 1 && B0 == 0)            
            position6();
    __delay_ms(2);
        if(B2 == 1 && B1 == 1 && B0 == 1)            
            home();
    __delay_ms(2);
    }
}




