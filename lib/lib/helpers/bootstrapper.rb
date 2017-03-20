$stdout.sync = true

# automagically include every file in this folder, except for this file
all_ruby_files = File.join File.expand_path(File.dirname(__FILE__)), "*.rb"
Dir[all_ruby_files].each {  |f| require "#{f}" unless f == __FILE__ }


# get any --com_port and --baud_rate settings passed from CLI
$cli_options, $cli_files = OptionMaker.parse ARGV


# make sure settings make sense
$cli_options[:repeat_count] = 1 if $cli_options[:repeat_count] == nil || $cli_options[:repeat_count] == 0
verbose = ( $cli_options.include?(:v) || $cli_options.include?(:verbose) ) ? true : false


$assert = TestAssert.new
$__tg_register = []
$__tg_count = 0

# create public level methods for tests, test_groups, test asserts
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
def disconnect_all_boards
	# it makes sense to start disconnecting from the last board that was created. This is a simple way around the :gateway problem. :D
	Board.all_boards.reverse.each {  |b| b.disconnect  }
end
def test name, purpose='', setup=nil, teardown=nil, &execution
	$__tg_register[$__tg_count] = { :name => name, :purpose => purpose, :setup => setup, :teardown => teardown, :execution => execution }
	$__tg_count += 1
end


# useful overrides
def sandbox() end
def on_abort()  end
def wait() forever end


# load passed files
$SANDBOXING = true
$assert.silent = true
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
rescue Interrupt => e
	on_abort
	disconnect_all_boards
	abort "\naborted."
rescue Exception => ex
	eputs "\n\nWIRING ERROR: #{ex.message}"
	if verbose
		eputs "At:\n"
		ex.backtrace.each {  |b| eputs "\t" + b  }
	end
	abort
end


# cannot define these aliases before the user files are included coz ruby won't update the aliases to new overrides
[:on_exit, :when_aborted, :when_aborting, :on_aborting].each {  |m| (class << self; self; end).send :alias_method, m, :on_abort }
[:sandboxing, :sandbox_code, :sandboxing_code, :sb ].each    {  |m| (class << self; self; end).send :alias_method, m, :sandbox }


# invoke sandbox functions if asked to do so
found_atleast_one_func = false
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
rescue RubySerial::Exception, ProtocolEx, Exception => ex
	eputs "\n\nSANDBOXING ERROR: #{ex.message}"
	eputs "At:\n" if verbose
	ex.backtrace.each {  |b| eputs "\t" + b  } if verbose
	abort
end
exit if found_atleast_one_func
$assert.silent = false
$SANDBOXING = false


# otherwise execute the tests
abort "No tests defined! Make sure tests were properly added." if $__tg_count == 0 && verbose
exit if $__tg_count == 0		# sometimes we use minlab just for sandboxing



$__test_runner = TestRunner.new

# override test for nested blocks
def test name, purpose='', setup=nil, teardown=nil, &execution
	meta = {}
	meta[:name]      = name
	meta[:purpose]   = purpose
	meta[:setup]     = setup
	meta[:teardown]  = teardown
	meta[:execution] = execution
	$__test_runner._execute meta
end

begin
	$__test_runner.test_group_pre_run = Proc.new {  |name, depth| puts "HERE"; puts ""; puts "  " * depth + "#{name}" }
	$__test_runner.test_pre_run = Proc.new {
	|name, depth|
		output = "\n"
		output += "  " * depth
		output += name
		print output
	}
	$__test_runner.test_post_run = Proc.new {
	|name, report, depth|
		output = ""
		result = report[:result]
		case result
		when :skipped then output += " : NA"
		when :ignored then output += " : IGNORED"
		when :error   then output += " : ERROR"
		when :failed  then output += " : FAIL"
		end
		output += " : #{report[:output]}" unless report[:output].length == 0 || result == :passed
		output += " : #{sprintf "%3.3f", report[:time]} seconds" if verbose
		print output
	}

	results = $__test_runner.execute $__tg_register
	
	# print summary
	puts "\n-----------------------"
	total_groups  = results[:stats][:total_groups]
	total_tests   = results[:stats][:total_tests]
	total_pass    = results[:stats][:total_pass]
	total_fail    = results[:stats][:total_fail]
	total_ignored = results[:stats][:total_ignored]
	total_errors  = results[:stats][:total_errors]
	total_skipped = results[:stats][:total_skipped]
	total_time    = results[:stats][:total_time]
	summary_statement = "#{total_tests} Tests"
	summary_statement += "  #{total_fail} Failures"   if total_fail > 0
	summary_statement += "  #{total_errors} Errors"   if total_errors > 0
	summary_statement += "  #{total_ignored} Ignored" if total_ignored > 0
	summary_statement += "  #{total_skipped} Skipped" if total_skipped > 0
	puts summary_statement
	puts "#{$assert.assert_count} Asserts  #{sprintf "%3.3f", total_time} seconds"
	puts ""
rescue RubySerial::Exception, Exception => ex
	disconnect_all_boards unless ex.class == RubySerial::Exception
	eputs "\n\nTESTS ERROR:\n\t#{ex.message}"
	eputs "At:\n" if verbose
	ex.backtrace.each {  |b| eputs "\t" + b  } if verbose
	abort
rescue Interrupt => e
	on_abort
	disconnect_all_boards
	eputs "\n\nTESTS ABORTED!"
	abort "FAIL"
end

if total_errors > 0
	abort "ERROR"
elsif total_fail > 0
	abort "FAIL"
else
	puts "OK" 
end

