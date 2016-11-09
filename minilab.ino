
#include "types.h"
#include "proto.h"

u8 serial_buffer[100], serial_buffer_length = 0;


void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
  // put your main code here, to run repeatedly:
  u8 i;
  i8 status;
  static bool led_status = true;

  status = proto_try_read_request( serial_buffer, &serial_buffer_length, sizeof serial_buffer );
  
  if ( status < 0 )
  {
    proto_send_error_reply(0);
  }
  else if ( status == 1 )
  {
    digitalWrite ( LED_BUILTIN, led_status );
    led_status = !led_status;

    service_request ( serial_buffer, serial_buffer_length );
  }
}


/*
  sends error code
    0 => framing error (checksum error, etc.)
    1 => unknown command
    2 => 
*/
void service_request ( Byte *buffer, u8 length )
{
  Char out_buffer[100];
  u8 error_code = 0, out_length = 0, command;

  // shift out command
  command = *buffer++;
  length--;

  // service command
  switch ( command ) 
  {
    default: error_code = 0xFF; break; // command unknown
    case 1: error_code = service_digital_input  ( buffer, length, out_buffer + 1, &out_length ); break;
    case 2: error_code = service_digital_output ( buffer, length, out_buffer + 1, &out_length ); break;
    case 3: error_code = service_analog_input   ( buffer, length, out_buffer + 1, &out_length ); break;
    case 4: error_code = service_analog_output  ( buffer, length, out_buffer + 1, &out_length ); break;
  }
  
  if ( error_code )
    proto_send_error_reply(error_code);
  else
  {
    out_buffer[0] = command;
    out_length += 1;
    proto_send_reply( out_buffer, out_length );
  }
}


bool check_digital_pin_number(u8 pin_id)
{
  return pin_id > 21 && pin_id < 54;
}

bool check_analog_pin_number(u8 pin_id)
{
  return pin_id < 14;
}


/* format: <DI><pin-number>
  error codes = {
    1 => "invalid command length"
    2 => "invalid pin number"
  }
*/
u8 service_digital_input (Char* buffer, u8 length, Char *out_buffer, u8 *out_length)
{
  u8 pin_number = buffer[0];

  if ( length != 1 )
    return 1; // invalid command length

  if ( check_digital_pin_number ( pin_number ) ) 
  {
    pinMode ( pin_number, INPUT );
    out_buffer[0] = digitalRead( pin_number );
    *out_length = 1;
    return 0;
  }

  return 2; // invalid pin number
}

/* format: <DO><pin-number><state>
  error codes = {
    1 => "invalid command length"
    2 => "invalid pin number"
    3 => "invalid state"
  }
*/
u8 service_digital_output (Char* buffer, u8 length, Char *out_buffer, u8 *out_length)
{
  u8 pin_number = buffer[0];
  u8 state = buffer[1];

  if ( length != 2 )
    return 1;           // invalid command length

  if ( state > 1 )
    return 3;           // invalid state

  if ( check_digital_pin_number ( pin_number ) ) 
  {
    pinMode      ( pin_number, OUTPUT );
    digitalWrite ( pin_number, state );
    out_buffer[0] = pin_number;
    out_buffer[1] = state;  // echo back the command as result
    *out_length = 2;
    return 0;
  }

  return 2;           // invalid pin number
}

/* format: <AI><pin-number><ref>
    ref = {
      0 => default (5v/3.3v), 
      1 => internal 1.1v
      2 => internal 2.56v
      3 => external Aref pin (0-5v only)
    }
    error codes = {
      1 => "invalid command length"
      2 => "invalid pin number"
      3 => "invalid reference"
    }
*/
u8 service_analog_input (Char *buffer, u8 length, Char *out_buffer, u8 *out_length)
{
  u8 pin_number = buffer[0];
  u8 ref = buffer[1];

  if ( length != 2 )
    return 1;           // invalid command length

  if ( ref > 3 )
    return 3;           // invalid reference

  if ( check_analog_pin_number ( pin_number ) ) 
  {
    u8 ref_codes[] = { DEFAULT, INTERNAL1V1, INTERNAL2V56, EXTERNAL };
    u16 result;

    pinMode         ( pin_number, INPUT );
    analogReference ( ref_codes[ref] );
    result = analogRead ( pin_number );
    out_buffer[0] = pin_number;
    out_buffer[1] = ref;
    out_buffer[2] = (u8)(result & 0xFF);
    out_buffer[3] = (u8)((result >> 8) & 0xFF);
    *out_length = 4;
    return 0;
  }

  return 2;           // invalid pin number
}

