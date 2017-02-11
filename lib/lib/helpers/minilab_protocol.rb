
# class SerialGateway
# 	attr_accessor :carrier_protocol, :port_number, :baudrate, :timeout

# 	def initialize(carrier_protocol, port_number, baudrate, timeout)
# 		@carrier_protocol = carrier_protocol
# 		@port_number     = port_number
# 		@baudrate        = baudrate
# 		@timeout         = timeout
# 	end

# 	def read byte_count
# 		return @carrier_protocol.serial_gateway_read byte_count, port_number, baudrate, timeout
# 	end

# 	def write bytes
# 		@carrier_protocol.serial_gateway_write bytes, port_number, baudrate, timeout
# 	end
# end
class ProtocolEx < Exception
end

class MinilabProtocol
	attr_accessor :coms

    ERROR_PACKET     = 0
	ECHO_COMMAND     = 1
    READ_DI_COMMAND  = 2
    WRITE_DO_COMMAND = 3
    READ_AI_COMMAND  = 4
    WRITE_AO_COMMAND = 5

    # serial gateway commands
    SG_OPEN        = 6
    SG_CLOSE       = 7
    SG_FLUSH       = 8
    SG_WRITE       = 9
    SG_READ        = 10
    SG_SET_TIMEOUT = 11

    # RESET_COMMAND = 12

    @@commands = {
    	0 => "error-packet",
    	1 => "echo",
    	2 => "read-digital-input",
    	3 => "write-digital-output",
    	4 => "read-analog-input",
    	5 => "write-analog-output",

    	6  => "serial-gateway-open",
		7  => "serial-gateway-close",
		8  => "serial-gateway-flush",
		9  => "serial-gateway-write",
		10 => "serial-gateway-read",
		11 => "serial-gateway-set_timeout",

    	# 12 => "reset",
    }

	@@supported_pin_types = [:di, :do, :ai, :ao]
	@@ai_references       = { "default" => 0, "internal_1.1v" => 1, "internal_2.56v" => 2, "external" => 3 }
	@@comport_baudrates = { 300    => 0,
							600    => 1,
							1200   => 2,
							2400   => 3,
							4800   => 4,
							9600   => 5,
							14400  => 6,
							19200  => 7,
							28800  => 8,
							38400  => 9,
							57600  => 10,
							115200 => 10, 
						  }

	@@error_codes = {
		ECHO_COMMAND     => {},
		READ_DI_COMMAND  => { 1 => "invalid command length", 2 => "invalid pin number" },
		WRITE_DO_COMMAND => { 1 => "invalid command length", 2 => "invalid pin number", 3 => "invalid state" },
		READ_AI_COMMAND  => { 1 => "invalid command length", 2 => "invalid pin number", 3 => "invalid reference code"},
		WRITE_AO_COMMAND => { 1 => "invalid command length", 2 => "invalid pin number" },

		#serial gateway commands error codes

		SG_OPEN        => { 1 => "invalid command length", 2 => "invalid com port id", 3 => "invalid baudrate" },
		SG_CLOSE       => { 1 => "invalid command length", 2 => "invalid com port id", },
		SG_FLUSH       => { 1 => "invalid command length", 2 => "invalid com port id", },
		SG_WRITE       => { 1 => "invalid command length", 2 => "invalid com port id", },
		SG_READ        => { 1 => "invalid command length", 2 => "invalid com port id", },
		SG_SET_TIMEOUT => { 1 => "invalid command length", 2 => "invalid com port id", },
	}


	def initialize(coms)
		@coms = coms
	end

	def connect
		response = send_command ECHO_COMMAND
		check_response response, [ECHO_COMMAND]
		# reset
	end

	def reset
		# response = send_command RESET_COMMAND
		# check_response response, [RESET_COMMAND]
	end

	def read_pin number, type, metadata={}
		check_type type

		if type == :di
		
			response = send_command READ_DI_COMMAND, number
			check_response response, [READ_DI_COMMAND, number], 3
			pin_state = response[2]
			raise ProtocolEx.new "Firmware-protocol error: received pin state invalid ('#{pin_state}')" unless pin_state == 0 || pin_state == 1
			return pin_state
		
		elsif type == :ai
		
			# figure out reference
			reference = @@ai_references["default"]
			reference = metadata["reference"] if metadata != nil && metadata.include?("reference")
			raise "ProtocolEx MinilabProtocol: :ai reference can only be a Fixnum" if reference.class != Fixnum

			response = send_command READ_AI_COMMAND, [number, reference]

			check_response response, [READ_AI_COMMAND, number, reference], 5
			return pack16_le response[3..4]
		
		else
			raise ProtocolEx.new "MinilabProtocol: Only :di and :ai pins can be read"
		end
	end

	def write_pin number, type, value
		check_type type

		if type == :do
			value = 0 if value.class == FalseClass
			value = 1 if value.class == TrueClass
			raise ProtocolEx.new "MinilabProtocol: only true(1), false(0) can be written to digital-output pin" if value.class != Fixnum

			response = send_command WRITE_DO_COMMAND, [number, value]

			check_response response, [WRITE_DO_COMMAND, number, value]
		
		elsif type == :ao
			raise ProtocolEx.new "MinilabProtocol: only Fixnum < 256 can be written to analog-output pin" if value.class != Fixnum || value > 255

			response = send_command WRITE_AO_COMMAND, [number, value]

			check_response response, [WRITE_AO_COMMAND, number, value]
		else
			raise ProtocolEx.new "MinilabProtocol: Only :do and :ao pins can be written"
		end
	end
	
	def serial_gateway_open com_port_id, baud_rate=9600, timeout=1000
		check_com_port com_port_id

		baudrate_index = @@comport_baudrates[baud_rate]
		raise ProtocolEx.new "MinilabProtocol: invalid baudrate ('#{baud_rate}'), valid baudrates are: '#{@@comport_baudrates.keys}'" if baudrate_index == nil

		timeout_unpacked = unpack16_le timeout
		response = send_command SG_OPEN, [com_port_id, baudrate_index, timeout_unpacked ]

		check_response response, [SG_OPEN, com_port_id, baudrate_index, timeout_unpacked]
	end

	def serial_gateway_close com_port_id
		check_com_port com_port_id

		response = send_command SG_CLOSE, [com_port_id]

		check_response response, [SG_CLOSE, com_port_id]
	end

	def serial_gateway_flush com_port_id
		check_com_port com_port_id

		response = send_command SG_FLUSH, [com_port_id]

		check_response response, [SG_FLUSH, com_port_id]
	end

	def serial_gateway_set_timeout com_port_id, timeout
		check_com_port com_port_id

		timeout_unpacked = unpack16_le timeout
		response = send_command SG_SET_TIMEOUT, [com_port_id, timeout_unpacked ]

		check_response response, [SG_SET_TIMEOUT, com_port_id, timeout_unpacked ]
	end

	def serial_gateway_write com_port_id, bytes
		check_com_port com_port_id
		raise ProtocolEx.new "MinilabProtocol: cannot relay more than 220 bytes!" if bytes.length > 220

		response = send_command SG_WRITE, [com_port_id, bytes.length, bytes ]

		check_response response, [SG_WRITE, com_port_id, bytes.length ]
	end

	def serial_gateway_read_until com_port_id, marker, max_read_length=220
		check_com_port com_port_id
		raise ProtocolEx.new "MinilabProtocol: cannot relay more than 220 bytes!" if max_read_length > 220

		flags = (com_port_id | 0x10) & 0xFF
		response = send_command SG_READ, [flags, marker, max_read_length]

		check_response response[0..2], [SG_READ, flags, marker]
		
		bytes_read = response[3]
		return [], 0 if bytes_read == 0

		expected_length = 4 + bytes_read
		raise ProtocolEx.new "Firmware-protocol: improper response length received ('#{response.length}'), expected was '#{expected_length}'" if response.length != expected_length
		return response[4..4+bytes_read], bytes_read
	end

	def serial_gateway_read com_port_id, byte_count
		check_com_port com_port_id
		raise ProtocolEx.new "MinilabProtocol: cannot relay more than 220 bytes!" if byte_count > 220

		response = send_command SG_READ, [com_port_id, byte_count]

		check_response response[0..1], [SG_READ, com_port_id]

		bytes_read = response[2]
		return [], 0 if bytes_read == 0
		return response[3..2+bytes_read], bytes_read
	end



	def send_command command_code, payload=nil
		# create frame
		if payload != nil
			payload = [payload] if payload.class != Array
			payload.flatten!
			payload = nil if payload.length == 0
		end
		bytes = [command_code]
		bytes.push payload if payload
		bytes.flatten!
		checksum = calculate_checksum bytes
		bytes.push checksum

		frame = ":"
		bytes.each {  |f| frame += to_ascii(f) }
		frame += "\n"


		# write frame
		@coms.write frame

		# read response
		response_unpacked = @coms.read_until 0xA
		raise ProtocolEx.new "Firmware-protocol error: received no response for '#{@@commands[command_code]}' command!" if response_unpacked == nil
		sof = response_unpacked.shift
		raise ProtocolEx.new "Firmware-protocol error: wrong SOF ('#{sof}')" unless sof == 0x3A
		response_unpacked.pop
		response_unpacked.pop
		raise ProtocolEx.new "Firmware-protocol error: received odd length, indicates missing bytes" unless response_unpacked.length % 2 == 0
		response = pack_response response_unpacked
		encoded_checksum = response.pop
		calculated_checksum = calculate_checksum response
		raise ProtocolEx.new "Firmware-protocol error: checksum error ('#{calculated_checksum}' != '#{encoded_checksum}')" if calculated_checksum != encoded_checksum

		return response
	end



	###### helpers

	def calculate_checksum bytes
		checksum = 0
		
		bytes.each {  |b| checksum += (b &0xFF) }
		checksum &= 0xFF
		return (~checksum + 1) & 0xFF
	end

	def to_ascii byte
		return sprintf "%02X", byte & 0xFF
	end

	def pack_response loose_bytes
		packed = []
		complete_byte = false
		half_byte = nil
		loose_bytes.each {  |b|
			if complete_byte
				other_half = b - 0x30
				other_half -=7 if other_half > 9
				complete_byte = half_byte | other_half
				packed.push complete_byte
			else
				half_byte = b - 0x30
				half_byte -=7 if half_byte > 9
				half_byte <<= 4
			end
			complete_byte = !complete_byte
		}
		return packed
	end

	def check_response response, expected_response=[], expected_length=nil
		expected_response.flatten!

		if response[0] == ERROR_PACKET
			command_code = expected_response[0]
			command_name = @@commands[command_code]
			error_code = response[1]
			error_description = @@error_codes[command_code][error_code]
			raise ProtocolEx.new "MinilabProtocol: command '#{command_name}' returned error-code '#{error_code}', '#{error_description}'"
		end
		expected_length = expected_response.length if expected_length == nil
		raise ProtocolEx.new "Firmware-protocol: improper response length received ('#{response.length}'), expected was '#{expected_length}'" if response.length != expected_length
		max_length = (response.length > expected_response.length ? expected_response.length : response.length) - 1
		for i in 0..max_length
			raise ProtocolEx.new "Firmware-protocol: improper response received ('#{response}'), expected was '#{expected_response}'" if response[i] != expected_response[i]
		end
	end

	def check_type type
		raise ProtocolEx.new "MinilabProtocol: Pin type ('#{type}') is not supported!" unless @@supported_pin_types.include? type
	end

	# pack array into u16 little-endian
	def pack16_le array
		return ( (array[0]) | (array[1] << 8) ) & 0xFFFF
	end

	def unpack16_le value
		return [ value & 0xFF, (( value >> 8 ) & 0xFF) ]
	end

	def check_com_port com_port_id
		raise ProtocolEx.new "MinilabProtocol: only com_ports 1..3 are available." if com_port_id < 1 || com_port_id > 3
	end


