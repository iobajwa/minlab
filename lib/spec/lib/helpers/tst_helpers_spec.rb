
require "spec_helper"
require "helpers\\tst_helpers"

describe Scale do
	describe "when converting a value from one scale to another, should return correct results when" do
		it "passed value is less than min" do
			result = Scale.convert 49, 50..100, 0..1000
			result.should be == 0
		end
		it "passed value is equal to min" do
			result = Scale.convert 50, 50..100, 0..1000
			result.should be == 0
		end
		it "passed value is greater than max" do
			result = Scale.convert 101, 50..100, 0..1000
			result.should be == 1000
		end
		it "passed value is equal to max" do
			result = Scale.convert 100, 50..100, 0..1000
			result.should be == 1000
		end
		it "both scales (to, from) are 0 based" do
			result = Scale.convert 23, 0..100, 0..1000
			result.should be == 230
		end
		it "from-scale is 0 based and to-scale is non-zero based" do
			result = Scale.convert 23, 0..100, 100..1000
			result.should be == 307
		end
		it "from-scale is non-0 based and to-scale is 0 based" do
			result = Scale.convert 75, 50..100, 0..100
			result.should be == 50
		end
		it "both scales (to, from) are non-0 based" do
			result = Scale.convert 150, 100..200, 1000..4000
			result.should be == 2500
		end
		it "either scale is negative based" do
			result = Scale.convert -150, -200..-100, 1000..4000
			result.should be == 2500
		end
		it "when scales presented are inverted" do
			result = Scale.convert 50, 100..0, 0..1000
			result.should be == 500

			result = Scale.convert 50, 100..0, 1000..0
			result.should be == 500
		end
	end

	describe "when converting a given value to percentage, should correct result when" do
		it "value is less than scale.min" do
			Scale.convert_percent(10, 20..400).should be == 0
		end
	end
end
