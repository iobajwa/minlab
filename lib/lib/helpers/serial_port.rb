
require 'rubyserial'

class Serial
	# port is already opened when we create an instance
	# this method has been provided merely for convention reasons
	def open
	end

	def flush
		while true
			byte = getbyte
			break if byte == nil
		end
	end

	def read_byte(timeout=1000)
		byte = nil
		start_time = Time.now
		while (Time.now - start_time) * 1000.0 < timeout
			byte = getbyte
			break if byte
		end

		return byte
	end

	def read_until(marker=0x0A, timeout=1000)
		data_bytes = []
		start_time = Time.now
		while (Time.now - start_time) * 1000.0 < timeout
			byte = getbyte
			data_bytes.push byte unless byte == nil
			break if byte == marker
		end
		return data_bytes.length == 0 ? nil : data_bytes
	end
end
