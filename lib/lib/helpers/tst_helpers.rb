
class Scale
	def Scale.convert value, from, to
		if from.first < from.last
			return to.first if value <= from.first
			return to.last  if value >= from.last
		end

		value *= 1.0
		result = ((to.last - to.first) * ( (value - from.first) / (from.last - from.first) ) + to.first).round
		result *= -1 if result < 0
		return result
	end

	def Scale.convert_percent value, scale
		scale = (scale.last..scale.first) if scale.first > scale.last
		return 0.0 if value < scale.first

		return ((value - scale.first * 1.0) / (scale.last - scale.first)) * 100.0
	end
end

class OptionMaker
	def OptionMaker.parse(args)
		args = [args] if args.class != Array
		options = {}
		filelist = []
		args.each {  |arg|
			arg = arg.strip
			if (arg =~ /^--([a-zA-Z+0-9._\\\/:\s]+)=\"?([a-zA-Z+0-9._\\\/:\s\;]+)\"?/)  # match against "--key=value"
				options = option_maker(options, $1, $2)
			elsif (arg =~ /^--([a-zA-Z+0-9._\\\/:\s]+)/) # match agains "--key"
				options = option_maker(options, $1, $2)
			else
			filelist << arg
			end
		}
		filelist.reject!(&:empty?)
		return options, filelist
	end

	private
	def OptionMaker.option_maker(options, key, val)
		options = options || {}
		key = key.strip.to_sym
		# val = "" if val == nil
		if val == nil
			options[key] = nil
			return options
		end
		options[key] =
		if val.chr == ":"
			val[1..-1].to_sym
		elsif val.include? ";"
			# appends the array values to previously parsed values
			value = options[key]
			value = [] unless value
			value.push val.split(';').map(&:strip)
			value.flatten!
			value = value[0] if value.length == 1
			value
		elsif val == 'true'
			true
		elsif val == 'false'
			false
		elsif val =~ /^\d+$/
			val.to_i
		else
			val
		end
		return options
	end
	
end

def delay ms
	sleep ms
end

def forever(&code)
	while true
		code.call if code
	end
end

def eputs message
	STDERR << message + "\n"
end

def abort message=''
	super message
end

def get_config name, silent=false
	name_original = name
	name = name.to_s.downcase
	$cli_options.each_pair {  |key, value|
		option = key.to_s.downcase
		return value if option == name
	} if $cli_options != nil
	ENV.each_pair {  |key, value|
		option = key.to_s.downcase
		return value if option == name
	}
	raise "'#{name_original}' is not defined." unless silent
	return nil
end

def get_value aliases
	$cli_options.each_pair {  |key,value|
		aliases.each {  |a| return value if a == key }
	} if $cli_options != nil
	return nil
end

