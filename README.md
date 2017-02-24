# *minilab* #

A PCB unit-testing framework. The firmware runs on an Arduino Mega and acts as an interface between the PCB and tests using a custom protocol on UART0. The tests are written in a ruby based DSL which provides high level asserts and helper functions along with a test runner.

### Quick overview ###

Simply create a new test file which describes the tests to perform and execute those with minilab.
```
#!ruby

# create boards
arduino = Board.new 'arduino', MinilabProtocol
pcb     = Board.new 'pcb',     UProtoProtocol, { :gateway => arduino, :port => 1, :baud => 57600 }


# mention connections- what is connected where

#    board     pin_name                 pin_number, pin_type, meta    
wire arduino, 'mock_temperature_signal', 3,         :ao,      { :raw_scale => 0..255, :end_scale => 0..100 }
wire arduino, 'fan_probe',               34,        :di,      :active_low
wire arduino, 'temperature_alarm_probe', 35,        :di


# write tests
fan_tests = []
fan_tests << Test.new( "Fan Test - Low Temperature", "checks if fan is switched off when temperature is below the threshold value", 
					Proc.new {    # execution
						# setup
						mock_temperature_signal << 50

						# assert
						fan_probe.is_off?
						temperature_alarm_probe.is_reset?
					})

fan_tests << Test.new( "Fan Test - Medium Temperature", "checks if fan is switched on when it's hot enough", 
					Proc.new {    # execution
						# setup
						mock_temperature_signal << 65

						# assert
						fan_probe.is_on?
						temperature_alarm_probe.is_reset?
					})

fan_tests << Test.new( "Fan Test - High Temperature", "checks if fan is switched on when it's very hot and the temperature alarm is also fired", 
					Proc.new {    # execution
						# setup
						mock_temperature_signal << 80
						delay 2.seconds

						# assert
						fan_probe.is_on?
						temperature_alarm_probe.is_set?
					})


# register the tests with the test runner
register_tests fan_test


```

and then inside the terminal:


```
#!bash
ruby minilab my_tests.rb

```

This will run the tests and produce the following output:

```
#!terminal
Fan Test - Low Temperature    : OK
Fan Test - Medium Temperature : OK
Fan Test - High Temperature   : OK

-----------------------
0 Groups  3 tests
6 Asserts  2.874 Seconds
OK

```