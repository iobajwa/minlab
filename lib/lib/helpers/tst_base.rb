
class TestSetupEx < Exception
end

class TestFailureEx < Exception
end

class FatalEx < Exception
end

class TestIgnoreEx < Exception
end

class TestSkipEx < Exception
end

def fail message=''
	raise TestFailureEx.new message
end

def ignore message=''
	raise TestIgnoreEx.new message
end

def skip message=''
	raise TestSkipEx.new message
end
