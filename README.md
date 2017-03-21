# *minlab* #

A PCB unit-testing framework. The firmware runs on an Arduino Mega and acts as an interface between the PCB and tests using a custom protocol on UART0. The tests are written in a ruby based DSL which provides high level asserts and helper functions along with a test runner.

### Quick overview ###

Simply create a .rb file which contains the board, wiring and tests and run it using minlab.
```
#!ruby

# create boards
arduino = Board.new 'arduino', MinlabProtocol
pcb     = Board.new 'pcb',     UProtoProtocol, { :gateway => arduino, :port => 1, :baud => 57600 }


# mention connections- what is connected where

#    board     pin_name                 pin_number, pin_type, meta    
wire arduino, 'mock_temperature_signal', 3,         :ao,      { :raw_scale => 0..255, :end_scale => 0..100 }
wire arduino, 'fan_probe',               34,        :di,      :active_low
wire arduino, 'temperature_alarm_probe', 35,        :di


# tests
test "Fan Test - Low Temperature", "checks if fan is switched off when temperature is below the threshold value" do
	# setup
	mock_temperature_signal << 50

	# assert
	fan_probe.is_off?
	temperature_alarm_probe.is_reset?
end

test "Fan Test - Medium Temperature", "checks if fan is switched on when it's hot enough" do
	# setup
	mock_temperature_signal << 65

	# assert
	fan_probe.is_on?
	temperature_alarm_probe.is_reset?
end

test "Fan Test - High Temperature", "checks if fan is switched on when it's very hot and the temperature alarm is also fired" do
	# setup
	mock_temperature_signal << 80
	delay 2.seconds

	# assert
	fan_probe.is_on?
	temperature_alarm_probe.is_set?
end

```

and then inside the terminal:


```
#!bash
ruby minlab my_tests.rb

```

This will run the tests and produce the following output:

```
#!terminal
Fan Test - Low Temperature
Fan Test - Medium Temperature
Fan Test - High Temperature

-----------------------
0 Groups  3 tests
6 Asserts  2.874 Seconds
OK

```

Furthermore, tests can be nested inside groups and have explicit teardowns

```
#!ruby

group "Fan tests" do
	# group setup code goes here

	test "Low Temperature" do
		teardown do
			# the code in this block will be called regardless of the test outcome
		end

		# ...
	end

	test "Medium Temperature" do
		# ...
	end

	test "High Temperature" do
		# ...
	end

	# group teardown code goes here
end
```