/* format: <AO><pin-number><8 bit value>
    error codes = {
      1 => "invalid command length"
      2 => "invalid pin number"
    }
*/
u8 service_analog_output (Char* buffer, u8 length, Char *out_buffer, u8 *out_length)
{
  u8 pin_number = buffer[0];
  u8 value = buffer[1];

  if ( length != 3 )
    return 1;           // invalid command length

  if ( check_analog_pin_number ( pin_number ) ) 
  {
    pinMode     ( pin_number, OUTPUT );
    analogWrite ( pin_number, value );
    out_buffer[0] = pin_number;
    out_buffer[1] = value;
    out_buffer[2] = buffer[2];
    *out_length = 3;
    return 0;
  }
  
  return 2;           // invalid pin number
}



/* proto */

static u8 ascii_to_hex ( Char c )
{
  u8 hex = c - '0';

  if ( hex > 9 )
    hex -= 7;

  return hex;
}

static Byte nibble_to_ascii (Byte hex_value)
{
  Byte temp = hex_value & 0xf;
  
  if (temp > 9)
    temp += 7;

  return temp += '0';
}

static void  hex_to_ascii (u8 value, Byte* buffer)
{
  *buffer++ = nibble_to_ascii ( value >> 4 );
  *buffer++ = nibble_to_ascii ( value );
}


static u8 calculate_lrc ( Byte *buffer, u8 length )
{
  Byte sum, i;

  for ( i = sum = 0; i < length; i++ )
    sum += *buffer++;

  return ~sum + 1;
}

i8 proto_try_read_request ( Byte* buffer, u8 *len, u8 max_size )
{
  static bool byte_complete = false, frame_begun = false, frame_error = false;

  if ( Serial.available() > 0 )
  {
    Char c = Serial.read();
    
    if ( c == ':' )
    {
      *len = 0;
      byte_complete = frame_error = false;
      frame_begun = true;
      return 0;
    }
    else if ( !frame_begun )
      return 0;
    else if ( c == '\n' )
    {
      // request ends
      u8 encoded_lrc, computed_lrc, length = *len;
      frame_begun = false;
      
      if ( frame_error )
        return -1;
      
      if ( length < 2 )
        return -1;

      length--;
      encoded_lrc  = buffer [ length ];
      computed_lrc = calculate_lrc ( buffer, length );  // skip encoded checksum byte
      
      if ( computed_lrc == encoded_lrc )
      {
        *len = length;
        return 1;
      }

      return -1;
    }
    else if ( c != '\r' && ( c < 0x30 || ( c > 0x39 && ( c < 0x41 || c > 0x46 ) ) ) )
      frame_error = true;
    else if ( !frame_error )
    {
      if ( *len > max_size - 1 )
        *len = 0;

      if ( byte_complete )
      {
        Byte t = ascii_to_hex ( buffer [ *len ] );
        t <<= 4;
        t |= ascii_to_hex ( c );
        buffer [ *len ] = t;
        *len = *len + 1;
      }
      else
        buffer [ *len ] = c;

      byte_complete = !byte_complete;
    }
  }

  return 0;
}

void proto_send_error_reply (u8 code)
{
  u8 buffer[2];

  buffer[0] = 0;       // error marker
  buffer[1] = code;    // error code
  proto_send_reply ( buffer, 2 );
}

void proto_send_reply (u8 *buffer, u8 length)
{
  u8 i, ascii_buffer[2];

  Serial.write ( ':' );
  for ( i = 0; i < length; i++ )
  {
    hex_to_ascii ( buffer[i], ascii_buffer );
    Serial.write ( ascii_buffer, 2 );
  }
  hex_to_ascii ( calculate_lrc( buffer, length ), ascii_buffer );
  Serial.write ( ascii_buffer, 2 );
  Serial.print ( "\r\n" );
}

