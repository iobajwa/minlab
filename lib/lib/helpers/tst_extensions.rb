
require_relative "tst_helpers"


class DigitalInputPin
	########### injected tests

	def is_set
		read_value = read()
		$assert.is_set @name, read_value
	end
	[
	  :should_be_set, :should_be_true,
	  :is_set?, :set?, 
	  :is_true?, :true?, 
	  :must_be_set, :must_be_true,
	].each {  |a| alias_method a, :is_set }

	def is_high
		read_value = read()
		$assert.is_high @name, read_value
	end
	[ :high?, :is_high?, :must_be_high, :should_be_high ].each {  |a| alias_method a, :is_high }

	def is_low
		read_value = read()
		$assert.is_low @name, read_value
	end
	[ :low?, :is_low?, :must_be_low, :should_be_low ].each {  |a| alias_method a, :is_low }

	def is_on
		$assert.is_on @name, state, @active_high
	end
	[ :should_be_on, :is_on?, :on?, :must_be_on ].each {  |a| alias_method a, :is_on }

	def is_off
		$assert.is_off @name, state, @active_high
	end
	[ :should_be_off, :is_off?, :off?, :must_be_off ].each {  |a| alias_method a, :is_off }


	def is_reset
		read_value = read()
		$assert.is_reset @name, read_value
	end
	[
	  :is_reset?, :reset?, 
	  :is_false?, :false?,
	  :should_be_false, :should_be_reset,
	  :must_be_false, :must_be_reset,
	].each {  |a| alias_method a, :is_reset }
end




class AnalogInputPin
	def lies_within? specified_range
		read_value = read
		$assert.value_lies_within @name, read_value, specified_range
	end
	[ :should_be_within, :must_lie_within, :should_lie_within ].each {  |a| alias_method a, :lies_within? }

	def lies_outside? specified_range
		read_value = read
		$assert.value_lies_outside @name, read_value, specified_range
	end
	[ :should_be_outside, :must_lie_outside, :should_lie_outside ].each {  |a| alias_method a, :lies_outside? }

	def > reference
		read_value = read
		$assert.value_greater_than @name, read_value, reference
	end
	[ :should_be_greater_than?, :should_be_greater_than, :must_be_greater_than?, :must_be_greater_than, ].each {  |a| alias_method a, :> }


	def < reference
		read_value = read()
		$assert.value_less_than @name, read_value, reference
	end
	[ :should_be_less_than?, :should_be_less_than, :must_be_less_than?, :must_be_less_than, ].each {  |a| alias_method a, :< }

	def >= reference
		read_value = read
		$assert.value_greater_than_equals @name, read_value, reference
	end
	[ :should_be_greater_than_equals_to?, :should_be_greater_than_equals_to, 
	  :must_be_greater_than_equals_to?, :must_be_greater_than_equals_to, ].each {  |a| alias_method a, :>= }

	def <= reference
		read_value = read()
		$assert.value_less_than_equals @name, read_value, reference
	end
	[ :should_be_less_than_equals_to?, :should_be_less_than_equals_to, 
	  :must_be_less_than_equals_to?, :must_be_less_than_equals_to, ].each {  |a| alias_method a, :<= }


	def is? expected_value
		read_value = read()
		$assert.value_equal @name, read_value, expected_value
	end
	[
		:should_be_equal_to, :should_equals_to, :should_equal_to, :should_be,
		:must_be_equal_to,   :must_equals_to,   :must_equal_to,   :must_be,
	].each {  |a| alias_method a, :is? }

	
	# should_be_zero
	def is_zero?
		return is? @end_scale.first
	end
	[
		:must_be_zero,   :must_be_zero_scale,   :must_be_minimum,   :must_be_min,
		:should_be_zero_scale, :should_be_minimum, :should_be_min, :should_be_zero
	].each {  |a| alias_method a, :is_zero? }


	# tests if the current value on the pin is almost 0 (0 +- 1% full scale error)
	def is_almost_zero? tolerance=10.0
		read_value = read()
		percent_of_full_scale = Scale.convert_percent read_value, @end_scale
		
		$assert.value_less_than_equals @name, tolerance, percent_of_full_scale
	end
	[
		:should_be_almost_zero, :should_be_almost_zero_scale, :should_be_almost_minimum, :should_be_almost_min,
		:must_be_almost_zero,   :must_be_almost_zero_scale,   :must_be_almost_minimum,   :must_be_almost_min,
	].each {  |a| alias_method a, :is_almost_zero? }


	# tests if the current value on the pin is absolutely full (full scale maximum).
	def is_full?
		should_be @end_scale.last
	end
	[
		:must_be_full,   :must_be_full_scale,   :must_be_maximum,   :must_be_max,
		:should_be_full, :should_be_full_scale, :should_be_maximum, :should_be_max,
	].each {  |a| alias_method a, :is_full? }


	# tests if the current value on the pin is almost full (full scale +- 1% error)
	def is_almost_full? tolerance=90.0
		read_value = read()
		percent_of_full_scale = Scale.convert_percent read_value, @end_scale
		
		$assert.value_greater_than_equals @name, tolerance, percent_of_full_scale
	end
	[
		:must_be_almost_full,    :must_be_almost_full_scale,    :must_be_almost_maximum,    :must_be_almost_max,
		:shouuld_be_almost_full, :shouuld_be_almost_full_scale, :shouuld_be_almost_maximum, :shouuld_be_almost_max,
	].each {  |a| alias_method a, :is_almost_full? }
end




class Fixnum
	########### injected helpers 

	def ms
		return self * 1.0 / 1000
	end
	[ :millis, :milliseconds, :mseconds, :milli_seconds ].each {  |a| alias_method a, :ms }

	def seconds
		return self
	end
	alias_method :second, :seconds

	def minutes
		return self * 60
	end
	alias_method :minute, :minutes
end



class Float
	########### injected helpers

	def ms
		return self / 1000
	end
	[ :millis, :milliseconds, :mseconds, :milli_seconds ].each {  |a| alias_method a, :ms }

	def seconds
		return self
	end
	alias_method :second, :seconds

	def minutes
		return self * 60
	end
	alias_method :minute, :minutes
end
