
require_relative "serial_gateway"

class ProtocolEx < Exception
end

class Protocol

	connected=false

	def initialize
		@connected =  false
	end

	def open_gateway port_number, baudrate
		return nil
	end

	def connect
		@connected = true
	end

	def connected?
		return @connected
	end

	def ping(count=1)
		raise "Not Implemented!"
	end

	# packs ascii-encoded frame into binary frames
	def pack_response loose_bytes
		packed = []
		complete_byte = false
		half_byte = nil
		loose_bytes.each {  |b|
			raise "Protocol error: corrupt byte received ('#{b}')" if b < 0x30 || b > 0x46 || ( b > 0x39 && b < 0x41 )
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

	def calculate_checksum bytes
		checksum = 0
		
		bytes.each {  |b| checksum += (b &0xFF) }
		checksum &= 0xFF
		return (~checksum + 1) & 0xFF
	end

	def to_ascii byte
		return sprintf "%02X", byte & 0xFF
	end


	# pack array into u16 little-endian
	def pack16_le array
		return ( (array[0]) | (array[1] << 8) ) & 0xFFFF
	end

	# unpacks 16 bit value into byte-stream (little endian)
	def unpack16_le value
		return [ value & 0xFF, (( value >> 8 ) & 0xFF) ]
	end
end
