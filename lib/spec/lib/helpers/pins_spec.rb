
require "spec_helper"
require "helpers\\pins"

describe Pin do
	it "when instantiating a pin instance, returns correct instance" do
		p = Pin.new 'p', 23, :type, "rw"
		p.name.should be == 'p'
		p.number.should be == 23
		p.type.should be == :type
		p.permissions.should be == "rw"
	end

	before(:each) do
		$dummy_protocol = []
		$pin = Pin.new 'p', 23, :type, :rw
		$pin.protocol_bridge = $dummy_protocol
	end

	it "when performing a read, should delegate work to the underlying protocol" do
		expect($pin).to receive(:assert_read_access)
		expect($dummy_protocol).to receive(:read_pin).with(23, :type).and_return("result")
		
		$pin.read.should be == "result"
	end

	it "when performing a write, should delegate work to the underlying protocol" do
		expect($pin).to receive(:assert_write_access)
		expect($dummy_protocol).to receive(:write_pin).with(23, :type, 'value')
		
		$pin.write 'value'
	end

	describe "when asserting read access, should" do
		it "return true, when it has valid permissions" do
			$pin.assert_read_access.should be == true
		end
		it "raises exception when it does not have valid permissions" do
			$pin.permissions = "mw"
			expect { $pin.assert_read_access }.to raise_exception(TestSetupEx, "read on pin 'p' (23, mw) is not permitted.")
		end
	end

	describe "when asserting write access, should" do
		it "return true, when it has valid permissions" do
			$pin.assert_write_access.should be == true
		end
		it "raises exception when it does not have valid permissions" do
			$pin.permissions = "mr"
			expect { $pin.assert_write_access }.to raise_exception(TestSetupEx, "write on pin 'p' (23, mr) is not permitted.")
		end
	end
end


describe AnalogPin do
	it "when instantiating a pin instance, returns correct instance" do
		p = AnalogPin.new 'p', 23, :type, "rw", 0..100, 0..200
		p.name.should be == 'p'
		p.number.should be == 23
		p.type.should be == :type
		p.permissions.should be == "rw"
		p.end_scale.should be == (0..100)
		p.raw_scale.should be == (0..200)
	end
end
