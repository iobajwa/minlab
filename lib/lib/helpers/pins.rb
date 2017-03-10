
require_relative "tst_helpers"

class PinEx < Exception
end

class Pin
	attr_accessor :number, :name, :type, :permissions
	attr_accessor :board_protocol

	def initialize(name, number, type, permissions, board_protocol=nil)
		@name        = name
		@number      = number
		@type        = type
		@permissions = permissions.class == String ? permissions : permissions.to_s
		@board_protocol = board_protocol
	end

	def read
		assert_read_access
		return @board_protocol.read_pin @number, @type
	end

	# def on
	# 	write(true)
	# end

	# def off
	# 	write(false)
	# end
	
	def write(value)
		assert_write_access
		@board_protocol.write_pin @number, @type, value
	end

	def assert_read_access
		raise PinEx.new "read on #{self} is not permitted." unless @permissions.include? 'r'
		return true
	end

	def assert_write_access
		raise PinEx.new "write on #{self} is not permitted." unless @permissions.include? 'w'
		return true
	end

	def to_s
		return "pin '#{@name}' (#{@number}, #{@permissions})"
	end
end

class DigitalPin < Pin

	attr_accessor :active_high

	def initialize(name, number, type, permissions, active_high=true, board_protocol=nil)
		super(name, number, type, permissions, board_protocol)
		@active_high = active_high
	end
end


class DigitalOutputPin < DigitalPin
	
	def initialize(name, number, active_high=true, board_protocol=nil)
		super(name, number, :do, "w", active_high, board_protocol)
	end

	def set
		write true
	end
	[
	  :true, :true!, :high, :high!,
	  :set_true, :set_high,
	  :make_true, :make_high,
	].each {  |a| alias_method a, :set }

	def reset
		write false
	end
	[
	  :false, :false!, :low, :low!,
	  :set_false, :set_low,
	  :make_false, :make_low,
	  
	].each {  |a| alias_method a, :reset }


	# switches the digital pin on depending upon @active_high
	def on!
		write @active_high
	end
	[ :on, :switch_on, :switch_on! ].each {  |a| alias_method a, :on! }

	# switches the digital pin off depending upon @active_high
	def off!
		write !@active_high
	end
	[ :off, :switch_off, :switch_off! ].each {  |a| alias_method a, :off! }


	def toggle time=0.5, count=5
		count.times {
			on!
			delay time
			off!
			delay time
		}
	end
end

class DigitalInputPin < DigitalPin

	attr_accessor :pin_network
	
	def initialize(name, number, active_high=true, board_protocol=nil)
		super(name, number, :di, "r", active_high, board_protocol)
	end

	def read
		data = @pin_network == nil ? super : @pin_network.get_state( @name )
		return data == 1
	end

	def get_state
		value = read
		return @active_high ? value : !value
	end

	def is_set
		return read
	end
	[
	  :is_set?, :set?,
	  :is_high, :is_high?, :high?,
	].each {  |a| alias_method a, :is_set }

	def is_reset
		return !read
	end
	[
	  :is_reset?, :reset?,
	  :is_false, :is_false?, :false?,
	].each {  |a| alias_method a, :is_reset }


	# returns weather the digital pin is 'on' depending upon @active_high
	def is_on
		state = is_set
		return @active_high ? state : !state
	end
	[ :is_on?, :on? ].each {  |a| alias_method a, :is_on }

	def is_off
		state = is_reset
		return @active_high ? state : !state
	end
	[ :is_off?, :off? ].each {  |a| alias_method a, :is_off }
end

class AnalogPin < Pin
	attr_accessor :raw_scale, :end_scale
	
	def initialize(name, number, type, permissions, coms=nil, end_scale=0..1023, raw_scale=0..1023)
		super(name, number, type, permissions, coms)
		@end_scale = end_scale
		if raw_scale.class != Range

		end
		@raw_scale = raw_scale
	end

end

