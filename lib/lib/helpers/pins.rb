
[ 
	"tst_helpers",
].each {|req| require "#{File.expand_path(File.dirname(__FILE__))}/#{req}"}


class Pin
	attr_accessor :number, :name, :type, :permissions
	attr_accessor :protocol_bridge

	def initialize(name, number, type, permissions)
		@name        = name
		@number      = number
		@type        = type
		@permissions = permissions.class == String ? permissions : permissions.to_s
	end

	def read
		assert_read_access
		return @protocol_bridge.read_pin @number, @type
	end
	
	def write(value)
		assert_write_access
		@protocol_bridge.write_pin @number, @type, value
	end

	def assert_read_access
		raise TestSetupEx.new "read on #{self} is not permitted." unless @permissions.include? 'r'
		return true
	end

	def assert_write_access
		raise TestSetupEx.new "write on #{self} is not permitted." unless @permissions.include? 'w'
		return true
	end

	def to_s
		return "pin '#{@name}' (#{@number}, #{@permissions})"
	end
end

class DigitalPin < Pin
end

class AnalogPin < Pin
	attr_accessor :raw_scale, :end_scale
	
	def initialize(name, number, type, permissions, end_scale, raw_scale=0..1023)
		super(name, number, type, permissions)
		@end_scale = end_scale
		@raw_scale = raw_scale
	end

	def read
		raw_value = super()
		scaled_value = Scale.convert raw_value, @raw_scale, @end_scale
		return Scale.convert, raw_value
	end

	def write(value)
		raw_value = Scale.convert value, @end_scale, @raw_scale
		super value
	end
end
