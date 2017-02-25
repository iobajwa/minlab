
[ 
	"../helpers/serial_port",
	"../helpers/uproto_protocol",
	"../helpers/pins",
	"../helpers/tst_extensions",
].each {|req| require "#{File.expand_path(File.dirname(__FILE__))}/#{req}"}

begin
	port = Serial.new 'COM3', 57600
	uproto = UProtoProtocol.new port

	10000.times {
		uproto.ping
	}

	port.close
	exit

	scr        = Pin.new "scr",        'S', :do, "rw", uproto
	fan        = Pin.new "fan",        'F', :do, "rw", uproto
	red_led    = Pin.new "red_led",    'R', :do, "rw", uproto
	yellow_led = Pin.new "yellow_led", 'Y', :do, "rw", uproto
	white_led  = Pin.new "white_led",  'W', :do, "rw", uproto
	blue_led   = Pin.new "blue_led",   'B', :do, "rw", uproto
	
	uproto.connect
	scr.off
	port.close
	exit

	
	2.times {
		scr.on
		delay 1.second
		scr.off		
		delay 1.second
	}

	port.close
	exit


	# uproto.reset
	# uproto.write_pin 'y', :do, true
	# uproto.write_pin 'y', :do, false
	10.times {
		volts = uproto.read_pin 'V', :ao
		amps = uproto.read_pin 'A', :ao
		temperature = uproto.read_pin 'T', :ao

		puts "volts: #{volts}   amps: #{amps}    temperature: #{temperature}"
		sleep 0.01
	}
	port.close

rescue RubySerial::Exception => ex
	if ex.message == "ERROR_FILE_NOT_FOUND"
		puts "uproto-serial bridge not connected with computer" 
	elsif ex.message == "ERROR_ACCESS_DENIED"
		puts "uproto-serial bridge is already connected with some other application."
	else
		puts "#{ex}"
	end
	port.close if port != nil && !port.closed?
rescue => ex
	port.close if port != nil && !port.closed?
	puts "Error: #{ex.message}"
end

