
#include "types.h"
#include "proto.h"

u8 serial_buffer[270];
u16 serial_buffer_length = 0;
u8 response_error_code;
u8 response_error_param;

#define register_error(__code, __param)  do { response_error_code = __code; response_error_param = __param; } while( 0 );
#define raise_error(__code, __param)     do { response_error_code = __code; response_error_param = __param; return false; } while( 0 );
#define reset_errors()                   do { response_error_code = 0; response_error_param = 0; } while( 0 );


#define MAX_BAUDRATE_INDEX    11
const u32 supported_baudrates[]   = { 300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200 };

u8 last_analog_reference;
HardwareSerial *com_ports[4] = { 0, 0, 0, 0 };


void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  pinMode(LED_BUILTIN, OUTPUT);

  com_ports[0] = &Serial;
  com_ports[1] = &Serial1;
  com_ports[2] = &Serial2;
  com_ports[3] = &Serial3;
  last_analog_reference = 0;
}

void loop() {
  // put your main code here, to run repeatedly:
  i8 status;
  static bool led_status = true;

  status = proto_try_read_request( serial_buffer, &serial_buffer_length, sizeof serial_buffer );
  
  if ( status < 0 )
  {
    proto_send_error_reply_(0, 0);
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
void service_request ( Byte *buffer, u16 length )
{
  Char out_buffer[270];
  bool success = false;
  u8 command;
  u16 out_length = 0;

  reset_errors();
  
  // shift out command
  command = *buffer++;
  length--;

  // service command
  switch ( command ) 
  {
    default : register_error( 0xFF, command ); break; // command unknown
    case 1  : success = service_echo                 ( buffer, length, out_buffer + 1, &out_length ); break;
    case 2  : success = service_read_digital_input   ( buffer, length, out_buffer + 1, &out_length ); break;
    case 3  : success = service_write_digital_output ( buffer, length, out_buffer + 1, &out_length ); break;
    case 4  : success = service_read_analog_input    ( buffer, length, out_buffer + 1, &out_length ); break;
    case 5  : success = service_write_analog_output  ( buffer, length, out_buffer + 1, &out_length ); break;

    // serial gateway
    case 6  : success = service_sg_open        ( buffer, length, out_buffer + 1, &out_length ); break;
    case 7  : success = service_sg_close       ( buffer, length, out_buffer + 1, &out_length ); break;
    case 8  : success = service_sg_flush       ( buffer, length, out_buffer + 1, &out_length ); break;
    case 9  : success = service_sg_write       ( buffer, length, out_buffer + 1, &out_length ); break;
    case 10 : success = service_sg_read        ( buffer, length, out_buffer + 1, &out_length ); break;
    case 11 : success = service_sg_set_timeout ( buffer, length, out_buffer + 1, &out_length ); break;

    case 12 : success = service_wire_net_read ( buffer, length, out_buffer + 1, &out_length ); break;
    // case 13: error_code = service_reset  ( buffer, length, out_buffer + 1, &out_length ); break;
  }
  
  if ( success )
  {
    out_buffer[0] = command;
    out_length += 1;
    proto_send_reply( out_buffer, out_length );
  }
  else
    proto_send_error_reply();
}


bool check_digital_pin_number(u8 pin_id)
{
  return pin_id > 21 && pin_id < 54;
}

bool check_ao_pin_number(u8 pin_id)
{
  return pin_id < 14;
}

bool check_ai_pin_number(u8 pin_id)
{
  return pin_id < 16;
}

bool check_sg_uart_number(u8 uart_id)
{
  return uart_id < 4 && uart_id > 0;
}


/* format: <ECHO><what-ever> */
bool service_echo (Char* buffer, u16 length, Char *out_buffer, u16 *out_length )
{
  *out_length = 0;
  return true;
}

/* format   : <DI><pin-number>
   response : <DI><pin-number><state>
  error_codes = {
    1 => "invalid command length"
    2 => "invalid pin number"
  }
*/
bool service_read_digital_input (Char* buffer, u16 length, Char *out_buffer, u16 *out_length)
{
  u8 pin_number = buffer[0];

  if ( length != 1 )
    raise_error(1, length);     // invalid command length

  if ( check_digital_pin_number ( pin_number ) ) 
  {
    pinMode ( pin_number, INPUT );
    out_buffer[0] = pin_number;
    out_buffer[1] = digitalRead( pin_number );
    *out_length = 2;
    return true;
  }

  raise_error(2, pin_number);   // invalid pin number
}

/* format   : <DO><pin-number><state>
   response : <DO><pin-number><state>
  error codes = {
    1 => "invalid command length"
    2 => "invalid pin number"
    3 => "invalid state"
  }
*/
bool service_write_digital_output (Char* buffer, u16 length, Char *out_buffer, u16 *out_length)
{
  u8 pin_number = buffer[0];
  u8 state = buffer[1];

  if ( length != 2 )
    raise_error(1, length);     // invalid command length

  if ( state > 1 )
    raise_error(3, state);      // invalid state

  if ( check_digital_pin_number ( pin_number ) ) 
  {
    pinMode      ( pin_number, OUTPUT );
    digitalWrite ( pin_number, state );
    out_buffer[0] = pin_number;
    out_buffer[1] = state;      // echo back the command as result
    *out_length = 2;
    return true;
  }

  raise_error(2, pin_number);   // invalid pin number
}

/* format   : <AI><pin-number><ref>
   response : <AI><pin-number><ref><state>
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
bool service_read_analog_input (Char *buffer, u16 length, Char *out_buffer, u16 *out_length)
{
  u8 pin_number = buffer[0];
  u8 ref = buffer[1];

  if ( length != 2 )
    raise_error(1, length);   // invalid command length

  if ( ref > 3 )
    raise_error(3, ref);      // invalid reference

  if ( check_ai_pin_number ( pin_number ) ) 
  {
    u8 ref_codes[] = { DEFAULT, INTERNAL1V1, INTERNAL2V56, EXTERNAL }, new_ref;
    u16 result;

    pinMode         ( pin_number, INPUT );
    analogReference ( ref_codes[ref] );
    result = analogRead ( pin_number );
    if ( ref != last_analog_reference )
    {
      delay(20);              // allow the readings to stabalize because we just changed analogReference
      result = analogRead ( pin_number );
      last_analog_reference = ref;
    }
    out_buffer[0] = pin_number;
    out_buffer[1] = ref;
    out_buffer[2] = (u8)(result & 0xFF);
    out_buffer[3] = (u8)((result >> 8) & 0xFF);
    *out_length = 4;
    return true;
  }

  raise_error(2, pin_number)    // invalid pin number
}

/* format   : <AO><pin-number><8 bit value>
   response : <AO><pin-number><8 bit value>
    error codes = {
      1 => "invalid command length"
      2 => "invalid pin number"
    }
*/
bool service_write_analog_output (Char* buffer, u16 length, Char *out_buffer, u16 *out_length)
{
  u8 pin_number = buffer[0];
  u8 value = buffer[1];

  if ( length != 2 )
    raise_error(1, length);     // invalid command length

  if ( check_ao_pin_number ( pin_number ) ) 
  {
    pinMode     ( pin_number, OUTPUT );
    analogWrite ( pin_number, value );
    out_buffer[0] = pin_number;
    out_buffer[1] = value;
    *out_length = 2;
    return true;
  }
  
  raise_error(2, pin_number);   // invalid pin number
}

/* format   : <sgO><uart-number><baudrate><timeout_l><timeout_h>
   response : <sgO><uart-number><baudrate><timeout_l><timeout_h>
    error codes = {
      1 => "invalid command length"
      2 => "invalid uart number"
      3 => "invalid baudrate"
    }
*/
bool service_sg_open (Char* buffer, u16 length, Char *out_buffer, u16 *out_length)
{
  u8 uart_number = buffer[0];
  u8 baudrate_id = buffer[1];
  u16 timeout = 0;
  u32 baud    = 0;

  if ( length != 4 )
    raise_error(1, length);         // invalid command length

  if ( !check_sg_uart_number ( uart_number ) )
    raise_error(2, uart_number);    // invalid uart number

  if ( baudrate_id > MAX_BAUDRATE_INDEX )
    raise_error(3, baudrate_id);    // invalid baudrate_id

  timeout = buffer[2] | ( ((u16)buffer[3]) << 8 );
  baud    = supported_baudrates[baudrate_id];

  HardwareSerial *port = get_com_port_ref(uart_number);
  port->begin(baud);
  port->setTimeout(timeout);

  out_buffer[0] = uart_number;
  out_buffer[1] = baudrate_id;
  out_buffer[2] = buffer[2];
  out_buffer[3] = buffer[3];
  *out_length = 4;

  return true;
}

/* format   : <sgC><uart-number>
   response : <sgC><uart-number>
    error codes = {
      1 => "invalid command length"
      2 => "invalid uart number"
    }
*/
bool service_sg_close (Char* buffer, u16 length, Char *out_buffer, u16 *out_length)
{
  u8 uart_number = buffer[0];

  if ( length != 1 )
    raise_error(1, length);         // invalid command length

  if ( !check_sg_uart_number ( uart_number ) )
    raise_error(2, uart_number);    // invalid uart number

  HardwareSerial *port = get_com_port_ref(uart_number);
  port->end();
  
  out_buffer[0] = uart_number;
  *out_length = 1;

  return true;
}

/* format   : <sgF><uart-number>
   response : <sgF><uart-number>
    error codes = {
      1 => "invalid command length"
      2 => "invalid uart number"
    }
*/
bool service_sg_flush (Char* buffer, u16 length, Char *out_buffer, u16 *out_length)
{
  u8 uart_number = buffer[0];

  if ( length != 1 )
    raise_error(1, length);           // invalid command length

  if ( !check_sg_uart_number ( uart_number ) )
    raise_error(2, uart_number);      // invalid uart number

  HardwareSerial *port = get_com_port_ref(uart_number);
  while( port->available() ) 
  { 
    port->read(); 
  }
  
  out_buffer[0] = uart_number;
  *out_length = 1;

  return true;
}

/* format   : <sgW><uart-number><packet-length><[packet]>
   response : <sgW><uart-number><bytes-written>
    error codes = {
      1 => "invalid command length"
      2 => "invalid uart number"
    }
*/
bool service_sg_write (Char* buffer, u16 length, Char *out_buffer, u16 *out_length)
{
  u8 uart_number   = buffer[0];
  u8 packet_length = buffer[1];
  u8 bytes_written = 0;

  if ( length != packet_length + 2 )
    raise_error(1, length);         // invalid command length

  if ( !check_sg_uart_number ( uart_number ) )
    raise_error(2, uart_number);    // invalid uart number

  if ( packet_length )
  {
    HardwareSerial *port = get_com_port_ref(uart_number);
    bytes_written = port->write( buffer + 2, packet_length );
  }

  out_buffer[0] = uart_number;
  out_buffer[1] = bytes_written;
  *out_length = 2;

  return true;
}

/* format   : <sgR><eof-marker|uart-number>
              if ( eof-marker )
              {
                <eof-marker><max-read-length>
              }
              else
              {
                <max-read-length>
              }
   response : <sgR><eof-marker|uart-number>
              if ( eof-marker )
              {
                <eof-marker><bytes-read-count><[read-bytes]>
              }
              else
              {
                <bytes-read-count><[read-bytes]>
              }
    error codes = {
      1 => "invalid command length"
      2 => "invalid uart number"
    }
*/
bool service_sg_read (Char* buffer, u16 length, Char *out_buffer, u16 *out_length)
{
  u8 uart_number = buffer[0];
  bool mode_eof  = (uart_number & 0x10) != 0; 

  if ( length < 1 )
    raise_error(1, length);           // invalid command length

  uart_number &= 0x0F;
  if ( !check_sg_uart_number ( uart_number ) )
    raise_error(2, uart_number);      // invalid uart number


  if ( mode_eof )
  {
    u8 eof_marker = buffer[1];
    u8 max_length = buffer[2];
    u8 bytes_read;

    if ( length < 3 )
      raise_error(1, length);           // invalid command length

    HardwareSerial *port = get_com_port_ref(uart_number);
    bytes_read = port->readBytesUntil(eof_marker, out_buffer + 3, max_length);

    if ( bytes_read > 0 )
    {
      out_buffer[3 + bytes_read] = eof_marker;
      bytes_read++;
    }
    
    out_buffer[0] = buffer[0];
    out_buffer[1] = buffer[1];
    out_buffer[2] = bytes_read;

    *out_length = (u16)3 + bytes_read;

    return true;
  }
  else
  {
    u8 byte_count = buffer[1];
    u8 bytes_read;

    if ( length < 2 )
      raise_error(1, length);           // invalid command length

    HardwareSerial *port = get_com_port_ref(uart_number);
    bytes_read = port->readBytes(out_buffer + 2, byte_count);

    out_buffer[0] = buffer[0];
    out_buffer[1] = bytes_read;
    *out_length = (u16)2 + bytes_read;

    return true; 
  }
}

/* format   : <sgST><uart-number><timeout_l><timeout_h>
   response : <sgST><uart-number><timeout_l><timeout_h>
    error codes = {
      1 => "invalid command length"
      2 => "invalid uart number"
    }
*/
bool service_sg_set_timeout (Char* buffer, u16 length, Char *out_buffer, u16 *out_length)
{
  u8 uart_number = buffer[0];
  u16 timeout    = 0;

  if ( length != 3 )
      raise_error(1, length);           // invalid command length

  if ( !check_sg_uart_number ( uart_number ) )
      raise_error(2, uart_number);      // invalid uart number

  timeout = buffer[1] | ( ((u16)buffer[2]) << 8 );
  
  HardwareSerial *port = get_com_port_ref(uart_number);
  port->setTimeout(timeout);
  
  out_buffer[0] = uart_number;
  out_buffer[1] = buffer[1];
  out_buffer[2] = buffer[2];
  *out_length = 3;

  return true;
}

/* format   : <NR>[<pin-numbers>]
   response : <NR>[<state_packed>]
  error_codes = {
    1 => "invalid pin count"
    2 => "invalid pin number"
  }
*/
bool service_wire_net_read (Char* buffer, u16 length, Char *out_buffer, u16 *out_length)
{
  u8 i, byte_count;
  u64 state_packed = 0;

  if ( length == 0 || length > 64 )
      raise_error(1, length);           // invalid pin count

  for ( i = 0; i < length; i++ )
  {
    u8 pin_number = buffer[i];

    if ( check_digital_pin_number ( pin_number ) ) 
    {
      u8 state;

      pinMode( pin_number, INPUT );
      state = digitalRead( pin_number );

      state_packed |= (state << i);
    }
    else
      raise_error(2, pin_number);      // invalid pin number
  }

  /* dirty way :| */
  out_buffer[0] = (u8)state_packed;
  out_buffer[1] = (u8)(state_packed >> 8);
  out_buffer[2] = (u8)(state_packed >> 16);
  out_buffer[3] = (u8)(state_packed >> 24);
  out_buffer[4] = (u8)(state_packed >> 32);
  out_buffer[5] = (u8)(state_packed >> 40);
  out_buffer[6] = (u8)(state_packed >> 48);
  out_buffer[7] = (u8)(state_packed >> 56);

  byte_count = (length / 8);
  byte_count += (length % 8) ? 1 : 0;

  *out_length = byte_count;

  return true;
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

i8 proto_try_read_request ( Byte* buffer, u16 *len, u16 max_size )
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

void proto_send_error_reply (void)
{
  proto_send_error_reply_(response_error_code, response_error_param);
}

void proto_send_error_reply_ (u8 code, u8 param)
{
  u8 buffer[3];

  buffer[0] = 0;       // error marker
  buffer[1] = code;    // error code
  buffer[2] = param;   // optional error parameter
  proto_send_reply ( buffer, 3 );
}

void proto_send_reply (u8 *buffer, u16 length)
{
  u8 ascii_buffer[2];
  u16 i;

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

HardwareSerial* get_com_port_ref (u8 com_port_id )
{
  return com_ports[com_port_id];
}

