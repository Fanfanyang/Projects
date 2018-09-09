
// This is the code for rotating POV display

#include <stdio.h>

#include <stdlib.h>

#include <inttypes.h>

#include <avr/io.h>

#include <avr/interrupt.h> 

#define F_CPU 16000000UL 

// the usual

#define begin {

#define end } 

volatile int motor_period, motor_period_ovlf;   // motor periods needed for rps calculation

volatile float rps;   // rps measurement

volatile int ledPos;           

volatile long eight[100];

volatile long yes[100];

volatile long no[100];

int i;

volatile long count=0;

volatile int time1;

volatile char display=2;

volatile char disp; 

void init(void) ;

//*************************************************************

// --- external interrupt ISR ------------------------

ISR (INT1_vect) 

begin

  //calculate motor speed

  if(PIND & 0x04) // voice, display 8

  begin

    //PORTC = 0x3f;

                display = 0; // display 8

                disp = rand()%2;// disp = 0, display yes; disp = 1, display no

  end

  else if(~PIND & 0x04)

  begin

              display = 1; // display random number

 end

  motor_period = TCNT2 + motor_period_ovlf  ;

  TCNT2 = 0 ;

  motor_period_ovlf = 0 ;              

  ledPos = 0;

  OCR0A = motor_period/45; 

end 

//************************************************************

// --- set up timer 0 for time base----------------

ISR (TIMER0_COMPA_vect)

begin

  if(ledPos < 90)

                ledPos++; 

                //voice exist, display 8

  if( display == 0 )

  begin

                if(ledPos > 33 && ledPos <= 65)

                begin

                  PORTB = ~(eight[ledPos-33] & 0x07);

                  PORTA = ~(eight[ledPos-33]>>3);

                  PORTC = ~(eight[ledPos-33]>>11);       

                end

                else

                begin

                  // leds off

                  PORTB = 0xff;

                  PORTA = 0xff;

                  PORTC = 0xff;

                end

  end      

  else if( display == 1 )// no voice, display random answer

  begin

    //disp = rand()%2; // disp = 0, display yes; disp = 1, display no

                if(disp==0) //display yes

                begin

                  if(ledPos > 20 && ledPos <= 88)

                  begin

                    PORTB = ~(yes[ledPos-20] & 0x07) ;

                    PORTA = ~(yes[ledPos-20]>>3);

                    PORTC = ~(yes[ledPos-20]>>11);

                  end

                  else

                  begin

                    PORTB = 0xff;

                    PORTA = 0xff;

                    PORTC = 0xff;

                  end

                end

                else if(disp==1) //display no

                begin

                  if(ledPos >27 && ledPos <= 75)

                  begin

                    PORTB = ~(no[ledPos-27] & 0x07);

                    PORTA = ~(no[ledPos-27]>>3);

                    PORTC = ~(no[ledPos-27]>>11);

                  end

                  else

                  begin

                    PORTB = 0xff;

                    PORTA = 0xff;

                    PORTC = 0xff;

                  end

                end

  end

  /*else if(display == 1)

  begin

    PORTB = 0xff;

     PORTA = 0xff;

                    PORTC = 0xff;

  end*/

end

//************************************************************

// --- set up extra 8 bits on timer 2 ----------------

ISR (TIMER2_OVF_vect) 

begin

  motor_period_ovlf = motor_period_ovlf + 256 ;

end

 

//***************************************************************

// --- Execute speed measurement loop ----------------------------------

void task1(void)

begin

  if(motor_period != 0)

  begin

                //spr = 0.000064*motor_period;               //calculate current rps

    TIMSK0 = 2; // turn on timer 0 compare match interrupt

                //OCR0A = spr*1000000/(180*4);

                OCR0A = motor_period/45;

  end

  else

  begin

                rps = 0;

                TIMSK0 = 0;

  end 

end

 

 

// --- Main Program ----------------------------------

int main(void) 

begin

  init();

  while(1);

 end // main

 

//***************************************************************

// --- Initialize Timer for INT0 ----------------------------------

void init(void) 

