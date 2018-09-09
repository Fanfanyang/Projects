
// This is the code for stepper motor control and voice command generation

#define F_CPU 16000000UL

#include <inttypes.h>

#include <avr/io.h>

#include <avr/interrupt.h>

#include <stdio.h>

#include <util/delay.h> 

#define begin {

#define end } 

volatile uint16_t Count;

volatile char V_sample;

//volatile char V_sample_pre;

volatile char Vmax, Vmin;

volatile uint32_t Sample_Count;

volatile char voice_maybe;

volatile int Motor_Period;

volatile int ramp_factor;

volatile int flag=0; 

void MotorCtrl(void); 

//timer 0 compare match ISR

ISR(TIMER0_COMPA_vect) 

begin   

  Count++;

  MotorCtrl();

  //Motor_Period --;

end 

// ADC interrupt

ISR(ADC_vect)

begin

  V_sample = ADCH;

  Sample_Count++; 

    //PORTC ^= 0x40;

  if(Sample_Count == 3840)

  begin

    PORTC ^= 0x40;

    Sample_Count = 0;

                if(~PINC & 0x20)

                begin

      PORTC &= 0xef; // switch off, set C4 to low

                end

                else if((PINC&0x20) && ((Vmax-Vmin)>80))

                begin

                  voice_maybe = 1;

                  PORTC &= 0xef; // voice, set C4 to low

                end

                else if(((Vmax-Vmin)<=80) && (PINC&0x20) )

                begin

                  voice_maybe = 0;

                  PORTC |= 0x10; // no voice, set C4 to high

                end

                Vmax = 0;

                Vmin = 255;

  end

  if(V_sample >= Vmax)

    Vmax = V_sample;

  if(V_sample <= Vmin)

    Vmin = V_sample;

  //V_sample_pre = V_sample;

  ADCSRA |= (1<<ADSC);

end 

//-----------------------

// Motor Control Routine

//-----------------------

void MotorCtrl(void)

begin 

    if(Count == 0)

 begin

      PORTC |= 0x09;           // Set c0 c3 high

      PORTC &= 0xf9;          // Set c1 c2 low 

 end

 else if(Count == (1*ramp_factor))

  begin

      PORTC |= 0x03;           // Set c0 c1 high

      PORTC &= 0xf3;          // Set c2 c3 low

  end

  else if(Count == (2*ramp_factor))

  begin

      PORTC |= 0x06;           // Set c1 c2 high

      PORTC &= 0xf6;          // Set c3 c4 low

  end

  else if(Count == (3*ramp_factor))

  begin

      PORTC |= 0x0c;           // Set c2 c3 high

      PORTC &= 0xfc;           // Set c0 c1 low

  end

 else if(Count == (4*ramp_factor))

 begin

    Count = -1;

    if(ramp_factor>43)

    begin

        if(flag==0)

        begin

           ramp_factor--;

           if(ramp_factor<90 && ramp_factor>=80)

                     flag=100;

          else if(ramp_factor<80 && ramp_factor>=70)

                     flag = 150;

          else if(ramp_factor<70 && ramp_factor>=60)

                    flag = 200;

          else if(ramp_factor<60 && ramp_factor>=50)

                   flag = 400;

          else if(ramp_factor<50 && ramp_factor>43)

                  flag = 700;

          else

                 flag=80;

       end

       

       else flag--;

    end

    end

end 

//---------------------

// Initial Subroutine

//---------------------

void init(void)

begin 

  //set up timer 0 for mSec timebase 

  TIMSK0= (1<<OCIE0A); //turn on timer 0 cmp match ISR 

  TCCR0A= (1<<WGM01); // turn on clear-on-match

  OCR0A = 38;       //set the compare re to 150 time ticks

  TCCR0B= 2;        //set prescaler to divide by 64 

  DDRC = 0x5f;    // Init port C as output 

  PORTC = 0x00; 

  // set initial value to variables

  //V_sample_pre = 0;

  Count = -1;

  Vmax = 0;

  Vmin = 255;

  Sample_Count = 0;

  voice_maybe = 0; 

  ramp_factor = 100; 

  //set AD converter

  ADMUX = (1<<ADLAR)|(1<<REFS0);

  ADCSRA = (1<<ADEN)|(1<<ADSC)+(1<<ADIE)+7;

  sei() ;

end 

int main(void)

begin

  init();

  while(1);

end

 

 
 