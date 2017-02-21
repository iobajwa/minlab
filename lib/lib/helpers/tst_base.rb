
class TestSetupEx < Exception
end

class TestFailureEx < Exception
end

class FatalEx < Exception
end

class TestIgnoreEx < Exception
end

class TestSkipEx < Exception
end


class Test
	attr_accessor :name, :purpose, :execution, :setup, :teardown, :options
	
	def initialize(name, purpose, execution, setup=nil, teardown=nil, options={})
		@name      = name
		@purpose   = purpose
		@execution = execution
		@setup     = setup
		@teardown  = teardown
		@options   = options
	end

	# returns test status
	# => :passed upon pass ("ok")
	# => :ignored upon ignore (<message>)
	# => :failed upon failure (<reasons>)
	# => :failed upon fatal error (<unhandeled exception>)
	def run(params=nil)
		begin
			settings = params.merge @options
			repeat_count = settings[:repeat_count]
			repeat_count = 1 unless repeat_count
			repeat_count.times {
				setup.call     settings if setup     != nil
				execution.call settings if execution != nil
				teardown.call  settings if teardown  != nil
			}
		rescue TestSkipEx => ex
			return :skipped, ex.message
		rescue TestIgnoreEx => ex
			return :ignored, ex.message
		rescue TestFailureEx => ex
			return :failed, ex.message
		rescue => ex 							# some other fatal
			return :error, ex.message
		end
		return :passed, "ok"
	end

	def to_s
		return "#{@name}" if @purpose == nil or @purpose == ''
		return "#{@name}: #{@purpose}"
	end

end

class TestGroup
	attr_accessor :name, :purpose, :list, :setup, :teardown
	attr_accessor :abort_on_first_failure

	# by default a test-suite is aborted 
	def initialize(name, purpose, list, setup=nil, teardown=nil)
		@name     = name
		@purpose  = purpose
		list = [list] if list.class != Array
		# make sure list has objects of same type
		first_class = list[0].class if list.length > 0
		list.each {  |t| raise "TestGroup cannot house mixed class components for list" unless t.class == first_class }
		@list    = list
		@setup    = setup
		@teardown = teardown
		@abort_on_first_failure = false
	end

	def has_test_list?
		return false if @list.length < 1
		return @list[0].class == Test
	end

	def list_max_name_length
		max_length = 0
		@list.each {  |l| max_length = l.name.length if l.name.length > max_length }
		return max_length
	end

	def run_setup params={}
		@setup.call params if @setup
	end

	def run_teardown params={}
		@teardown.call params if @teardown
	end
end

def fail message=''
	raise TestFailureEx.new message
end

def ignore message=''
	raise TestIgnoreEx.new message
end

def skip message=''
	raise TestSkipEx.new message
end
