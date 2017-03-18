
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
		$pin.board_protocol = $dummy_protocol
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
			expect { $pin.assert_read_access }.to raise_exception(PinEx, "read on pin 'p' (23, mw) is not permitted.")
		end
	end

	describe "when asserting write access, should" do
		it "return true, when it has valid permissions" do
			$pin.assert_write_access.should be == true
		end
		it "raises exception when it does not have valid permissions" do
			$pin.permissions = "mr"
			expect { $pin.assert_write_access }.to raise_exception(PinEx, "write on pin 'p' (23, mr) is not permitted.")
		end
	end
end


# describe AnalogPin do
# 	it "when instantiating a pin instance, returns correct instance" do
# 		p = AnalogPin.new 'p', 23, :type, "rw", 0..100, 0..200
# 		p.name.should be == 'p'
# 		p.number.should be == 23
# 		p.type.should be == :type
# 		p.permissions.should be == "rw"
# 		p.end_scale.should be == (0..100)
# 		p.raw_scale.should be == (0..200)
# 	end
# end


# describe DigitalPin do
# 	before(:each) do
# 		$pin = DigitalPin.new 'p', 23, :type, "rw"
# 	end
# 	it "set" do
# 		expect($pin).to receive(:write).with(true)
# 		$pin.set
# 	end
# 	it "reset" do
# 		expect($pin).to receive(:write).with(false)
# 		$pin.reset
# 	end
# 	it "on" do
# 		$pin.active_high = 'a'
# 		expect($pin).to receive(:write).with('a')
# 		$pin.on!
# 	end
# 	it "off" do
# 		$pin.active_high = true
# 		expect($pin).to receive(:write).with(false)
# 		$pin.off!
# 	end
# end

describe DigitalPin do
	describe "when parsing meta" do
		describe "returns correct result" do
			it "no meta is provided" do
				active_high = DigitalPin.parse_meta 'p', 23
				active_high.should be == true
			end
			describe "active_low is provided with" do
				it "no value" do
					active_high = DigitalPin.parse_meta 'p', 23, :active_low
					active_high.should be == false
				end
				it "false" do
					active_high = DigitalPin.parse_meta 'p', 23, :active_low => false
					active_high.should be == true
				end
				it "true" do
					active_high = DigitalPin.parse_meta 'p', 23, :active_low => true
					active_high.should be == false
				end
			end
			describe "active_high is provided with" do
				it "no value" do
					active_high = DigitalPin.parse_meta 'p', 23, :active_high
					active_high.should be == true
				end
				it "false" do
					active_high = DigitalPin.parse_meta 'p', 23, :active_high => false
					active_high.should be == false
				end
				it "true" do
					active_high = DigitalPin.parse_meta 'p', 23, :active_high => true
					active_high.should be == true
				end
			end
		end
	end
end

describe DigitalInputPin do
	it "when parsing an object instance, returns valid result" do
		expect(DigitalPin).to receive(:parse_meta).with('p', 23, 'meta').and_return('result')

		p = DigitalInputPin.parse 'p', 23, 'meta'

		p.class.should be == DigitalInputPin
		p.active_high.should be == 'result'
	end
end

describe DigitalOutputPin do
	it "when parsing an object instance, returns valid result" do
		expect(DigitalPin).to receive(:parse_meta).with('p', 23, 'meta').and_return('result')

		p = DigitalOutputPin.parse 'p', 23, 'meta'

		p.class.should be == DigitalOutputPin
		p.active_high.should be == 'result'
	end
end

