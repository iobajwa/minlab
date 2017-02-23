[ 
	"../helpers/serial_port",
	"../helpers/minilab_protocol",
	"../helpers/board",
].each {|req| require "#{File.expand_path(File.dirname(__FILE__))}/#{req}"}

begin
	lab = Board.new 'arduino', MinilabProtocol, { :port => 'COM10', :baud => 115200 }

	lab.connect
	puts "connected"

	lab.protocol.write_pin 5, :ao, 50
	puts "pin #5 = 125"

	lab.disconnect
	exit

	
	# read digital input
	pin_state = lab.protocol.read_pin 22, :di
	puts "pin #22 is '#{pin_state}'"
	port.close
	exit
	

	# read analog input
	pin_state = lab.protocol.read_pin 2, :ai
	puts "pin #2 is '#{pin_state}'"

	lab.protocol.write_pin 23, :do, false
	puts "pin #23 = false"

	lab.protocol.write_pin 5, :ao, 125
	puts "pin #5 = 125"

	puts "\n ==== GATEWAY ====\n"
	lab.protocol.serial_gateway_open 1
	puts "gateway opened on comport #1"
	lab.protocol.serial_gateway_flush 1
	lab.protocol.serial_gateway_set_timeout 1, 2000
	lab.protocol.serial_gateway_write 1, [0x30, 0x31, 0x32, 0xD, 0xA]
	buffer, bytes_read = lab.protocol.serial_gateway_read 1, 5
	puts "data read: #{bytes_read}, #{buffer}"

	lab.protocol.serial_gateway_write 1, [0x30, 0x31, 0x32, 0xD, 0xC, 0xB, 0xA]
	buffer, bytes_read = lab.protocol.serial_gateway_read_until 1, 0xA
	puts "data read: #{bytes_read}, #{buffer}"
	
	
	lab.protocol.serial_gateway_close 1


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
	# port.close if port != nil && !port.closed?
rescue => ex
	# port.close if port != nil && !port.closed?
	puts "Error: #{ex.message}"
end

