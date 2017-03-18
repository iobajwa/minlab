=begin
	This file provides rudimentory minlab integration with RSpec.
	Make sure the project environment is properly loaded and setup before invoking rpec.

	1. create a new rspec workspace
	2. create the spec file (ex: device_spec.rb)
	3. add this following code at the top of the file:
		$LOAD_PATH.unshift(ENV['PROJECT_PATHS'].split(';')).flatten!
	4. enjoy.

	Step #3 basically adds every path in PROJECT_PATHS to the $LOAD_PATH. This helps ruby to
	find minlab and other helper libraries from installed packages.
=end


# include every file in ./helpers except for bootstrapper
all_ruby_files = File.join "#{File.expand_path(File.dirname(__FILE__))}/helpers/", "*.rb"
Dir[all_ruby_files].each {  |f| require "#{f}" unless File.basename(f, ".*") == "bootstrapper"  }

# and a bunch of helper methods
$assert = TestAssert.new
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
def connect_everything
	# create handy shortcuts for each defined board and connect with each
	Board.all_boards.each {  |b| 
		eval "$#{b.name} = b"
		eval "def #{b.name}() $#{b.name} end"
		b.connect 
	}
end
