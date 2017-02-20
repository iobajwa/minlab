
require_relative "tst_base.rb"

class TestRunner
	attr_accessor :test_group_pre_run, :test_group_post_run
	attr_accessor :test_pre_run, :test_post_run

	@depth

	def initialize
		@depth = 0
	end

	def execute(job, params={})
		@depth = -1
		_execute job, params
		@depth = -1
	end

	private
	def _execute(job, params, group=nil)
		# job can be a group, a group array, a test, a test array, or a mixed array
		job = [job] if job.class != Array

		results = {}
		@depth += 1
		job.each  {  |j|
			if j.class == Test

				@test_pre_run.call j, group, @depth if @test_pre_run
					result, output = j.run params
				@test_post_run.call j, result, output, group, @depth if @test_post_run

				results[j.name] = { :result => result, :output => output }

			elsif j.class == TestGroup

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
