
require_relative "tst_base.rb"

class TestRunner
	attr_accessor :test_group_pre_run, :test_group_post_run
	attr_accessor :test_pre_run, :test_post_run

	@depth; 
	@group_count; @test_count; @total_pass; @total_fail; @total_ignored; @total_errors; @total_skipped; 
	@results;

	def initialize
		@depth = 0
	end

	def execute(job, params={})
		@results = { :reports => {}, :stats => {} }
		@depth         = -1
		@group_count = 0
		@test_count    = 0
		@total_pass    = 0
		@total_fail    = 0
		@total_ignored = 0
		@total_errors  = 0
		@total_skipped = 0

		start = Time.now
			_execute job, params
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

	private
	def _execute(job, params, group=nil)
		# job can be a group, a group array, a test, a test array, or a mixed array
		job = [job] if job.class != Array

		@depth += 1
		job.each  {  |j|
			if j.class == Test

				@test_count += 1
				@test_pre_run.call j, group, @depth if @test_pre_run
					start_time = Time.now
					result, output = j.run params
					report = { :result => result, :output => output, :time => Time.now - start_time }
				@test_post_run.call j, report, group, @depth if @test_post_run

				@results[:reports][j.name] = report
				case result
				when :passed  then @total_pass += 1
				when :failed  then @total_fail += 1
				when :skipped then @total_skipped += 1
				when :ignored then @total_ignored += 1
				when :error   then @total_errors += 1
				end

			elsif j.class == TestGroup

				@group_count += 1
				@test_group_pre_run.call j, @depth if @test_group_pre_run
					j.run_setup params
						_execute j.list, params, j
					j.run_teardown params
				@test_group_post_run.call j, @depth if @test_group_post_run
			else
				raise "TestRunner: 'tests' array can only contain Test and/or TestGroup objects ('#{j.class}')"
			end
		}

		@depth -= 1
	end
end
