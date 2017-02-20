
class Scale
	def Scale.convert value, from, to
		from = (from.last..from.first) if from.first > from.last
		to = (to.last..to.first) if to.first > to.last
		return to.first if value <= from.first
		return to.last if value >= from.last

		value *= 1.0
		return ((to.last - to.first) * ( (value - from.first) / (from.last - from.first) ) + to.first).round
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

class Bridges
	def Bridges.parse raw
	end
end

def delay ms
	sleep ms
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
	}
	ENV.each_pair {  |key, value|
		option = key.to_s.downcase
		return value if option == name
	}
	raise "'#{name_original}' is not defined." unless silent
	return nil
end

def find_file conventional_names
	conventional_names.each {  |cn|
		f = _find_file cn
		return f if f
	}
	return nil
end

def _find_file name
	sole_name = File.basename name, ".*"
	# begin by searching configs
	f = get_config sole_name, true

	# if not found in configs, search cli-files
	$cli_files.each {  |cf|
		c_f_name = File.basename cf, ".*"
		if c_f_name.downcase == sole_name.downcase
			f = cf
			break
		end
	} unless f

	# if not, check the current working directory
	unless f
		f = File.join Dir.pwd, 'name'
		f = nil unless File.exist? f
	end
	
	f = File.absolute_path f if f
	return f
end