class AnalogInputPin < AnalogPin

	def initialize(name, number, coms=nil, end_scale=0..1023, raw_scale=0..1023)
		super(name, number, :ai, "r", coms, end_scale, raw_scale)
	end

	def read
		raw_value = super()
		scaled_value = Scale.convert raw_value, @raw_scale, @end_scale
		return scaled_value
		# return Scale.convert, raw_value
	end

	def is_almost? reference, tolerance=10.0
		read_value = read()
		delta = ((@end_scale.last - @end_scale.first) * tolerance) / 100
		return (reference-delta..reference+delta).include? read_value
	end
	[ :is_almost_equals?, :is_almost_equal_to?, :almost_equals?, :almost_equals_to? ].each {  |a| alias_method a, :is_almost? }

	def lies_within? specified_range
		read_value = read()
		return specified_range.include? read_value
	end
	[ :is_within?, :within? ].each {  |a| alias_method a, :lies_within? }

	def lies_outside? specified_range
		read_value = read()
		return !specified_range.include?(read_value)
	end
	[ :is_outside?, :outside? ].each {  |a| alias_method a, :lies_outside? }

	def > reference
		read_value = read()
		return read_value > reference
	end
	[ :greater_than?, :greater_than, :is_greater?, :is_greater, :is_greater_than?, :is_greater_than, :greater? ].each {  |a| alias_method a, :> }

	def < reference
		read_value = read()
		return read_value < reference
	end
	[ :less_than?, :less_than, :is_less?, :is_less, :is_less_than?, :is_less_than, :lesser? ].each {  |a| alias_method a, :> }

	def >= reference
		read_value = read()
		return read_value >= reference
	end
	[ :greater_than_equals_to?, :greater_than_equals_to, :is_greater_or_equals?, :is_greater_or_equals, 
      :is_greater_than_equals_to?, :is_greater_than_equals_to, :greater_or_equals? ].each {  |a| alias_method a, :>= }

  	def <= reference
		read_value = read()
		return read_value <= reference
	end
	[ :less_than_equals_to?, :less_than_equals_to, :is_less_or_equals?, :is_less_or_equals, 
      :is_less_than_equals_to?, :is_less_than_equals_to, :lesser_or_equals? ].each {  |a| alias_method a, :>= }


	def is? expected_value
		read_value = read()
		return read_value == expected_value
	end
	[
		:equals_to?, :is_equals_to?, :is_equal_to?,
		:equals?,    :is_equals?,    :is,           :reads?
	].each {  |a| alias_method a, :is? }

	
	# returns true if the current value on the pin is scale 0.
	def is_zero?
		return is? @end_scale.first
	end
	[
		:zero?,       :is_zero_scale?, :zero_scale?,
		:is_minimum?, :minimum?,       :is_min?,     :min?, :is_0?,
		:is_empty?,   :empty?,
	].each {  |a| alias_method a, :is_zero? }


	# returns true if the current value on the pin is almost 0 (0 +- 1% full scale error)
	def is_almost_zero?(tolerance=10.0)
		read_value = read()
		percent_of_full_scale = Scale.convert_percent read_value, @end_scale
		
		return percent_of_full_scale <= tolerance
	end
	[
		:almost_zero?,    :is_almost_zero_scale?, :almost_zero_scale?, :is_almost_minimum?,    
		:almost_minimum?, :is_almost_min?,        :almost_min?,
	].each {  |a| alias_method a, :is_almost_zero? }


	# returns true if the current value on the pin is absolutely full (full scale maximum).
	def is_full?
		should_be @end_scale.last
	end
	[
		:full?,       :is_full_scale?, :full_scale?,
		:is_maximum?, :maximum?,       :is_max?,     :max?,
	].each {  |a| alias_method a, :is_full? }


	# tests if the current value on the pin is almost full (full scale +- 1% error)
	def is_almost_full? tolerance=90.0
		read_value = read()
		percent_of_full_scale = Scale.convert_percent read_value, @end_scale
		
		return percent_of_full_scale >= tolerance
	end
	[
		:almost_full?,       :is_almost_full_scale?, :almost_full_scale?, 
		:is_almost_maximum?, :almost_maximum?,       :is_almost_max?,     :almost_max?
	].each {  |a| alias_method a, :is_almost_full? }
end


class AnalogOutputPin < AnalogPin
	def initialize(name, number, coms=nil, end_scale=0..1023, raw_scale=0..1023)
		super(name, number, :ao, "w", coms, end_scale, raw_scale)
	end

	def write(value)
		raw_value = Scale.convert value, @end_scale, @raw_scale
		super raw_value
	end
	[:<<, :latch].each {  |a| alias_method a, :write }
end





class PinNetwork
	attr_accessor :name, :pins, :pins_protocol
	attr_accessor :pins_status, :pin_numbers

	def initialize name, pins
		pins = [pins] unless pins.class == Array
		raise "PinNetwork '#{name}': no pin collection passed!" if pins.length == 0

		first_protocol = pins[0].board_protocol
		first_type     = pins[0].type
		@pins_status = {}
		@pin_numbers = []

		raise "PinNetwork '#{name}': can only house :di pins" if first_type != :di
		pins.each {  |p|
			raise "PinNetwork '#{name}': collections can only be of base class Pin" unless p.class < Pin
			raise "PinNetwork '#{name}': all pins must have same board_protocol" unless p.board_protocol == first_protocol
			raise "PinNetwork '#{name}': all pins must be of same type" unless p.type == first_type
			@pins_status[p.name] = nil
			@pin_numbers.push p.number
			p.pin_network = self
		}

		@name = name
		@pins = pins
		@pins_protocol = first_protocol
	end


	def read
		states = @pins_protocol.read_pin_network @pin_numbers
		@pins.each {  |p| @pins_status[p.name] = states.shift  }
	end
	[ :refresh, :update, :refresh!, :update!, :read! ].each {  |a| alias_method a, :read }

	def get_state name
		return @pins_status[name]
	end
end


