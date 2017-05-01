
require_relative "tst_base.rb"

class TestRunner
	attr_accessor :test_pre_run, :test_post_run
	attr_accessor :test_group_pre_run, :test_group_post_run

	@group_count; @test_count; @total_pass; @total_fail; @total_ignored; @total_errors; @total_skipped; 
	@results; @depth;

	@teardown_hook_table;

	@execution_pipeline

	@filter_only

	def initialize filter_only=[]
		@depth = 0
		@execution_pipeline = []
		@filter_only = filter_only == nil ? [] : filter_only
	end

	def get_active_job_in_pipeline
		return @execution_pipeline.last
	end

	def pipeline
		return @execution_pipeline
	end

	def job_passes_only_filter title=nil
		return true if @filter_only.length < 1

		@filter_only.each {  |n|
			i = 0
			matched = true
			@execution_pipeline.each {  |e|
				e = e[:name].downcase
				return true if i > n.length - 1 && n.length > 0
				if n[i].downcase != e
					matched = false
					break
				end
				i += 1
			}
			return true if matched
		}
		return false
	end

	def hook_teardown name, type, caller_body, teardown_body
		@teardown_hook_table.push( { :name => name, :type => type, :caller => caller_body, :code => teardown_body } )
	end

	def get_teardown_code name, type, caller_body
		top_hook = @teardown_hook_table.sample
		return nil unless top_hook
		return nil unless top_hook[:name] == name
		return nil unless top_hook[:type] == type
		return nil unless top_hook[:caller] == caller_body
		
		return @teardown_hook_table.pop[:code]
	end

	def execute jobs
		@results = { :reports => {}, :stats => {} }
		@depth         = 0
		@group_count   = 0
		@test_count    = 0
		@total_pass    = 0
		@total_fail    = 0
		@total_ignored = 0
		@total_errors  = 0
		@total_skipped = 0
		@execution_pipeline  = []
		@teardown_hook_table = []

		start = Time.now
			jobs.each {  |meta|  _execute_group meta  }
		finish = Time.now

		@results[:stats] = { 
			:total_groups  => @group_count,
			:total_tests   => @test_count,
			:total_pass    => @total_pass,
			:total_fail    => @total_fail,
			:total_ignored => @total_ignored,
			:total_errors  => @total_errors,
			:total_skipped => @total_skipped,
			:total_time    => finish - start
		}
		
		return @results
	end

	def _run_test meta
		name = meta[:name]
		@execution_pipeline.push( { :type => :test, :name => name, :meta => meta } )
		
		status  = nil; 
		message = '';

		begin
			raise TestIgnoreEx.new '' unless job_passes_only_filter name
		
			@test_count += 1
			meta_setup    = meta[:setup]
			meta_teardown = meta[:teardown]
			body          = meta[:body]

			meta_setup.call if meta_setup
			if body
				body.call
			else
				raise TestIgnoreEx.new, "<no test body provided>"
			end
			teardown_hook = get_teardown_code name, :test, body
			teardown_hook.call if teardown_hook
			meta_teardown.call if meta_teardown

			@total_pass += 1
			status  = :passed
			message = "ok"

		rescue TestSkipEx, TestIgnoreEx, TestFailureEx, ProtocolEx, Exception => ex
			begin
				teardown_hook = get_teardown_code name, :test, body
				teardown_hook.call if teardown_hook
			rescue
			end
			begin
				meta_teardown.call if meta_teardown
			rescue
			end
			status = 
			case ex
				when TestSkipEx    then @total_skipped += 1; :skipped
				when TestIgnoreEx  then @total_ignored += 1; :ignored
				when TestFailureEx then @total_fail    += 1; :failed
				else @total_errors += 1; :error; raise ex
			end

			message = ex.message
		end

		@execution_pipeline.pop

		return status, message
	end

	def _execute_group meta
		name          = meta[:name]
		body          = meta[:body]
		setup_code    = meta[:setup]
		teardown_code = meta[:teardown]
		@execution_pipeline.push( { :type => :group, :name => name, :meta => meta } )

		@depth += 1

		unless job_passes_only_filter name
			@execution_pipeline.pop
			@depth -= 1
			return
		end

		@group_count += 1
		@test_group_pre_run.call name, @depth if @test_group_pre_run

			setup_code.call    if setup_code
			body.call          if body
			teardown_code.call if teardown_code
		@depth -= 1

		@test_group_post_run.call name, @depth if @test_group_post_run

		@execution_pipeline.pop
	end

	def _execute_test meta
		name = meta[:name]

		@test_pre_run.call name, @depth if @test_pre_run

			start_time = Time.now
			result, output = _run_test meta
			report = { :result => result, :output => output, :time => Time.now - start_time }

		@test_post_run.call name, report, @depth if @test_post_run
	
	end
end
