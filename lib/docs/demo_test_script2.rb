
ping_test = Test.new( "pcb ping", "checks if pcb is alive",
						Proc.new {
							2.times {
								pcb.ping
								delay 1.second
								pcb.ping
								delay 1.second
							}
						}
					)

# fan
fan_toggle = Test.new( "Fan toggle", "checks if fan circuit is functional",
						Proc.new { 
							mock_fan_signal.switch_on
							delay 100.ms
							fan_probe.is_almost_full?
						}
					 )

scr_toggle = Test.new( "SCR toggle", "checks if scr circuit is functional",
						Proc.new {
							mock_scr_signal.switch_on
							delay 250.second
							scr_probe.is_high?

							mock_scr_signal.switch_off
							delay 250.second
							scr_probe.is_low?
						}
					 )

adc_tests = []
adc_tests << Test.new( "volts", "checks if volts is being sensed properly",
						Proc.new {
							volts_probe.is_within? 80..110
						}
					 )
adc_tests << Test.new( "amps", "checks if amps is being sensed properly",
						Proc.new {
							mock_amps_signal << 0
							amps_probe.is_almost_empty?

							mock_amps_signal << 50
							delay 200.ms
							amps_probe.is_within? 45..55

							mock_amps_signal << 90
							delay 200.ms
							amps_probe.is_within? 80..100
						}
					  )
adc_tests << Test.new( "temps", "checks if temps is being sensed properly",
						Proc.new {
							mock_temps_signal << 0
							temps_probe.is_almost_empty?

							mock_temps_signal << 50
							delay 200.ms
							temps_probe.is_within? 45..55

							mock_temps_signal << 90
							delay 200.ms
							temps_probe.is_within? 80..100
						}
					  )


# leds
led_tests = []
led_tests << Test.new( "red LED toggle", "checks if red led circuit is functional",
						Proc.new {
							mock_red_led_signal.switch_on
							red_led_probe.is_on?
							mock_red_led_signal.switch_off
							red_led_probe.is_off?
						}
					 )
led_tests << Test.new( "yellow LED toggle", "checks if yellow led circuit is functional",
						Proc.new {
							mock_yellow_led_signal.switch_on
							yellow_led_probe.is_on?
							mock_yellow_led_signal.switch_off
							yellow_led_probe.is_off?
						}
					 )

led_tests << Test.new( "blue LED toggle", "checks if blue led circuit is functional",
						Proc.new {
							mock_blue_led_signal.switch_on
							blue_led_probe.is_on?
							mock_blue_led_signal.switch_off
							blue_led_probe.is_off?
						}
					 )

led_tests << Test.new( "white LED toggle", "checks if white led circuit is functional",
						Proc.new {
							mock_white_led_signal.switch_on
							white_led_probe.is_on?
							mock_white_led_signal.switch_off
							white_led_probe.is_off?
						}
					 )

led_tests << Test.new( "green LED toggle", "checks if green led circuit is functional",
						Proc.new {
							mock_green_led_signal.switch_on
							green_led_probe.is_on?
							mock_green_led_signal.switch_off
							green_led_probe.is_off?
						}
					 )

leds_tests_group = TestGroup.new "LED tests", "checks if leds are functional", led_tests
adc_tests_group  = TestGroup.new "ADC tests", "checks if adcs are functional", adc_tests
scr_tests_group  = TestGroup.new "SCR tests", "checks if scr is functional",   scr_toggle
fan_tests_group  = TestGroup.new "Fan tests", "checks if fan is functional",   fan_toggle

normal_tests = TestGroup.new( "pcb functional tests", "checks if pcb is fully functional", 
							  [ leds_tests_group, scr_tests_group, scr_tests_group, fan_tests_group ],
							  Proc.new {
							  	  # operate in 240 volts
							      relay1.switch_on
							      relay2.switch_on
							      relay3.switch_off
							      relay4.switch_off
							      relay5.switch_off
							  },
							  nil, { :each_test_repeat_count => 10 }
							)

lv_tests_group = TestGroup.new( "low voltage operation", "checks if pcb remains functional even in low voltage",
								ping_test,
								Proc.new {
									# operate in 110 volts
									relay1.switch_on
									relay2.switch_off
									relay3.switch_off
									relay4.switch_off
									relay5.switch_off
								},
								Proc.new {
									# reset to 220 volts
									relay1.switch_on
									relay2.switch_on
									relay3.switch_off
									relay4.switch_off
									relay5.switch_off
								}
								 )

hv_tests_group = TestGroup.new( "high voltage operation", "checks if pcb remains functional even in high voltage",
								ping_test,
								Proc.new {
									# operate in 550 volts
									relay1.switch_on
									relay2.switch_on
									relay3.switch_on
									relay4.switch_on
									relay5.switch_on
								},
								Proc.new {
									# reset to 220 volts
									relay1.switch_on
									relay2.switch_on
									relay3.switch_off
									relay4.switch_off
									relay5.switch_off
								}
							 )


tests = [ 
			leds_tests_group, 
			adc_tests_group, 
			scr_tests_group, 
			fan_tests_group, 
			lv_tests_group, 
			hv_tests_group,
		]
