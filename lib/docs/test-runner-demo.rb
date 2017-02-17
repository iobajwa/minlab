
require "bridge"
require "bots"

# load the config file
boards = parse_and_build_boards 'config.yaml'

# force pin naming conventions
boards.each {  |b| Conventionizer.apply_pin_naming_conventions b.pins }

boards.connect

# create public level methods for pin objects (so that user_test_file can access these)
pins = []
boards.each {  |b| pins << b.pins }
pins.flatten!

pins.each {  |p| eval( "def #{p.name}() p end" ) }


# create public level methods for tests, fixtures, test harness
$fixtures = []
$tests    = []
$test_harness = TestHarness.new

def fixtures()  $fixtures  end
def tests() tests end


require "user_test_file"


begin
	fixtures.each {  |f| 
		status, results = f.run 
	}
rescue => ex

end
