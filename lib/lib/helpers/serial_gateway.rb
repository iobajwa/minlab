
class SerialGatewayComs
	attr_accessor :carrier_protocol, :port_number, :baudrate, :timeout

	def initialize(carrier_protocol, port_number, baudrate, timeout=1000)
		@carrier_protocol = carrier_protocol
		@port_number = port_number
		@baudrate = baudrate
		@timeout = timeout
	end

	def open
		@carrier_protocol.serial_gateway_open @port_number, @baudrate, @timeout
	end

	def close
		@carrier_protocol.serial_gateway_close @port_number
	end

	def flush
		@carrier_protocol.serial_gateway_flush @port_number
	end

	def read_byte timeout=@timeout
		data = read_bytes 1, timeout
		return data[0]
	end

	def read_until marker=0x0A, max_read_length=220, timeout=@timeout
		set_timeout timeout
			
		data, count = @carrier_protocol.serial_gateway_read_until @port_number, marker, max_read_length

		return data.length == 0 ? nil : data
	end

	def write(data)
		payload = []
		if data.class == String
			payload = data.bytes
		elsif data.class == Array
			payload = data
		else
			payload = [data]
		end
		return @carrier_protocol.serial_gateway_write @port_number, payload
	end

	def read_bytes count, timeout=1000
		set_timeout timeout
		data, count = @carrier_protocol.serial_gateway_read @port_number, 1
		return nil if count == 0
		return data
	end

	def set_timeout timeout
		if timeout != @timeout
			@carrier_protocol.serial_gateway_set_timeout @port_number, timeout
			@timeout = timeout
		end
	end
end
