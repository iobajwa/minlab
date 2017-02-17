
require "spec_helper"
require "helpers\\pins"
$test_harness = []
require "helpers\\tst_extensions"

describe "DigitalPin - Extended" do
	before(:each) do
		$pin = DigitalPin.new 'p', 23, :di, "r"
	end
	it "should_be_set" do
		expect($pin).to receive(:read).and_return("result")
		expect($test_harness).to receive(:test_value_is_true).with('p', "result")
		
		$pin.should_be_set
	end
	it "should_be_reset" do
		expect($pin).to receive(:read).and_return(:result)
		expect($test_harness).to receive(:test_value_is_false).with('p', :result)
		
		$pin.should_be_reset
	end
end

describe "AnalogPin - Extended" do
	before(:each) do
		$pin = AnalogPin.new 'p', 23, :di, "r", 50..100
	end
	it "should_lie_within" do
		expect($pin).to receive(:read).and_return("result")
		expect($test_harness).to receive(:test_value_lies_within).with('p', "result", 0..230)
		
		$pin.should_lie_within 0..230
	end
	it "should_be" do
		expect($pin).to receive(:read).and_return("result")
		expect($test_harness).to receive(:test_value_equal).with('p', "result", 250)
		
		$pin.should_be 250
	end
	it "should_be_zero" do
		expect($pin).to receive(:should_be).with(50)
		$pin.should_be_zero
	end
	it "should_be_almost_zero" do
		expect($pin).to receive(:read).and_return(75)
		expect(Scale).to receive(:convert_percent).with(75, 50..100).and_return(75.0)
		expect($test_harness).to receive(:test_value_less_than_equals).with('p', 1.0, 75.0)
		
		$pin.should_be_almost_zero
	end
	it "should_be_full" do
		expect($pin).to receive(:should_be).with(100)
		$pin.should_be_full
	end
	it "should_be_almost_full" do
		expect($pin).to receive(:read).and_return(23)
		expect(Scale).to receive(:convert_percent).with(23, 50..100).and_return(23.0)
		expect($test_harness).to receive(:test_value_greater_than_equals).with('p', 99.0, 23.0)
		
		$pin.should_be_almost_full
	end
end

describe "Fixnum - Extended" do
	it "ms" do
		3.ms.should be == 0.003
	end
	it "seconds" do
		3.seconds.should be == 3
		1.second.should be == 1
	end
	it "minutes" do
		3.minutes.should be == 180
		1.minute.should be == 60
	end
end

describe "Float - Extended" do
	it "ms" do
		35.6.ms.should be == 0.0356
	end
	it "seconds" do
		3.5.seconds.should be == 3.5
	end
	it "minutes" do
		2.5.minutes.should be == 150
	end
end
