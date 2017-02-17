
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
	attr_accessor :name, :purpose, :tests, :setup, :teardown
	attr_accessor :abort_on_first_failure

	# by default a test-suite is aborted 
	def initialize(name, purpose, tests, setup=nil, teardown=nil)
		@name     = name
		@purpose  = purpose
		tests = [tests] if tests.class != Array
		@tests    = tests
		@setup    = setup
		@teardown = teardown
		@abort_on_first_failure = false
	end

	def run(pre_run=nil, post_run=nil, pre_test_run=nil, post_test_run=nil)
		@setup.call if @setup !=nil

		fixture_healthy = true
		results = {}
		if @tests != nil && tests.length > 0
			count = 0
			pre_run @name, @purpose if pre_run
			if @tests[0].class == Test
				@tests.each {  |t|

					pre_test_run.call t.name, t.purpose, count if pre_test_run

					result, output  = t.run @name
					results[t.name] = { :result => result, :output => output }
					fixture_healthy = result

					post_test_run.call t.name, t.purpose, result, count if post_test_run
					break if result != :passed && result != :ignored && @abort_on_first_failure
					
				}
			post_run @name, @purpose if post_run
			
			elsif @tests[0].class == TestGroup
				# nested group
				@tests.each {  |g|
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
