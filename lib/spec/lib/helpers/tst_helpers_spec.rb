
require "spec_helper"
$cli_options = {}
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
		describe "when scales presented are inverted- " do
			it "from is inverted" do
				result = Scale.convert 25, 100..0, 0..1000
				result.should be == 750
			end
			it "to is inverted" do
				result = Scale.convert 25, 0..100, 1000..0
				result.should be == 750
			end

			it "from & to, booth are inverted" do
				result = Scale.convert 25, 100..0, 1000..0
				result.should be == 250
			end
		end
	end

	describe "when converting a given value to percentage, should correct result when" do
		it "value is less than scale.min" do
			Scale.convert_percent(10, 20..400).should be == 0.0
		end
		it "value is greater than scale.max" do
			Scale.convert_percent(200, 0..100).should be == 200
		end
		it "value lies in between" do
			Scale.convert_percent(135, 100..200).should be == 35.0
		end
	end
end

describe OptionMaker do
	describe "when parsing options from the passed string, returns correct options when" do
		it "a simple flag is passed" do
			options, files = OptionMaker.parse "--flag"
			files.should be_empty
			options.should be == { :flag => nil }
		end
		it "multiple flags are passed" do
			options, files = OptionMaker.parse ["--flag1", "-- flag2", "  -- flag3  "]
			files.should be_empty
			options.should be == { :flag1 => nil, :flag2 => nil, :flag3 => nil }
		end
		it "single key-value is provided" do
			options, files = OptionMaker.parse ["--key=value"]
			files.should be_empty
			options.should be == { :key => "value" }
		end
		it "single key-value is provided with multiple values" do
			options, files = OptionMaker.parse ["--key=v1;v2"]
			files.should be_empty
			options.should be == { :key => ["v1", "v2"] }
		end
		it "multiple key-values are provided with multiple values" do
			options, files = OptionMaker.parse ["--k1=v1;", " -- k2 = v2  ; v3; ", "  -- k3 = v4 ;  "]
			files.should be_empty
			options.should be == { :k1 => "v1", :k2 => [ "v2", "v3" ], :k3 => "v4" }
		end
	end
end

describe "get_config" do
	it "raises exception when no matching option found" do
		expect { get_config 'Blah' }.to raise_exception("'Blah' is not defined.")
	end

	it "returns found entry from $cli_options upon a match" do
		$cli_options = { :WHAT? => 1, :BLAH => 2 }
		get_config('blah').should be == 2
	end

	it "returns found entry from ENV upon a match" do
		$cli_options = { :WHAT? => 1, :BLAH2 => 2 }
		ENV["haha"] = "3"
		ENV["bLAH"] = "4"
		get_config('blah').should be == "4"
	end
end

