
tests << Test.new( "Fan Test", "checks if fan circuit is functional",
				    lamda {
						mock_fan_signal.set
						delay 1.second

						fan_probe.is_set?
				   	},
				   	nil,
				   	nil,
				   	{ :repeat => 3.times }
				 )

led_tests = []
led_tests << Test.new( "Red LED Test", "checks if red led circuit is functional",
					lambda {
						mock_red_led_signal.switch_on

						red_led_probe.is_on?
					}
				)

scr_test = Test.new( "SCR Test", "checks if scr circuit is functional",
				   lambda {
						mock_scr_signal.switch_on
						scr_probe.is_on?

						mock_scr_signal.switch_off
						scr_probe.is_off?
				   	}
				 )

volt_test << Test.new( "Volt Test", "checks if voltage sensing circuit is functional",
				   lambda {
						volts_probe.lies_within? 200..260
				   	}
				 )

fixture = Fixture.new( "voltman-pcb-unit-testing", "unit tests the voltman pcb",
					   tests, nil, nil,
					   { :repeat => 10.times }
				 )

test_groups = [ led_tests, scr_test ]