=begin	
	def serial_gateway_read byte_count, portnumber, baudrate, timeout=1000
	end

	# baud_rates = [300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200]
	# total 12
	def serial_gateway_write bytes, portnumber, baudrate
 		baud_rates = [300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200]
		bytes_broken = []
		bytes.each {  |b|
			upper = ( ( b >> 4 ) & 0xF )
			upper += 7 if upper > 9
			upper |= 0x30
			bytes_broken.push upper

			lower = ( ( b >> 4 ) & 0xF )
			lower += 7 if lower > 9
			lower |= 0x30
			bytes_broken.push lower
		}
		bit
		header = [0x3A, ]
	end
=end
end


[ 
	"serial_port",
].each {|req| require "#{File.expand_path(File.dirname(__FILE__))}/#{req}"}

begin
	port = Serial.new 'COM10', 115200
	protocol = MinilabProtocol.new port
	protocol.connect
	puts "connected"
	
	# read digital input
	pin_state = protocol.read_pin 22, :di
	puts "pin #22 is '#{pin_state}'"

	# read analog input
	pin_state = protocol.read_pin 2, :ai
	puts "pin #2 is '#{pin_state}'"

	protocol.write_pin 23, :do, false
	puts "pin #23 = false"

	protocol.write_pin 5, :ao, 125
	puts "pin #5 = 125"

	puts "\n ==== GATEWAY ====\n"
	protocol.serial_gateway_open 1
	puts "gateway opened on comport #1"
	protocol.serial_gateway_flush 1
	protocol.serial_gateway_set_timeout 1, 2000
	protocol.serial_gateway_write 1, [0x30, 0x31, 0x32, 0xD, 0xA]
	buffer, bytes_read = protocol.serial_gateway_read 1, 5
	puts "data read: #{bytes_read}, #{buffer}"

	protocol.serial_gateway_write 1, [0x30, 0x31, 0x32, 0xD, 0xC, 0xB, 0xA]
	buffer, bytes_read = protocol.serial_gateway_read_until 1, 0xA
	puts "data read: #{bytes_read}, #{buffer}"
	
	
	protocol.serial_gateway_close 1


	# protocol
	port.close

rescue RubySerial::Exception => ex
	if ex.message == "ERROR_FILE_NOT_FOUND"
		puts "minilab board not connected with hardware" 
	elsif ex.message == "ERROR_ACCESS_DENIED"
		puts "minilab board is already connected with some other application."
	else
		puts "#{ex}"
	end
	port.close if port != nil && !port.closed?
rescue => ex
	port.close if port != nil && !port.closed?
	puts "Error: #{ex.message}"
end

