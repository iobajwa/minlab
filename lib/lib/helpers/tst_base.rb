
class TestSetupEx < Exception
end

class TestFailureEx < Exception
end

class FatalEx < Exception
end

class TestIgnoreEx < Exception
end


class Test
	attr_accessor :name, :purpose, :execution, :setup, :teardown
	
	def initialize(name, purpose, execution, setup=nil, teardown=nil)
		@name      = name
		@purpose   = purpose
		@execution = execution
		@setup     = setup
		@teardown  = teardown
	end

	# returns test status
	# => :passed upon pass ("ok")
	# => :ignored upon ignore (<message>)
	# => :failed upon failure (<reasons>)
	# => :failed upon fatal error (<unhandeled exception>)
	def run(params=nil)
		begin
			setup.call     params if setup     != nil
			execution.call params if execution != nil
			teardown.call  params if teardown  != nil
		rescue TestIgnoreEx > ex
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

	def run
		@setup.call if @setup !=nil

		fixture_healthy = true
		results = {}
		if @list != nil && list.length > 0
			count = 0
			pre_run @name, @purpose if pre_run
			if @list[0].class == Test
				@list.each {  |t|

					pre_test_run.call t.name, t.purpose, count if pre_test_run

					result, output  = t.run @name
					results[t.name] = { :result => result, :output => output }
					fixture_healthy = result

					post_test_run.call t.name, t.purpose, result, count if post_test_run
					break if result != :passed && result != :ignored && @abort_on_first_failure
					
				}
			post_run @name, @purpose if post_run
			
			elsif @list[0].class == TestGroup
				# nested group
				@list.each {  |g|
					g.run( lambda {  |n,p| pre_run(n,p) if pre_run }, # pre_run
						   lambda {  |n,p| post_run(n,p) if post_run },
						   lambda {  |n,p,i| pre_test_run(n,p,i) if pre_test_run },
						   lambda {  |n,p,r,i| post_test_run(n,p,i) if post_test_run },
						)
				}
			end
		end

		@teardown.call if @teardown != nil
		return fixture_healthy, results
	end
end
