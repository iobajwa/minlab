
class TestFailureEx < Exception
end

class TestSetupEx < Exception
end

class FatalEx < Exception
end

class Scale
	def Scale.convert value, from, to
		from = (from.last..from.first) if from.first > from.last
		to = (to.last..to.first) if to.first > to.last
		return to.first if value <= from.first
		return to.last if value >= from.last

		value *= 1.0
		return ((to.last - to.first) * ( (value - from.first) / (from.last - from.first) ) + to.first).round
	end

	def Scale.convert_percent value, scale
		raise "Not Implemented!"
	end
end
