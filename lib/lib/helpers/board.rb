
require_relative "serial_port.rb"
require_relative "tst_helpers.rb"

class Board
	@@all_instances = []

	attr_accessor :name, :protocol, :pins

	def initialize name, protocol, meta={}
		meta = {} unless meta
		meta = { meta => nil } if meta.class != Hash

		port_number = meta[:port]
		port_number = meta[:comport] unless port_number
		port_number = meta[:coms] unless port_number
		port_number = meta[:com_port] unless port_number
		port_number = meta[:com_port_number] unless port_number
		port_number = meta[:port_number] unless port_number
		port_number = get_config "#{name.upcase}_COM_PORT", true unless port_number

		baud_rate = meta[:baud]
		baud_rate = meta[:baud_rate] unless baud_rate
		baud_rate = meta[:baudrate]  unless baud_rate
		baud_rate = get_config "#{name.upcase}_BAUD_RATE", true unless baud_rate
		baud_rate = 115200 if name == 'arduino' && baud_rate == nil

		raise "Board '#{name}': could not identify port" unless port_number
		raise "Board '#{name}': could not identify baud rate" unless baud_rate

		com_port = nil
		if meta.include?(:gateway) && meta[:gateway]
			bridge = meta[:gateway]
			bridge = Board.get_board bridge if bridge.class == String
			raise "Board '#{name}': could not identify bridge ('#{bridge}')" unless bridge
			com_port = bridge.protocol.open_gateway port_number, baud_rate
		else
			begin
				com_port = Serial.new port_number, baud_rate
			rescue RubySerial::Exception => ex
				raise "Board '#{name}': com_port '#{port_number}' and/or board already in use." if ex.message == "ERROR_ACCESS_DENIED"
				raise "Board '#{name}': not found (Port '#{port_number}')." if ex.message == "ERROR_FILE_NOT_FOUND"
				raise "Board '#{name}': has stopped responding (hung) or a general failure occurred on the device. Try manual reset. (Port '#{port_number}')." if ex.message == "ERROR_GEN_FAILURE"
				raise "Board '#{name}': #{ex.message}"
			rescue => ex
				raise "Board '#{name}': #{ex.message}"
			end
		end

		@name = name
		@pins = {}
		@protocol = protocol.new com_port
		@protocol.connect
		@@all_instances << self
	end

	def wire name, number, type, meta={}
		meta = { meta => nil } if meta.class != Hash
		raise "A pin by the name of '#{name}' has already been wired." if @pins.include? name
		pin = nil
		case type
			when :di then pin = DigitalInputPin.parse name, number, meta
			when :do then pin = DigitalOutputPin.parse name, number, meta
			when :ai then pin = AnalogInputPin.parse name, number, meta
			when :ao then pin = AnalogOutputPin.parse name, number, meta
			else raise "'#{name}, ##{number}': invalid pin type ('#{type}'). Valid types are- [:di, :do, :ai, :ao]"
		end

		pin.board_protocol = @protocol
		@pins[name] = pin
		return pin
	end

	def connect
		@protocol.connect unless @protocol.connected?
	end

	def disconnect
		@protocol.disconnect
	end

	def ping
		@protocol.ping
	end

	def reset
		@protocol.reset
	end

	def Board.all_boards
		return @@all_instances
	end

	def Board.get_board name
		name = name.downcase
		@@all_instances.each {  |i| return i if i.name.downcase == name }
		return nil
	end
end
