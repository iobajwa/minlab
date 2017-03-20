
require_relative "tst_base.rb"

class TestRunner
	attr_accessor :test_pre_run, :test_post_run
	attr_accessor :test_group_pre_run, :test_group_post_run

	attr_accessor :depth

	@nested;
	@group_count; @test_count; @total_pass; @total_fail; @total_ignored; @total_errors; @total_skipped; 
	@results;

	@setup_code; @teardown_code;

	def initialize
		@depth = 0
	end

	def execute(jobs)
		@results = { :reports => {}, :stats => {} }
		@depth         = -1
		@group_count   = 0
		@test_count    = 0
		@total_pass    = 0
		@total_fail    = 0
		@total_ignored = 0
		@total_errors  = 0
		@total_skipped = 0

		@nested = false

		start = Time.now
			jobs.each {  |meta|
				_execute meta
			}
		finish = Time.now

		@results[:stats] = { 
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

	def setup &execution
		@setup_code = execution
	end

	def teardown &execution
		@teardown_code = execution
	end

	def _run_test meta

		begin
			@test_count += 1
			meta_setup    = meta[:setup]
			meta_teardown = meta[:teardown]
			execution     = meta[:execution]

			@setup_code.call    if @setup_code
			meta_setup.call     if meta_setup
			if execution
				execution.call
			else
				raise TestIgnoreEx.new, "<no test body found>"
			end
			meta_teardown.call  if meta_teardown
			@teardown_code.call if @teardown_code

		rescue TestSkipEx, TestIgnoreEx, TestFailureEx, ProtocolEx, Exception => ex
			begin 
				@teardown_code.call if @teardown_code
				meta_teardown.call  if teardown
			rescue
			end
			status = 
			case ex
				when TestSkipEx    then @total_skipped += 1; :skipped
				when TestIgnoreEx  then @total_ignored += 1; :ignored
				when TestFailureEx then @total_fail    += 1; :failed
				else @total_errors += 1; :error
			end

			return status, ex.message
		end

		@total_pass += 1
		return :passed, "ok"
	end

	def _execute meta
		@depth += 1

		test_name = meta[:name]
			# @test_group_pre_run.call test_name, @depth if @test_group_pre_run
			@test_pre_run.call test_name, @depth if @test_pre_run

			start_time = Time.now
			result, output = _run_test meta
			report = { :result => result, :output => output, :time => Time.now - start_time }

			# @test_group_post_run.call test_name, @depth if @test_group_post_run
			@test_post_run.call test_name, report, @depth if @test_post_run

		@depth -= 1
	end
end
