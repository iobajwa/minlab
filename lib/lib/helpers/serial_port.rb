
require 'rubyserial'

class Serial
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
