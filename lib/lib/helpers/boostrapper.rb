
# get any --com_port and --baud_rate settings passed from CLI

[ 
	"board.rb",
	"protocol_base.rb",
	"tst_helpers.rb",
	"tst_assert.rb",
	"pins.rb",
	"tst_extensions.rb"
].each {|req| require "#{File.expand_path(File.dirname(__FILE__))}/#{req}"}


# load wiring
begin
	# require 'wirings.rb'
	# create pin getter functions
rescue => ex
	eputs "Wiring error: #{ex.message}"
	abort
end

begin
	Board.all_boards.each {  |b| board.connect unless board.connected? }
rescue => ex
	eputs "Setup error: #{ex.message}"
	abort
end


# create public level methods for tests, test_groups, test asserts
$tests    = []
$assert = TestAssert.new

def tests()     $tests       end
def tests=(val) $tests = val end
def assert()    $assert      end


# load tests
begin
	# require 'tests.rb'
rescue => ex
	eputs "Wiring error: #{ex.message}"
	abort
end


# execute tests
begin
	TestRunner.run $tests
rescue => ex
end