describe AnalogPin do
	describe "when parsing meta" do
		describe "raises exception when" do
			it "end_scale is something other than a Fixnum, Float, range" do
				expect { AnalogPin.parse_meta 'pin', 12, :end_scale => 'blah' }.to raise_exception("Pin 'pin' ('12'): end_scale can only be a Fixnum, Float or Range ('String')")
			end
			it "end_scale is provided as Fixnum and raw_scale is provided as something other than a Fixnum, Range or nil" do
				expect { AnalogPin.parse_meta 'pin', 12, :raw_scale => 'blah', :end_scale => 2 }.to raise_exception("Pin 'pin' ('12'): raw_scale can only be a Fixnum, Range or nil when end_scale is a Fixnum/Float ('String')")
			end
			it "end_scale is a Range and raw_scale is something other than nil" do
				expect { AnalogPin.parse_meta 'pin', 12, :raw_scale => 'blah', :end_scale => (0..10) }.to raise_exception("Pin 'pin' ('12'): raw_scale can only be a Range or nil when end_scale is a Range ('String')")
			end
			it "raw_scale is something other than a Range when end_scale is nil" do
				expect { AnalogPin.parse_meta 'pin', 12, :raw_scale => 2 }.to raise_exception("Pin 'pin' ('12'): raw_scale can only be a Range when no end_scale is provided ('Fixnum')")
			end
		end
		describe "returns valid data when" do
			describe "end_scale is a Fixnum and" do
				it "no raw_scale is provided" do
					raw_scale, end_scale = AnalogPin.parse_meta 'pin', 12, :end_scale => 2

					end_scale.should be == 2
					raw_scale.should be == nil
				end
				it "raw_scale is provided as Fixnum" do
					raw_scale, end_scale = AnalogPin.parse_meta 'pin', 12, :raw_scale => 100, :end_scale => 2

					end_scale.should be == (0..200)
					raw_scale.should be == (0..100)
				end
				it "raw_scale is provided as range" do
					raw_scale, end_scale = AnalogPin.parse_meta 'pin', 12, :raw_scale => 0..50, :end_scale => 2

					end_scale.should be == (0..100)
					raw_scale.should be == (0..50)
				end
			end
			describe "end_scale is a Float and" do
				it "no raw_scale is provided" do
					raw_scale, end_scale = AnalogPin.parse_meta 'pin', 12, :end_scale => 2.0

					end_scale.should be == 2
					raw_scale.should be == nil
				end
				it "raw_scale is provided as Fixnum" do
					raw_scale, end_scale = AnalogPin.parse_meta 'pin', 12, :raw_scale => 100, :end_scale => 1.1

					end_scale.should be == (0..110)
					raw_scale.should be == (0..100)
				end
				it "raw_scale is provided as range" do
					raw_scale, end_scale = AnalogPin.parse_meta 'pin', 12, :raw_scale => 0..50, :end_scale => 2.0

					end_scale.should be == (0..100)
					raw_scale.should be == (0..50)
				end
			end
			describe "end_scale is a range and" do
				it "raw_scale is missing" do
					raw_scale, end_scale = AnalogPin.parse_meta 'pin', 12, :end_scale => 0..100

					end_scale.should be == (0..100)
					raw_scale.should be == (0..1023)
				end
				it "raw_scale is missing" do
					raw_scale, end_scale = AnalogPin.parse_meta 'pin', 12, :end_scale => 0..100

					end_scale.should be == (0..100)
					raw_scale.should be == (0..1023)
				end
			end
			it "end_scale is a nil and raw_scale is a range" do
				raw_scale, end_scale = AnalogPin.parse_meta 'pin', 12, :raw_scale => 0..50

				raw_scale.should be == (0..50)
				end_scale.should be == (0..50)
			end
			it "end_scale and raw_scale are both nil" do
				raw_scale, end_scale = AnalogPin.parse_meta 'pin', 12

				end_scale.should be == (0..1023)
				raw_scale.should be == (0..1023)
			end
			it "end_scale and raw_scale are both provided as range" do
				raw_scale, end_scale = AnalogPin.parse_meta 'pin', 12, :raw_scale => 0..50, :end_scale => (0..100)

				raw_scale.should be == (0..50)
				end_scale.should be == (0..100)
			end
		end
	end
end

describe AnalogInputPin do
	before(:each) do
		$dummy_coms = []
		$pin = AnalogInputPin.new 'p', 23, $dummy_coms, 0..100, 0..100
	end

	xit "lies_within?" do
		dummy_result = []
		expect($pin).to receive(:read).and_return(dummy_result)
		# expect(dummy_result).to receive(:)
		# $pin.lies_within? 
	end

	describe "is_almost?" do
		it "returns true when the value read is within the tolerance level" do
			expect($pin).to receive(:read).and_return 40
			$pin.is_almost?(50).should be true

			expect($pin).to receive(:read).and_return 60
			$pin.is_almost?(50).should be true
		end

		it "returns false when the value read is outside the tolerance level" do
			expect($pin).to receive(:read).and_return 39
			$pin.is_almost?(50).should be false

			expect($pin).to receive(:read).and_return 61
			$pin.is_almost?(50).should be false
		end
	end

	it "when parsing an object instance, returns valid object" do
		expect(AnalogPin).to receive(:parse_meta).with('pin', 12, 'meta').and_return(['raw', 'end'])

		pin = AnalogInputPin.parse 'pin', 12, 'meta'

		pin.class == AnalogInputPin
		pin.name.should be == 'pin'
		pin.number.should be == 12
		pin.raw_scale.should be == 'raw'
		pin.end_scale.should be == 'end'
	end
end

describe AnalogOutputPin do
	it "when parsing an object instance, returns valid object" do
		expect(AnalogPin).to receive(:parse_meta).with('pin', 12, 'meta').and_return(['raw', 'end'])

		pin = AnalogOutputPin.parse 'pin', 12, 'meta'

		pin.class == AnalogOutputPin
		pin.name.should be == 'pin'
		pin.number.should be == 12
		pin.raw_scale.should be == 'raw'
		pin.end_scale.should be == 'end'
	end
end
