#include <avr/io.h>
#include <avr/interrupt.h>

// Array to hold 8 raw bytes (4 channels x 2 bytes per 10-bit value)
volatile uint8_t adc_buffer[8] = {0};
volatile uint8_t tx_index = 0;

// Initialize USI in SPI Slave Mode
void spi_slave_init(void) {
  // Set DO (PA5 / MISO) as output
  DDRA |= (1 << DDA5);
  
  // Set USCK (PA4 / SCK) and DI (PA6 / MOSI) as inputs
  DDRA &= ~((1 << DDA4) | (1 << DDA6));
  
  // Configure Chip Select (PB2 / CS) as input with pull-up resistor
  DDRB  &= ~(1 << DDB2);
  PORTB |=  (1 << PINB2);

  /* USICR - USI Control Register Setup:
   * USISIE = 1 : Enable USI Start Condition Interrupt
   * USIOIE = 1 : Enable USI Counter Overflow Interrupt
   * USIWM0 = 1, USIWM1 = 0 : Three-wire mode (SPI)
   * USICS1 = 1, USICS0 = 0, USICLK = 0 : External, positive edge clock source
   */
  USICR = (1 << USIOIE) | (1 << USIWM0) | (1 << USICS1);
  
  // Clear USI counter overflow flag
  USISR = (1 << USIOIF);
}

// Read a specified ADC channel (10-bit, 0 to 1023)
uint16_t read_adc(uint8_t channel) {
  // Select ADC channel (MUX bits 0 to 3)
  ADMUX = (ADMUX & 0xF0) | (channel & 0x0F);
  
  // Start ADC Conversion
  ADCSRA |= (1 << ADSC);
  
  // Wait for conversion to complete
  while (ADCSRA & (1 << ADSC));
  
  return ADC;
}

int main(void) {
  // Setup ADC: Enable, Prescaler = 64 (125 kHz ADC clock @ 8 MHz CPU)
  ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1);
  
  spi_slave_init();
  
  // Enable Global Interrupts
  sei();

  while (1) {
    // Continuously poll all 4 potentiometers into the byte array
    for (uint8_t i = 0; i < 4; i++) {
      uint16_t val = read_adc(i);
      
      // Store as High Byte followed by Low Byte
      adc_buffer[i * 2]     = (uint8_t)(val >> 8);   // Upper 2 bits
      adc_buffer[(i * 2) + 1] = (uint8_t)(val & 0xFF); // Lower 8 bits
    }
  }
}

/* 
 * USI Counter Overflow Interrupt
 * Triggered automatically every 8 clock pulses (1 byte transferred) on USCK
 */
ISR(USI_OVF_vect) {
  // Load the next byte into the Data Register for the next transfer
  USIDR = adc_buffer[tx_index];
  
  // Increment index across 8 bytes
  tx_index = (tx_index + 1) % 8;

  // Clear USI overflow flag to prepare for next byte
  USISR = (1 << USIOIF);
}