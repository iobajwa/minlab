

port_number = ENV['ARDUINO_COM_PORT']
baud_rate   = ENV['ARDUINO_BAUD_RATE']
raise "'ARDUINO_BAUD_RATE' not defined" unless baud_rate
raise "'ARDUINO_COM_PORT' not defined"  unless port_number

com_port         = Serial.new port_number, 115200
minilab_protocol = MinilabProtocol.new com_port

arduino = Board.new 'arduino', minilab_protocol
pcb     = Board.new 'pcb', minilab_protocol.open_gateway 1, 57600

arduino.wire 'mock_temperature_signal', 19, :ao
arduino.wire 'mock_amps_signal',        19, :ao
arduino.wire 'mock_volts_signal',       19, :ao
arduino.wire 'red_led_probe',    1, :di
arduino.wire 'yellow_led_probe', 2, :di
arduino.wire 'white_led_probe',  3, :di
arduino.wire 'blue_led_probe',   4, :di
arduino.wire 'green_led_probe',  5, :di

pcb.wire 'mock_fan_signal',        1, :do
pcb.wire 'mock_scr_signal',        1, :do
pcb.wire 'mock_red_led_signal',    3, :do
pcb.wire 'mock_yellow_led_signal', 4, :do
pcb.wire 'mock_white_led_signal',  5, :do
pcb.wire 'mock_blue_led_signal',   6, :do
pcb.wire 'mock_green_led_signal',  7, :do

def mock_temperature_signal() return arduino.pins['mock_temperature_signal'] end

arduino.connect
pcb.connect
