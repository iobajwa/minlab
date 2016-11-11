
[ 
	"tst_helpers",
].each {|req| require "#{File.expand_path(File.dirname(__FILE__))}/#{req}"}


class DigitalPin
	########### injected tests

	def should_be_set
		read_value = read()
		$test_harness.test_value_is_true @name, read_value
	end
	[
	  :is_set?, :set?, 
	  :is_true?, :true?, 
	  :is_high, :high?,
	  :should_be_true, :should_be_high,
	  :must_be_set, :must_be_true, :must_be_high,
	].each {  |a| alias_method a, :should_be_set }


	def should_be_reset
		read_value = read()
		$test_harness.test_value_is_false @name, read_value
	end
	[
	  :is_reset?, :reset?, 
	  :is_false?, :false?, 
	  :is_low, :low?,
	  :should_be_false, :should_be_low,
	  :must_be_reset, :must_be_false, :must_be_low,
	].each {  |a| alias_method a, :should_be_reset }

end


class AnalogPin
	########### injected tests 

	# tests if the current value on the pin lies within the specified range
	def should_lie_within(specified_range)
		read_value = read()
		$test_harness.test_value_lies_within @name, read_value, specified_range
	end
	[:lies_within?, :is_within?, :should_be_within, :within?].each {  |a| alias_method a, :should_lie_within }


	# tests if the current value on the pin is exeactly equal 
	def should_be(expected_value)
		read_value = read()
		$test_harness.test_value_equal @name, read_value, expected_value
	end
	[
		:should_be_equal_to, :equals_to?, :is_equals_to?,
		:is_equal_to?,       :equals?,    :is_equals?,
		:is,                 :reads
	].each {  |a| alias_method a, :should_be }

	# tests if the current value on the pin is absolutely 0 (full scale 0).
	def should_be_zero
		should_be @end_scale.first
	end
	[
		:is_zero?,       :zero?,       :must_be_zero,
		:is_zero_scale?, :zero_scale?, :must_be_zero_scale,
		:is_minimum?,    :minimum?,    :must_be_minimum,
		:is_min?,        :min?,        :must_be_min,
	].each {  |a| alias_method a, :should_be_zero }


	# tests if the current value on the pin is almost 0 (0 +- 1% full scale error)
	def should_be_almost_zero
		read_value = read()
		percent_of_full_scale = Scale.convert_percent read_value, @end_scale
		
		$test_harness.test_value_less_than_equals @name, 1.0, percent_of_full_scale
	end
	[
		:is_almost_zero?,       :almost_zero?,       :must_be_almost_zero,
		:is_almost_zero_scale?, :almost_zero_scale?, :must_be_almost_zero_scale,
		:is_almost_minimum?,    :almost_minimum?,    :must_be_almost_minimum,
		:is_almost_min?,        :almost_min?,        :must_be_almost_min,
	].each {  |a| alias_method a, :should_be_almost_zero }


	# tests if the current value on the pin is absolutely full (full scale maximum).
	def should_be_full
		should_be @end_scale.last
	end
	[
		:is_full?,       :full?,       :must_be_full,
		:is_full_scale?, :full_scale?, :must_be_full_scale,
		:is_maximum?,    :maximum?,    :must_be_maximum,
		:is_max?,        :max?,        :must_be_max,
	].each {  |a| alias_method a, :should_be_full }


	# tests if the current value on the pin is almost full (full scale +- 1% error)
	def should_be_almost_full
		read_value = read()
		percent_of_full_scale = Scale.convert_percent read_value, @end_scale
		
		$test_harness.test_value_greater_than_equals @name, 99.0, percent_of_full_scale
	end
	[
		:is_almost_full?,       :almost_full?,       :must_be_almost_full,
		:is_almost_full_scale?, :almost_full_scale?, :must_be_almost_full_scale,
		:is_almost_maximum?,    :almost_maximum?,    :must_be_almost_maximum,
		:is_almost_max?,        :almost_max?,        :must_be_almost_max,
	].each {  |a| alias_method a, :should_be_almost_full }
end
