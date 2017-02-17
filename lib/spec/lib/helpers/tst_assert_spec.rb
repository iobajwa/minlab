
require "spec_helper"
require "helpers\\tst_assert"

describe "when performing" do
	before(:each) do
		$assert = TestAssert.new
	end
	describe "is_true" do
		it "returns true when test passes" do
			result = $assert.is_true 'something', true
			result.should be true
		end
		it "raises TestFailureEx when passed value is false" do
			expect { $assert.is_true 'something', false }.to raise_exception(TestFailureEx, "'something': expected 'true', was 'false'")
		end
		it "raises TestFailureEx when passed value is of neither TrueClass or FalseClass" do
			expect { $assert.is_true 'something', 'value' }.to raise_exception(TestFailureEx, "'something': expected 'true', was 'value'")
		end
	end

	describe "is_false" do
		it "returns true when test passes" do
			result = $assert.is_false 'something', false
			result.should be true
		end
		it "raises TestFailureEx when passed value is true" do
			expect { $assert.is_false 'something', true }.to raise_exception(TestFailureEx, "'something': expected 'false', was 'true'")
		end
		it "raises TestFailureEx when passed value is of neither TrueClass or FalseClass" do
			expect { $assert.is_false 'something', 'value' }.to raise_exception(TestFailureEx, "'something': expected 'false', was 'value'")
		end
	end
	
	describe "value_equal" do
		it "returns true when test passes" do
			result = $assert.value_equal 'something', 3, 3
			result.should be true
		end
		it "raises TestFailureEx when passed value not equal" do
			expect { $assert.value_equal 'something', 3, 4 }.to raise_exception(TestFailureEx, "'something': expected '4', was '3'")
			expect { $assert.value_equal 'something', 'value', 'Value' }.to raise_exception(TestFailureEx, "'something': expected 'Value', was 'value'")
			expect { $assert.value_equal 'something', 3, 'Value' }.to raise_exception(TestFailureEx, "'something': expected 'Value', was '3'")
			expect { $assert.value_equal 'something', nil, true }.to raise_exception(TestFailureEx, "'something': expected 'true', was ''")
		end
	end

	describe "value_not_equal" do
		it "returns true when test passes" do
			result = $assert.value_not_equal 'something', 3, 4
			result.should be true
			result = $assert.value_not_equal 'something', true, false
			result.should be true
			result = $assert.value_not_equal 'something', true, nil
			result.should be true
			result = $assert.value_not_equal 'something', false, nil
			result.should be true
			result = $assert.value_not_equal 'something', 'a', 'b'
			result.should be true
			result = $assert.value_not_equal 'something', 'a', true
			result.should be true
		end
		it "raises TestFailureEx when passed value is equal" do
			expect { $assert.value_not_equal 'something', 3, 3 }.to raise_exception(TestFailureEx, "'something': expected not '3'")
			expect { $assert.value_not_equal 'something', 'string', 'string' }.to raise_exception(TestFailureEx, "'something': expected not 'string'")
			expect { $assert.value_not_equal 'something', nil, nil }.to raise_exception(TestFailureEx, "'something': expected not ''")
		end
	end

	describe "value_less_than_equals" do
		it "returns true when test passes" do
			result = $assert.value_less_than_equals 'something', 3, 4
			result.should be true
			result = $assert.value_less_than_equals 'something', 4, 4
			result.should be true
		end
		it "raises TestFailureEx when passed value is not less than or equals" do
			expect { $assert.value_less_than_equals 'something', 5, 4 }.to raise_exception(TestFailureEx, "'something': expected <= '4', was '5'")
		end
		it "raises exception when passed values cannot be compared" do
			expect { $assert.value_less_than_equals 'something', 5, 'something' }.to raise_exception("'something': comparison of Fixnum with String failed, (value '5', reference 'something'")
		end
	end

	describe "value_greater_than_equals" do
		it "returns true when test passes" do
			result = $assert.value_greater_than_equals 'something', 5, 4
			result.should be true
			result = $assert.value_greater_than_equals 'something', 4, 4
			result.should be true
		end
		it "raises TestFailureEx when passed value is not less than or equals" do
			expect { $assert.value_greater_than_equals 'something', 3, 4 }.to raise_exception(TestFailureEx, "'something': expected >= '4', was '3'")
		end
		it "raises exception when passed values cannot be compared" do
			expect { $assert.value_greater_than_equals 'something', 5, 'something' }.to raise_exception("'something': comparison of Fixnum with String failed, (value '5', reference 'something'")
		end
	end

	describe "value_less_than" do
		it "returns true when test passes" do
			result = $assert.value_less_than 'something', 3, 4
			result.should be true
		end
		it "raises TestFailureEx when passed value is not less than" do
			expect { $assert.value_less_than 'something', 4, 4 }.to raise_exception(TestFailureEx, "'something': expected < '4', was '4'")
			expect { $assert.value_less_than 'something', 5, 4 }.to raise_exception(TestFailureEx, "'something': expected < '4', was '5'")
		end
		it "raises exception when passed values cannot be compared" do
			expect { $assert.value_less_than 'something', 5, 'something' }.to raise_exception("'something': comparison of Fixnum with String failed, (value '5', reference 'something'")
		end
	end

	describe "value_greater_than" do
		it "returns true when test passes" do
			result = $assert.value_greater_than 'something', 3, 2
			result.should be true
		end
		it "raises TestFailureEx when passed value is not less than" do
			expect { $assert.value_greater_than 'something', 2, 2 }.to raise_exception(TestFailureEx, "'something': expected > '2', was '2'")
			expect { $assert.value_greater_than 'something', 1, 2 }.to raise_exception(TestFailureEx, "'something': expected > '2', was '1'")
		end
		it "raises exception when passed values cannot be compared" do
			expect { $assert.value_greater_than 'something', 5, 'something' }.to raise_exception("'something': comparison of Fixnum with String failed, (value '5', reference 'something'")
		end
	end

	describe "value_lies_within" do
		it "returns true when test passes" do
			result = $assert.value_lies_within 'something', 3, 0..5
			result.should be true
			result = $assert.value_lies_within 'something', 0, 0..5
			result.should be true
			result = $assert.value_lies_within 'something', 5, 0..5
			result.should be true
		end
		it "raises TestFailureEx when passed value lies outside" do
			expect { $assert.value_lies_within 'something', 6, 0..5 }.to raise_exception(TestFailureEx, "'something': value ('6') lies outside of specified range ('0..5')")
			expect { $assert.value_lies_within 'something', 1, 2..5 }.to raise_exception(TestFailureEx, "'something': value ('1') lies outside of specified range ('2..5')")
			expect { $assert.value_lies_within 'something', 'blah', 2..5 }.to raise_exception(TestFailureEx, "'something': value ('blah') lies outside of specified range ('2..5')")
		end
		it "raises FatalEx when passed reference isn't a range" do
			expect { $assert.value_lies_within 'something', 5, 'something' }.to raise_exception(FatalEx, "'something': value_lies_within- expected Range, received 'something' (type 'String')")
		end
	end

	describe "value_lies_outside" do
		it "returns true when test passes" do
			result = $assert.value_lies_outside 'something', 1, 2..5
			result.should be true
		end
		it "raises TestFailureEx when passed value lies inside" do
			expect { $assert.value_lies_outside 'something', 0, 0..5 }.to raise_exception(TestFailureEx, "'something': value ('0') lies within the specified range ('0..5')")
			expect { $assert.value_lies_outside 'something', 2, 0..5 }.to raise_exception(TestFailureEx, "'something': value ('2') lies within the specified range ('0..5')")
			expect { $assert.value_lies_outside 'something', 5, 0..5 }.to raise_exception(TestFailureEx, "'something': value ('5') lies within the specified range ('0..5')")
		end
		it "raises FatalEx when passed reference isn't a range" do
			expect { $assert.value_lies_outside 'something', 5, 'something' }.to raise_exception(FatalEx, "'something': value_lies_outside- expected Range, received 'something' (type 'String')")
		end
	end

	it "fail, raises TestFailureEx exception with the passed message" do
		expect { $assert.fail 'message' }.to raise_exception(TestFailureEx, "message")
	end

	describe "is_on" do
		describe "when active high" do
			it "returns true when signal is true" do
				result = $assert.is_on "something", true
				result.should be true
			end
			it "raises TestFailureEx when signal is false" do
				expect { $assert.is_on "something", false }. to raise_exception(TestFailureEx, "'something': expected 'on', was 'off' ('false')")
			end
		end
		describe "when active low" do
			it "returns true when signal is false" do
				result = $assert.is_on "something", false, :active_low
				result.should be true
			end
			it "raises TestFailureEx when signal is true" do
				expect { $assert.is_on "something", true, :active_low }. to raise_exception(TestFailureEx, "'something': expected 'on', was 'off' ('true')")
			end
		end
	end

	describe "is_off" do
		describe "when active high" do
			it "returns true when signal is false" do
				result = $assert.is_off "something", false
				result.should be true
			end
			it "raises TestFailureEx when signal is true" do
				expect { $assert.is_off "something", true }. to raise_exception(TestFailureEx, "'something': expected 'off', was 'on' ('true')")
			end
		end
		describe "when active low" do
			it "returns true when signal is true" do
				result = $assert.is_off "something", true, :active_low
				result.should be true
			end
			it "raises TestFailureEx when signal is false" do
				expect { $assert.is_off "something", false, :active_low }. to raise_exception(TestFailureEx, "'something': expected 'off', was 'on' ('false')")
			end
		end
	end

	describe "is_set" do
		it "returns true when signal is true" do
			result = $assert.is_set "something", true
			result.should be true
		end
		it "raises TestFailureEx when signal is false" do
			expect { $assert.is_set "something", false }. to raise_exception(TestFailureEx, "'something': expected 'set', was 'reset' ('false')")
		end
	end

	describe "is_reset" do
		it "returns true when signal is false" do
			result = $assert.is_reset "something", false
			result.should be true
		end
		it "raises TestFailureEx when signal is true" do
			expect { $assert.is_reset "something", true }. to raise_exception(TestFailureEx, "'something': expected 'reset', was 'set' ('true')")
		end
	end

	describe "is_high" do
		it "returns true when signal is true" do
			result = $assert.is_high "something", true
			result.should be true
		end
		it "raises TestFailureEx when signal is false" do
			expect { $assert.is_high "something", false }. to raise_exception(TestFailureEx, "'something': expected 'high', was 'low' ('false')")
		end
	end

	describe "is_low" do
		it "returns true when signal is false" do
			result = $assert.is_low "something", false
			result.should be true
		end
		it "raises TestFailureEx when signal is true" do
			expect { $assert.is_low "something", true }. to raise_exception(TestFailureEx, "'something': expected 'low', was 'high' ('true')")
		end
	end
end
