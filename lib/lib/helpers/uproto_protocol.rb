
require_relative "protocol_base"

class UProtoProtocol < Protocol
	attr_accessor :coms, :attempts

	ECHO_COMMAND  = ' '
	RESET_COMMAND = '~'
	@@commands = { ' ' => "echo", '~' => "reset" }

	def initialize(coms, attempts=6)
		@attempts = attempts
		super(coms)
	end

	def connect
		@coms.open
		super()
	end

	def ping(count=1)
		count.times { response = send_signal ECHO_COMMAND, "echo" }
	end

	def reset
		response = send_signal RESET_COMMAND, "reset"
	end

	def read_pin number, type, metadata={}
		raise ProtocolEx.new "uproto: only :ai can be read" if type != :ai
		read_frame number
	end

	def write_pin number, type, value
		raise ProtocolEx.new "uproto: only :do can be written" if type != :do
		raise ProtocolEx.new "uproto: cannot write nil" if value == nil
		value = 0 if value.class == FalseClass
		value = 1 if value.class == TrueClass
		raise ProtocolEx.new "uproto: invalid value passed ('#{value}'), only true(1), false(0) can be written to digital-output pin" if (value.class != Fixnum) || (value != 0 && value != 1)
		number = number.to_s unless number.class == String
		number = number[0]
		number = number.downcase if value == 0
		number = number.upcase if value == 1
		send_signal number
	end
	

	def send_signal code, command_name=nil
		response = nil
		attempt_count = 0
		@attempts.times {
			attempt_count += 1
			@coms.flush
			@coms.write code
			response = @coms.read_byte
			response = response.chr if response
			break if response == code
			sleep 0.250
		}
		command_name = code unless command_name
		raise ProtocolEx.new "uproto: received no response for command '#{command_name}'" if response == nil
		raise ProtocolEx.new "uproto: command not recoganized '#{command_name}'" if response == "?"

		response = response.chr
		raise ProtocolEx.new "uproto: received invalid reply ('#{response.bytes[0] & 0xFF}') for command '#{command_name}' ('#{code}'), (#{attempt_count} attempts)" if response != code
	end

	def read_frame code
		response = nil
		@attempts.times {
			@coms.flush
			@coms.write code
			response_unpacked = @coms.read_until 0xA

			raise ProtocolEx.new "uproto error: received no response for '#{code}' command." if response_unpacked == nil
			raise ProtocolEx.new "uproto: command not recoganized '#{code}'" if response_unpacked[0].chr == '?'

			sof = response_unpacked.shift
			raise ProtocolEx.new "uproto error: wrong SOF ('#{sof}')" unless sof == 0x3A
			response_unpacked.pop
			response_unpacked.pop
			raise ProtocolEx.new "uproto error: received odd length, indicates missing bytes" unless response_unpacked.length % 2 == 0
			response = pack_response response_unpacked
			encoded_checksum = (response.pop) & 0xFF
			calculated_checksum = calculate_checksum response
			raise ProtocolEx.new "uproto error: checksum error ('#{calculated_checksum}' != '#{encoded_checksum}')" if calculated_checksum != encoded_checksum
			raise ProtocolEx.new "uproto error: returned value is too large (> 8 bytes)" if response.length > 8
			raise ProtocolEx.new "uproto error: returned value is nil" if response.length == 0
			return pack_to_fixnum response
		}
	end



	###### helpers

	def pack_to_fixnum bytes
		# we are assuming that data is encoded in big-endian format (mostly we use sprintf in firmware to write data onto ASCII frame)
		packed_result = 0
		i = bytes.length
		bytes.each {  |b|
			i -= 1
			packed_result |= b << (8 * i)
		}
		if bytes.length == 1
			packed_result &= 0xFF
		elsif bytes.length == 2
			packed_result &= 0xFFFF
		elsif bytes.length == 3
			packed_result &= 0xFFFFFF
		elsif bytes.length == 4
			packed_result &= 0xFFFFFFFF
		end
			
		return packed_result
	end

end
