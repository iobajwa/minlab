
require_relative "tst_base.rb"

class TestAssert
	attr_accessor :silent

	@assert_count

	def initialize
		@assert_count = 0
		@silent = false
	end

	def assert_count
		@assert_count
	end

	def binary_to_bool(value)
		value = value == 0 ? false : true if value.class == Fixnum
		return value
	end
	
	def is_true(name, value)
		@assert_count += 1
		value = binary_to_bool value
		value_equal name, value, true
	end

	def is_false(name, value)
		@assert_count += 1
		value = binary_to_bool value
		value_equal name, value, false
	end

	def is_on(name, value, active_high=true)
		@assert_count += 1
		value = binary_to_bool value
		passed_value = value
		active_high = false if active_high == :active_low
		active_high = true  if active_high == :active_high

		value = !value unless active_high
		return true if value == true
		return false if @silent
		raise TestFailureEx.new "'#{name}': expected 'on', was 'off' ('#{passed_value}')"
	end

	def is_off(name, value, active_high=true)
		@assert_count += 1
		value = binary_to_bool value
		passed_value = value
		active_high = false if active_high == :active_low
		active_high = true  if active_high == :active_high

		value = !value unless active_high
		return true if value == false
		return false if @silent
		raise TestFailureEx.new "'#{name}': expected 'off', was 'on' ('#{passed_value}')"
	end

	def is_set(name, value)
		@assert_count += 1
		value = binary_to_bool value
		return true if value == true
		return false if @silent
		raise TestFailureEx.new "'#{name}': expected 'set', was 'reset' ('#{value}')"
	end

	def is_reset(name, value)
		@assert_count += 1
		value = binary_to_bool value
		return true if value == false
		return false if @silent
		raise TestFailureEx.new "'#{name}': expected 'reset', was 'set' ('#{value}')"
	end

	def is_high(name, value)
		@assert_count += 1
		value = binary_to_bool value
		return true if value == true
		return false if @silent
		raise TestFailureEx.new "'#{name}': expected 'high', was 'low' ('#{value}')"
	end

	def is_low(name, value)
		@assert_count += 1
		value = binary_to_bool value
		return true if value == false
		return false if @silent
		raise TestFailureEx.new "'#{name}': expected 'low', was 'high' ('#{value}')"
	end

	def value_equal(name, value, expected_value)
		@assert_count += 1
		return true if value == expected_value
		return false if @silent
		raise TestFailureEx.new "'#{name}': expected '#{expected_value}', was '#{value}'"
	end
	alias_method :value_equals, :value_equal


	def value_not_equal(name, value, reference)
		@assert_count += 1
		return true if value != reference
		return false if @silent
		raise TestFailureEx.new "'#{name}': expected not '#{value}'"
	end
	alias_method :value_not_equals, :value_not_equal

	def value_less_than_equals(name, value, reference)
		@assert_count += 1
		begin
			return true if value <= reference
		rescue => ex
			raise "'#{name}': #{ex.message}, (value '#{value}', reference '#{reference}'"
		end
		return false if @silent
		raise TestFailureEx.new "'#{name}': expected <= '#{reference}', was '#{value}'"
	end

	def value_greater_than_equals(name, value, reference)
		@assert_count += 1
		begin
			return true if value >= reference
		rescue => ex
			raise "'#{name}': #{ex.message}, (value '#{value}', reference '#{reference}'"
		end
		return false if @silent
		raise TestFailureEx.new "'#{name}': expected >= '#{reference}', was '#{value}'"
	end

	def value_less_than(name, value, reference)
		@assert_count += 1
		begin
			return true if value < reference
		rescue => ex
			raise "'#{name}': #{ex.message}, (value '#{value}', reference '#{reference}'"
		end
		return false if @silent
		raise TestFailureEx.new "'#{name}': expected < '#{reference}', was '#{value}'"
	end

	def value_greater_than(name, value, reference)
		@assert_count += 1
		begin
			return true if value > reference
		rescue => ex
			raise "'#{name}': #{ex.message}, (value '#{value}', reference '#{reference}'"
		end
		return false if @silent
		raise TestFailureEx.new "'#{name}': expected > '#{reference}', was '#{value}'"
	end

	def value_lies_within(name, value, range)
		@assert_count += 1
		raise FatalEx.new "'#{name}': value_lies_within- expected Range, received '#{range}' (type '#{range.class}')" unless range.class == Range
		return true if range.include? value
		return false if @silent
		raise TestFailureEx.new "'#{name}': value ('#{value}') lies outside of specified range ('#{range}')"
	end

	def value_lies_outside(name, value, range)
		@assert_count += 1
		raise FatalEx.new "'#{name}': value_lies_outside- expected Range, received '#{range}' (type '#{range.class}')" unless range.class == Range
		return true unless range.include? value
		return false if @silent
		raise TestFailureEx.new "'#{name}': value ('#{value}') lies within the specified range ('#{range}')"
	end

	def fail(message)
		raise TestFailureEx.new message
	end
end
