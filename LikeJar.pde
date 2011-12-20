#include <avr/eeprom.h>

// Like button by Herman Kopinga herman@kopinga.nl
// Works together with a homebrew Arduino on an Atmega8
// Soldered on a perfboard with a Kingbright 3 digit 7 segment common cathode LED module.

// Version history:
// 0.9: Beta version removed test code & redundant variables and improved documentation.

// Software based on:
// Arduino 7 segment display example software
// http://www.hacktronics.com/Tutorials/arduino-and-7-segment-led.html
 
// License: none whatsoever.
 
// Global variables

// for 3 digit display in the 'like jar'
//  555     111
// 6   7   2   3
// 6   7   2   3
//  A11     444
// A   A   7   5
// 5   2   7   5
//  A44 A3  666 8
byte sevenSegDigits[11][7] =   { { 1,1,1,0,1,1,1 },  // = 0
                                 { 0,0,1,0,1,0,0 },  // = 1
                                 { 1,0,1,1,0,1,1 },  // = 2
                                 { 1,0,1,1,1,1,0 },  // = 3
                                 { 0,1,1,1,1,0,0 },  // = 4
                                 { 1,1,0,1,1,1,0 },  // = 5
                                 { 1,1,0,1,1,1,1 },  // = 6
                                 { 1,0,1,0,1,0,0 },  // = 7
                                 { 1,1,1,1,1,1,1 },  // = 8
                                 { 1,1,1,1,1,1,0 },  // = 9
                                 { 0,0,0,0,0,0,0 }   // = space
                                 };
                                 
byte sevenSegPins[8] = {5,6,7,A1,A2,A4,A5,A3};
          
long ticks = 0;
byte reset = 60;
byte divide = 20;
int likes;                    // The number of button presses.
int num;
int value;                    // The number displayed on the LEDs.
int n = 0;
int buttonState = 0;          // Current state of the button.
int lastButtonState = 0;      // Previous state of the button.
long coolDownTicks = 0;       // Hold delay before a new button press is registered.
                                 
void setup()
{
  //Set all the LED pins as output.
  for (byte pinCount = 0; pinCount < 9; pinCount++)
  {
     pinMode(sevenSegPins[pinCount], OUTPUT);
  }

  pinMode(2, OUTPUT);    // Cathode
  pinMode(3, OUTPUT);    // Cathode
  pinMode(4, OUTPUT);    // Cathode
  
  digitalWrite(2, 0);   // Select one of the digits.
  writeDot(0);          // start with the "dot" off

  // Read the number of Likes from last run.
  eeprom_read_block((void*)&likes, (void*)0, sizeof(likes));
}

void writeDot(byte dot) 
{
  digitalWrite(A3, dot);
}

// Function that writes the passed digit to the output pins. 
// Depending on which cathode is grounded another digit is lit.
void sevenSegWrite(byte digit, byte dot) 
{
  for (byte loopCount = 0; loopCount < 8; ++loopCount) {
    digitalWrite(sevenSegPins[loopCount], sevenSegDigits[digit][loopCount]);
  }
  writeDot(dot);
}

void loop()
{
  // Always increase the ticks counter.
  ticks++;
  
  // Decrease the cooldown if it is currently running.
  if (coolDownTicks > 0)
  {
    coolDownTicks--;
  }
  else
  {
    ////////////// 
    //Manage the button.
    
    // Read current button state.
    buttonState = digitalRead(A0);
  
    // compare the buttonState to its previous state
    if (buttonState != lastButtonState) {
      if (buttonState == HIGH) {
        // if the current state is HIGH then the button
        // went from off to on:
        if (coolDownTicks == 0)
        {
          // Check if we're upside down.
 /*         if (digitalRead(9))
          {*/
            // Normal operation, increment the counter.
            likes++; 
            coolDownTicks = 12000;
            eeprom_write_block((const void*)&likes, (void*)0, sizeof(likes));
/*          }
          else
          {
            // Whoei! I'm flying! Upside down mode.
            // Longer cooldown and count backwards.
            likes--; 
            coolDownTicks = 65000;
            eeprom_write_block((const void*)&likes, (void*)0, sizeof(likes));
          }*/
        }
      }
    }
    // save the current state as the last state, 
    // for next time through the loop
    lastButtonState = buttonState;
  }
  
  ////////////// 
  // (Re)Write the digits

  // Write a digit at a time for 20 ticks.
  n = ticks/divide;
  
  // Most significant digit
  if(n == 0)
  {
    digitalWrite(2,0);
    digitalWrite(3,1);
    digitalWrite(4,1);
    sevenSegWrite(value % 1000 / 100, 0);
  }

  // Middle significant digit  
  if(n == 1)
  {
    digitalWrite(2,1);
    digitalWrite(3,0);
    digitalWrite(4,1);
    sevenSegWrite(value % 100 / 10, 0);
  }

  // Least significant digit  
  if(n == 2)
  {
    digitalWrite(2,1);
    digitalWrite(3,1);
    digitalWrite(4,0);
    if (coolDownTicks > 0)
    {
      sevenSegWrite(value % 10, 1);
    }
    else
    {
      sevenSegWrite(value % 10, 0);
    }
  } 
  
  // Ticks won't be bigger than reset (60).
  if(ticks > reset) 
  {
    ticks = 0;
    num++;
  }
  
  // Every 600 loops the value we work with is updated.
  if(num > 10)
  {
    num = 0;
    value = likes;
  }
}
