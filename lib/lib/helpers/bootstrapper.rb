$stdout.sync = true

# automagically include every file in this folder, except for this file
all_ruby_files = File.join File.expand_path(File.dirname(__FILE__)), "*.rb"
Dir[all_ruby_files].each {  |f| require "#{f}" unless f == __FILE__ }

# get any --com_port and --baud_rate settings passed from CLI
$cli_options, $cli_files = OptionMaker.parse ARGV

# load wiring
begin
	# find a valid wiring file and load it
	f = find_file ['wirings.rb', 'wiring.rb']
	abort "wiring file was not given and neither could find any." unless f
	require "#{f}"

	# create handy shortcut pin getter functions
	abort "No boards defined!" if Board.all_boards.length == 0
	Board.all_boards.each {  |board|
		board.pins.each_pair {  |pin_name, pin|
			eval "$#{pin_name} = Board.get_board('#{board.name}').pins['#{pin_name}']"
			eval "def #{pin_name}() $#{pin_name} end"
		}
	}

	# connect with every board
	Board.all_boards.each {  |b| b.connect }
rescue => ex
	eputs "Wiring error: #{ex.message}"
	eputs "At: #{ex.backtrace}"
	abort
end


# create public level methods for tests, test_groups, test asserts
$tests  = []
$assert = TestAssert.new

def register_tests(val)  $tests = val end
# def tests=(val) $tests = val end
def tests()     $tests       end
def assert()    $assert      end


# load tests
begin
	# find a valid test file and load it
	# find a valid wiring file and load it
	f = find_file ['tests.rb', 'test.rb']
	abort "test file was not given and neither could find any." unless f
	require "#{f}"
rescue => ex
	eputs "Tests declaration error: #{ex.message}"
	eputs "At: #{ex.backtrace}"
	abort
end
abort "No tests defined! Make sure tests were properly added." if $tests == nil || $tests.class != Array || $tests.length == 0
$tests.flatten!


# execute tests
begin
	runner = TestRunner.new
	max_test_name_length = 0
	runner.test_group_pre_run  = Proc.new {  |g, depth| puts "  " * depth + "#{g.name}" }
	runner.test_group_post_run = Proc.new { puts "" }
	runner.test_post_run       = Proc.new {  |t, r, o, g, depth|
		max_length = g.list_max_name_length
		output = "  " * depth
		output += sprintf "%-#{max_length}.#{max_length}s", t.name
		if r != :passed
			case r
			when :skipped then output += " : NA"
			when :ignored then output += " : IGNORED"
			when :error   then output += " : ERROR"
			when :failed  then output += " : FAIL"
			end
			output += " : #{o}" unless o.length == 0
		end
		puts output
	}
	results = runner.execute $tests, $cli_options
	puts "-----------------------"
	total_groups  = results[:stats][:total_groups]
	total_tests   = results[:stats][:total_tests]
	total_pass    = results[:stats][:total_pass]
	total_fail    = results[:stats][:total_fail]
	total_ignored = results[:stats][:total_ignored]
	total_errors  = results[:stats][:total_errors]
	total_skipped = results[:stats][:total_skipped]
	total_time    = results[:stats][:total_time]
	summary_statement = "#{total_groups} Groups #{total_tests} Tests"
	summary_statement += " #{total_fail} Failures" if total_fail > 0
	summary_statement += " #{total_errors} Errors " if total_errors > 0
	summary_statement += " #{total_ignored} Ignored " if total_ignored > 0
	summary_statement += "#{total_skipped} Skipped" if total_skipped > 0
	puts summary_statement
	puts "#{total_time} seconds"
	puts ""
	if total_fail > 0 || total_errors > 0
		puts "FAIL"
	else
		puts "OK" 
	end
rescue => ex
	eputs "Tests run error: #{ex.message}"
	eputs "At: #{ex.backtrace}"
	abort
end
