
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

	def DigitalPin.parse_meta name, number, meta={}
		meta = { meta => nil } if meta.class != Hash

		if meta.include?(:active_low)
			active_low = meta[:active_low]
			raise "Pin '#{name}' ('#{number}'): active_low can only be true or false ('#{active_low.class}')" if active_low != nil && active_low.class != TrueClass && active_low.class != FalseClass
			active_high = active_low == nil ? false : !active_low
		elsif meta.include?(:active_high)
			active_high = meta[:active_high]
			raise "Pin '#{name}' ('#{number}'): active_high can only be true or false ('#{active_high.class}')" if active_high != nil && active_high.class != TrueClass && active_high.class != FalseClass
			active_high = active_high == nil ? true : active_high
		else
			active_high = true
		end

		return active_high
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

	def DigitalOutputPin.parse name, number, meta={}
		active_high = DigitalPin.parse_meta name, number, meta
		return DigitalOutputPin.new name, number, active_high
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


	def DigitalInputPin.parse name, number, meta={}
		active_high = DigitalPin.parse_meta name, number, meta
		return DigitalInputPin.new name, number, active_high
	end
end

class AnalogPin < Pin
	attr_accessor :raw_scale, :end_scale
	
	def initialize(name, number, type, permissions, coms=nil, end_scale=0..1023, raw_scale=0..1023)
		super(name, number, type, permissions, coms)
		@end_scale = end_scale
		@raw_scale = raw_scale
	end

	def AnalogPin.parse_meta name, number, meta={}
		meta = { meta => nil } if meta.class != Hash
		# get aliases
		meta[:raw_scale] = meta[:raw]   unless meta[:raw_scale]
		meta[:end_scale] = meta[:scale] unless meta[:end_scale]
		meta[:end_scale] = meta[:end]   unless meta[:end_scale]

		raw_scale = meta[:raw_scale]
		end_scale = meta[:end_scale]

		if end_scale.class == Fixnum || end_scale.class == Float
			if raw_scale.class == Range || raw_scale.class == Fixnum

				# force defaults for raw_scale
				raw_scale = (0..raw_scale) if raw_scale.class == Fixnum
				
				# convert end_scale to a range
				end_first = raw_scale.first * end_scale
				end_first = end_first.round if end_first.class == Float
				end_last  = raw_scale.last * end_scale
				end_last = end_last.round if end_last.class == Float

				end_scale = (end_first..end_last)
			elsif raw_scale != nil
				raise "Pin '#{name}' ('#{number}'): raw_scale can only be a Fixnum, Range or nil when end_scale is a Fixnum/Float ('#{raw_scale.class}')"
			end
		elsif end_scale.class == Range
			if raw_scale == nil
				raw_scale = (0..1023)
			elsif raw_scale.class != Range
				raise "Pin '#{name}' ('#{number}'): raw_scale can only be a Range or nil when end_scale is a Range ('#{raw_scale.class}')"
			end
		elsif end_scale == nil
			raise "Pin '#{name}' ('#{number}'): raw_scale can only be a Range when no end_scale is provided ('#{raw_scale.class}')" if raw_scale != nil && raw_scale.class != Range
			end_scale = raw_scale

			end_scale = 0..1023 if end_scale == nil
			raw_scale = 0..1023 if raw_scale == nil
		else
			raise "Pin '#{name}' ('#{number}'): end_scale can only be a Fixnum, Float or Range ('#{end_scale.class}')"
		end

		return raw_scale, end_scale
	end
end

class AnalogInputPin < AnalogPin

	def initialize(name, number, coms=nil, end_scale=0..1023, raw_scale=0..1023)
		super(name, number, :ai, "r", coms, end_scale, raw_scale)
	end

	def read
		raw_value = super()
		
		return raw_value if @end_scale == nil && @raw_scale == nil

		if @end_scale.class == Fixnum || @end_scale.class == Float
			result = raw_value * @end_scale 
			return @end_scale.class == Float ? result.round : result
		end

		return Scale.convert raw_value, @raw_scale, @end_scale
	end

	def is_almost? reference, tolerance=10.0
		tolerance = Float(tolerance)
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
		tolerance = Float(tolerance)
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
		tolerance = Float(tolerance)
		read_value = read()
		percent_of_full_scale = Scale.convert_percent read_value, @end_scale
		
		return percent_of_full_scale >= tolerance
	end
	[
		:almost_full?,       :is_almost_full_scale?, :almost_full_scale?, 
		:is_almost_maximum?, :almost_maximum?,       :is_almost_max?,     :almost_max?
	].each {  |a| alias_method a, :is_almost_full? }


	# returns pin.value if $SANDBOXING is defined
	# returns pin-name 
	def to_s
		return read().to_s if $SANDBOXING
		return super()
	end


	def AnalogInputPin.parse name, number, meta={}
		raw_scale, end_scale = AnalogPin.parse_meta name, number, meta
		return AnalogInputPin.new name, number, nil, end_scale, raw_scale
	end
end


class AnalogOutputPin < AnalogPin
	def initialize(name, number, coms=nil, end_scale=0..1023, raw_scale=0..1023)
		super(name, number, :ao, "w", coms, end_scale, raw_scale)
	end

	def write(value)
		unless @end_scale == nil || @raw_scale == nil
			if @end_scale.class == Fixnum || @end_scale.class == Float
				value = value * @end_scale 
			else
				value = Scale.convert value, @end_scale, @raw_scale
			end
		end
		value = value.round if value.class == Float
		super value
	end
	[:<<, :latch].each {  |a| alias_method a, :write }

	def AnalogOutputPin.parse name, number, meta={}
		raw_scale, end_scale = AnalogPin.parse_meta name, number, meta
		return AnalogOutputPin.new name, number, nil, end_scale, raw_scale
	end
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


