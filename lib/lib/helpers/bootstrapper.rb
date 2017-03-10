$stdout.sync = true

# automagically include every file in this folder, except for this file
all_ruby_files = File.join File.expand_path(File.dirname(__FILE__)), "*.rb"
Dir[all_ruby_files].each {  |f| require "#{f}" unless f == __FILE__ }


# get any --com_port and --baud_rate settings passed from CLI
$cli_options, $cli_files = OptionMaker.parse ARGV


# make sure settings make sense
$cli_options[:repeat_count] = 1 if $cli_options[:repeat_count] == nil || $cli_options[:repeat_count] == 0
verbose = ( $cli_options.include?(:v) || $cli_options.include?(:verbose) ) ? true : false


# create public level methods for tests, test_groups, test asserts
$tests  = []
$assert = TestAssert.new
def tests()     $tests       end
def assert()    $assert      end
def settings()  $cli_options end
def wire board, pin_name, pin_number, type, meta={}
	board = Board.get_board board if board.class == String
	pin = board.wire pin_name, pin_number, type, meta
	eval "$#{pin_name} = pin"
	eval "def #{pin_name}() $#{pin_name} end"
end
def wire_net name, pins
	net = PinNetwork.new name, pins
	eval "$#{name} = net"
	eval "def #{name}() $#{name} end"
end
def register_tests(val)  $tests = val end

# useful overrides
def workbench() end
def on_abort()  end
def wait() forever end



# load passed files
begin
	if $cli_files.length == 0
		# see if there is a single ruby file in the current working directory, if so, assume it to be the test file
		ruby_files = File.join File.expand_path(Dir.pwd), "*.rb"
		ruby_files = Dir[ruby_files]
		abort "no test script found" if ruby_files.length == 0
		abort "multiple scripts available in '#{Dir.pwd}' (#{ruby_files.length}).\nplease specify the actual test script." if ruby_files.length > 1
		require "#{ruby_files[0]}"
	else
		$cli_files.each {  |cf|
			f = File.absolute_path cf
			require "#{f}"
		}
	end

	# create handy shortcuts for each defined board and connect with each
	Board.all_boards.each {  |b| 
		eval "$#{b.name} = b"
		eval "def #{b.name}() $#{b.name} end"
		b.connect 
	}
rescue RubySerial::Exception => ex
	eputs "Wiring error:\n\t#{ex.message}"
	eputs "At:\n"
	ex.backtrace.each {  |b| eputs "\t" + b  }
	abort
rescue => ex
	eputs "Wiring error:\n\t#{ex.message}"
	eputs "At:\n"
	ex.backtrace.each {  |b| eputs "\t" + b  }
	abort
end

def disconnect_all_boards
	# it makes sense to start disconnecting from the last board that was created. This is a simple way around the :gateway problem. :D
	Board.all_boards.reverse.each {  |b| b.disconnect  }
end


# cannot define these aliases before the user files are included coz ruby won't update the aliases to new overrides
[:on_exit, :when_aborted, :when_aborting, :on_aborting].each         {  |m| (class << self; self; end).send :alias_method, m, :on_abort }
[:workbench_code, :playground, :scratchpad, :scratch, :wb, :pg].each {  |m| (class << self; self; end).send :alias_method, m, :workbench }


# invoke workbench functions if asked to do so
found_atleast_one_func = false
$assert.silent = true
begin
	$cli_options.each_pair {  |k, v|
		if self.private_methods.include? k.to_sym            # black magic
			self.send k.to_sym
			found_atleast_one_func = true
		end
	}
rescue Interrupt => e
	on_abort
	disconnect_all_boards
	abort "\naborted."
rescue RubySerial::Exception => ex
	eputs "Workbench error:\n\t#{ex.message}"
	eputs "At:\n"
	ex.backtrace.each {  |b| eputs "\t" + b  }
	abort
rescue => ex
	eputs "Workbench error:\n\t#{ex.message}"
	eputs "At:\n"
	ex.backtrace.each {  |b| eputs "\t" + b  }
	abort
end
exit if found_atleast_one_func
$assert.silent = false


# otherwise execute the tests
abort "No tests defined! Make sure tests were properly added." if $tests == nil || $tests.class != Array || $tests.length == 0
$tests.flatten!

begin
	runner = TestRunner.new
	max_test_name_length = 0
	runner.test_group_pre_run  = Proc.new {  |g, depth| puts ""; puts "  " * depth + "#{g.name}" }
	runner.test_pre_run        = Proc.new {  |t, g, depth| 
		max_length = g ? g.list_max_name_length : t.name.length    # g might not even exist
		output = "  " * depth
		output += sprintf "%-#{max_length}.#{max_length}s", t.name
		print output
	}
	runner.test_post_run = Proc.new {  |t, report, g, depth|
		output = ""
		result = report[:result]
		case result
		when :passed then output += " : OK"
		when :skipped then output += " : NA"
		when :ignored then output += " : IGNORED"
		when :error   then output += " : ERROR"
		when :failed  then output += " : FAIL"
		end
		output += " : #{report[:output]}" unless report[:output].length == 0 || result == :passed
		output += " : #{sprintf "%3.3f", report[:time]} seconds" if verbose
		puts output
	}
	results = runner.execute $tests, $cli_options
	
	# print summary
	puts "-----------------------"
	total_groups  = results[:stats][:total_groups]
	total_tests   = results[:stats][:total_tests]
	total_pass    = results[:stats][:total_pass]
	total_fail    = results[:stats][:total_fail]
	total_ignored = results[:stats][:total_ignored]
	total_errors  = results[:stats][:total_errors]
	total_skipped = results[:stats][:total_skipped]
	total_time    = results[:stats][:total_time]
	summary_statement = "#{total_groups} Groups  #{total_tests} Tests"
	summary_statement += "  #{total_fail} Failures"   if total_fail > 0
	summary_statement += "  #{total_errors} Errors"   if total_errors > 0
	summary_statement += "  #{total_ignored} Ignored" if total_ignored > 0
	summary_statement += "  #{total_skipped} Skipped" if total_skipped > 0
	puts summary_statement
	puts "#{$assert.assert_count} Asserts  #{sprintf "%3.3f", total_time} seconds"
	puts ""
	if total_fail > 0 || total_errors > 0
		abort "FAIL"
	else
		puts "OK" 
	end

rescue RubySerial::Exception => ex
	eputs "Tests error:\n\t#{ex.message}"
	eputs "At:\n"
	ex.backtrace.each {  |b| eputs "\t" + b  }
	abort
rescue Interrupt => e
	on_abort
	disconnect_all_boards
	eputs "\n\nTESTS ABORTED!"
	abort "FAIL"
rescue => ex
	disconnect_all_boards
	eputs "Tests error:\n\t#{ex.message}"
	eputs "At:\n"
	ex.backtrace.each {  |b| eputs "\t" + b  }
	abort
end
