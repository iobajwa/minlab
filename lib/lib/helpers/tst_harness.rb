
class TestHarness
	
	attr_accessor :logger

	def test_value_is_true(name, value)
		raise "Not Implemented!"
	end

	def test_value_is_false(name, value)
		raise "Not Implemented!"
	end

	def test_value_lies_within(name, value, range)
		raise "Not Implemented!"
	end

	def test_value_equal(name, value, expected_value)
		raise "Not Implemented!"
	end

	def test_value_not_equal(name, value, reference)
	end

	def test_value_less_than_equals(name, value, reference)
		raise "Not Implemented!"
	end

	def test_value_greater_than_equals(name, value, reference)
		raise "Not Implemented!"
	end
end

TestHarness.new logger