begin

  EIMSK = (1<<INT1); // turn on int1

  EICRA = 0x08;       // falling edge for INT1; 

  // turn on timer 2 to be read in int0 ISR

  TCCR2B = 7; // divide by 1024

  // turn on timer 2 overflow ISR for double precision time

  TIMSK2 = 1; 

  TIMSK0 = 2; 

  TCCR0A = 2; // timer0 turn on compare match mode

  TCCR0B = 4; // timer0 clk divided by 256; 

  time1 = 1;

  sei(); 

  //initialize led matrix 

  ledPos = 0; 

  //initialize eight 

  for (i=0;i<32;i++)

  begin

 

                if(i>=0 && i<4)

                  eight[i] = 0b0000000000001110000;

    if(i>=4 && i<8)

                  eight[i] = 0b0000111000011011000;

                if(i>=8 && i<12)

                  eight[i] = 0b0001101100110001100;

                if(i>=12 && i<16)

                  eight[i] = 0b0011000011100000110;

                if(i>=16 && i<20)

                  eight[i] = 0b0011000011100000110;

                if(i>=20 && i<24)

                  eight[i] = 0b0001101100110001100;

                if(i>=24 && i<28)

                  eight[i] = 0b0000111000011011000;

                if(i>=28 && i<32)

                  eight[i] = 0b0000000000001110000;

 

                /*if (i >= 0 && i < 10)

                  eight[i] = 0b0011111111111111100;

                  

                

                  if (i >= 10 && i < 30)

                  eight[i] = 0b0011000011000001100;

 

                if (i >= 30 && i < 40)

                  eight[i] = 0b0011111111111111100;*/

  end 

  for(i=0;i<68;i++)

  begin

    // display Y

                if(i>=0 && i<2)

                  yes[i] = 0b0001100000000000000;

                if(i>=2 && i<4)

                  yes[i] = 0b0000110000000000000;

                if(i>=4 && i<6)

                  yes[i] = 0b0000011000000000000;

                if(i>=6 && i<8)

                  yes[i] = 0b0000001100000000000;

    if(i>=8 && i<10)

                  yes[i] = 0b0000000011111111100;

                if(i>=10 && i<12)

                  yes[i] = 0b0000001100000000000;

                if(i>=12 && i<14)

                  yes[i] = 0b0000011000000000000;

                if(i>=14 && i<16)

                  yes[i] = 0b0000110000000000000;

                if(i>=16 && i<18)

                  yes[i] = 0b0001100000000000000; 

    // display space

    if(i>=18 && i<22)

                  yes[i] = 0b0000000000000000000;

                // display E

                if(i>=22 && i<24)

                  yes[i] = 0b0001111111111111000;

    if(i>=24 && i<40)

                  yes[i] = 0b0001100011000011000; 

    // display space

    if(i>=40 && i<44)

                  yes[i] = 0b0000000000000000000; 

                // display S

    if(i>=44 && i<47)

                  yes[i] = 0b0000111000000110000;//0b0000000000001110000

    if(i>=47 && i<50)

                  yes[i] = 0b0001101100000011000;//0b0000000000011011000

                if(i>=50 && i<53)

                  yes[i] = 0b0011000110000001100;//0b0000000000110001100

                if(i>=53 && i<56)

                  yes[i] = 0b0010000011000000100;//0b0000000001100000110

                if(i>=56 && i<59)

                  yes[i] = 0b0010000001100000100;//0b0110000011000000000

                if(i>=59 && i<62)

                  yes[i] = 0b0011000000110001100;//0b0011000110000000000

                if(i>=62 && i<65)

                  yes[i] = 0b0001100000011011000;//0b0001101100000000000

                if(i>=65 && i<68)

                  yes[i] = 0b0000110000001110000;//0b0000111000000000000

  end 

  for(i=0;i<48;i++)

  begin

    if(i>=0 && i<3)

                  no[i] = 0b0000011111111000000;

                if(i>=3 && i<6)

                  no[i] = 0b0000001100000000000;

                if(i>=6 && i<9)

                  no[i] = 0b0000000110000000000;

                if(i>=9 && i<12)

                  no[i] = 0b0000000011000000000;

                if(i>=12 && i<15)

                  no[i] = 0b0000000001100000000;

                if(i>=15 && i<18)

                  no[i] = 0b0000000000110000000;

    if(i>=18 && i<21)

                  no[i] = 0b0000011111111000000; 

                if(i>=21 && i<24)

      no[i] = 0b0000000000000000000; 

                if(i>=24 && i<27)

                  no[i] = 0b0000000011100000000;

    if(i>=27 && i<30)

                  no[i] = 0b000000011011000000;

                if(i>=30 && i<33)

                  no[i] = 0b0000001100011000000;

                if(i>=33 && i<36)

                  no[i] = 0b0000011000001100000;

                if(i>=36 && i<39)

                  no[i] = 0b0000011000001100000;

                if(i>=39 && i<42)

                  no[i] = 0b0000001100011000000;

                if(i>=42 && i<45)

                  no[i] = 0b000000011011000000;

                if(i>=45 && i<48)

                  no[i] = 0b0000000011100000000;

  end 

  // Set portA portB portC to output

                DDRA = 0xff;

                DDRB = 0xff;

                DDRC = 0xff;

  // lit all the led

                PORTA = 0xff;

                PORTB = 0xff;

                PORTC = 0x7f; 

                //initialize motor period calculation

                motor_period = 0;

                motor_period_ovlf = 0;

 

  /*

  // start TRT

  trtInitKernel(300); // 80 bytes for the idle task stack

 

  // --- creat tasks  ----------------

  trtCreateTask(task1, 200, SECONDS2TICKS(0.8), SECONDS2TICKS(0.13), &(args[0]));

  trtCreateTask(task2, 200, SECONDS2TICKS(0.5), SECONDS2TICKS(0.1), &(args[1]));

  //trtCreareTask(task3, 200, SECONDS2TICKS(0.5), SECONDS2TICKS(0.08), &(args[2]));*/

 

end

 

//***************************************************************

 

 
 