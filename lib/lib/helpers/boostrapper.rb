$stdout.sync = true

require_relative "board.rb"
require_relative "serial_port.rb"
require_relative "protocol_base.rb"
require_relative "minilab_protocol.rb"
require_relative "uproto_protocol.rb"
require_relative "tst_runner.rb"
require_relative "tst_helpers.rb"
require_relative "tst_assert.rb"
require_relative "pins.rb"
require_relative "tst_extensions.rb"

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
		output += sprintf "%-#{max_length}.#{max_length}s : #{o}", t.name
		puts output
	}
	runner.execute $tests, $cli_options
rescue => ex
	eputs "Tests run error: #{ex.message}"
	eputs "At: #{ex.backtrace}"
	abort
end
