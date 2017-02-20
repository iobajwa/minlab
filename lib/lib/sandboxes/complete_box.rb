
[ 
	"../helpers/serial_port",
	"../helpers/serial_gateway",
	"../helpers/minilab_protocol",
	"../helpers/uproto_protocol",
	"../helpers/pins",
	"../helpers/tst_extensions",
].each {|req| require "#{File.expand_path(File.dirname(__FILE__))}/#{req}"}

begin
	com_port = Serial.new 'COM10', 115200
	minilab_protocol = MinilabProtocol.new com_port
	minilab_protocol.connect

	gateway_port = SerialGatewayComs.new minilab_protocol, 1, 57600
	gateway_port.open

	uproto = UProtoProtocol.new gateway_port
	uproto.connect
	puts "everything connected!"
	# com_port.close
	# exit


	scr        = DigitalOutputPin.new "scr",       'S', true, uproto
	red_led    = DigitalOutputPin.new "red_led",   'R', true, uproto
	blue_led   = DigitalOutputPin.new "blue_led",  'B', true, uproto
	white_led  = DigitalOutputPin.new "white_led", 'W', true, uproto
	yellow_led = DigitalOutputPin.new "white_led", 'Y', true, uproto

	mock_temperature_signal = AnalogOutputPin.new "mock_temperature_signal", 5, minilab_protocol, 0..500, 0..255

	scr_probe        = DigitalInputPin.new "scr_probe",        30, true, minilab_protocol
	red_led_probe    = DigitalInputPin.new "red_led_probe",    28, false, minilab_protocol
	blue_led_probe   = DigitalInputPin.new "blue_led_probe",   22, false, minilab_protocol
	white_led_probe  = DigitalInputPin.new "white_led_probe",  26, false, minilab_protocol
	yellow_led_probe = DigitalInputPin.new "yellow_led_probe", 24, false, minilab_protocol

	temperature_probe = AnalogInputPin.new "temperature_probe", 'T', uproto, 0..100, 0..100
	amps_probe        = AnalogInputPin.new "amps_probe",        'A', uproto, 0..100, 0..100

	# mock_temperature_signal << 95
	# delay 500.ms

	white_led.off
	puts "#{amps_probe.read}"
	com_port.close
	exit

	puts "amps are: #{amps_probe.read}"
	# puts "temperature_read is: #{temperature_probe.read}"

	# red_led.off
	# blue_led.on
	# white_led.on
	# 10.times {
	# 	white_led.on
	# 	delay 1.second
	# 	white_led.off
	# 	delay 1.second
	# }

	# 10.times {
	# 	yellow_led.on
	# 	white_state  = white_led_probe.is_on?
	# 	red_state    = red_led_probe.is_on?
	# 	yellow_state = yellow_led_probe.is_on?
	# 	blue_state   = blue_led_probe.is_on?
		
	# 	raise "Yellow led not on!" unless yellow_state

	# 	yellow_led.off
	# 	white_state  = white_led_probe.is_on?
	# 	red_state    = red_led_probe.is_on?
	# 	yellow_state = yellow_led_probe.is_on?
	# 	blue_state   = blue_led_probe.is_on?
	# 	raise "Yellow led not off!" if yellow_state

	# 	# puts "white on?: #{white_led_probe.is_set?}"
	# 	# delay 1.second
	# 	# white_led.off
	# 	# puts "white off?: #{white_led_probe.is_reset?}"
	# 	# delay 1.second
	# }



	# scr check
	# 10.times {
	# 	scr.set
	# 	puts "scr switched on"
	# 	delay 200.milliseconds
	# 	feedback = scr_probe.is_set?
	# 	puts "scr_probe feedback : #{feedback}"

	# 	scr.reset
	# 	puts "scr switched off"
	# 	delay 200.milliseconds
	# 	feedback = scr_probe.is_set?
	# 	puts "scr_probe feedback : #{feedback}"
	# }

	com_port.close
	port1.close
	exit

rescue RubySerial::Exception => ex
	if ex.message == "ERROR_FILE_NOT_FOUND"
		puts "uproto-serial bridge not connected with computer" 
	elsif ex.message == "ERROR_ACCESS_DENIED"
		puts "uproto-serial bridge is already connected with some other application."
	else
		puts "#{ex}"
	end
	com_port.close if com_port && !com_port.closed?
rescue => ex
	com_port.close if com_port && !com_port.closed?
	puts "Error: #{ex.message}"
end

