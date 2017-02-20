
class Board
	@@all_instances = []

	attr_accessor :name, :protocol, :pins

	def initialize name, protocol
		@name = name
		@protocol = protocol
		@pins = {}
		@@all_instances << self
	end

	def wire name, number, type, meta={}
		raise "A pin by the name of '#{name}' has already been wired." if @pins.include? name
		pin = nil
		case type
		
		when :di
			active_high = meta[:active_high]
			active_high = false if active_high == nil && meta.include?(:active_low)
			active_high = true  if active_high == nil
			raise "'#{name}, ##{number}': :active_high can only have true or false as values" unless active_high.class == TrueClass || active_high.class == FalseClass
			pin = DigitalInputPin.new name, number, active_high, @protocol
		
		when :do
			pin = DigitalOutputPin.new name, number, active_high, @protocol
			
		when :ai
			end_scale = meta[:end_scale]
			end_scale = 0..1023 if end_scale == nil
			raw_scale = meta[:raw_scale]
			raw_scale = 0..1023 if raw_scale == nil
			raise "'#{name}, ##{number}': :end_scale can only have Range as value" unless end_scale.class == Range
			raise "'#{name}, ##{number}': :raw_scale can only have Range as value" unless raw_scale.class == Range

			pin = AnalogInputPin.new name, number, @protocol, end_scale, raw_scale
			
		when :ao
			end_scale = meta[:end_scale]
			end_scale = 0..1023 if end_scale == nil
			raw_scale = meta[:raw_scale]
			raw_scale = 0..1023 if raw_scale == nil
			raise "'#{name}, ##{number}': :end_scale can only have Range as value" unless end_scale.class == Range
			raise "'#{name}, ##{number}': :raw_scale can only have Range as value" unless raw_scale.class == Range

			pin = AnalogOutputPin.new name, number, @protocol, end_scale, raw_scale
		else
			raise "'#{name}, ##{number}': invalid pin type. Valid types are- [:di, :do, :ai, :ao]"
		end

		@pins[name] = pin
		return pin
	end

	def connect
		@protocol.connect unless @protocol.connected?
	end

	def ping
		@protocol.ping
	end

	# def reset
	# end

	def Board.all_boards
		return @@all_instances
	end

	def Board.get_board name
		@@all_instances.each {  |i| return i if i.name == name }
		return nil
	end
end


=begin
class Bridge
	attr_accessor :name, :protocol, :pins

	def initialize name, pins, protocol
		@name     = name
		@pins     = pins
		@protocol = protocol
	end

	def Bridge.parse name, raw
		protocol = Protocol.parse raw[:protocol]
		
		pins = []
		protocol.
		raw[:wiring].each_pair {  |name, config|  pins.push( Pin.parse name, config, protocol )  }

		return Bridge.new name, pins, protocol
	end
end
=end
