data = File.readlines('wires.txt')

def parse_data(line)
	line.split(',')
end

line1 = parse_data(data[0])
line2 = parse_data(data[1])

#line1 = parse_data('R75,D30,R83,U83,L12,D49,R71,U7,L72')
#line2 = parse_data('U62,R66,U55,R34,D71,R55,D58,R83')

#line1 = parse_data('R8,U5,L5,D3')
#line2 = parse_data('U7,R6,D4,L4')

class Point
	attr_reader :x, :y
	def initialize(x,y)
		@x = x.round
		@y = y.round
	end
	def to_s
		"(#{x}, #{y})"
	end
	def ==(other)
		x == other.x && y == other.y
	end
end

class Line
	attr_reader :p1, :p2
	def initialize(p1, p2)
		@p1 = p1
		@p2 = p2
	end
	def needs_sorting?
		p2.x < p1.x && horizontal? || 
		p2.y < p1.y && vertical?
	end
	def sort_points
		if needs_sorting?
			tmp = p1
			@p1 = p2
			@p2 = tmp
		end
	end
	def to_s
		"#{p1.to_s} - #{p2.to_s}"
	end
	def horizontal?
		p1.y == p2.y
	end
	def vertical?
		p1.x == p2.x
	end
	def length
		Integer.sqrt(
			(p1.x - p2.x)**2 + (p1.y - p2.y)**2
		)
	end
	def has_point?(p3)
		cross = (p3.y - p1.y) * (p2.x - p1.x) - (p3.x - p1.x) * (p2.y - p1.y)
		return false if cross.abs > 1
		
		dot = (p3.x - p1.x) * (p2.x - p1.x) + (p3.y - p1.y) * (p2.y - p1.y)
		return false if dot < 0
		
		return false if dot > (p1.x - p2.x)**2 + (p1.y - p2.y)**2
		
		true
	end
end

def parse_line(line)
	x = 0
	y = 0
	lines = []
	line.each do |move_to|
		direction = move_to[0]
		value = Integer(move_to[1..-1])
		p1 = Point.new(x,y)
		p2 = case direction.upcase
			when 'U'
				Point.new(x, y + value)
			when 'D'
				Point.new(x, y - value)
			when 'R'
				Point.new(x + value, y)
			when 'L'
				Point.new(x - value, y)
			end
		lines << Line.new(p1,p2)
		x = p2.x
		y = p2.y
	end
	lines
end

wire1 = parse_line(line1)
wire2 = parse_line(line2)

# http://www.izdebski.edu.pl/kategorie/Informatyka/Cwiczenie_02.pdf
# https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection - this probably has some errors?
def inter(l1,l2)
	# points have to be sorted by x and y 
	l1 = l1.dup
	l2 = l2.dup
	l1.sort_points
	l2.sort_points
	puts "Calculating for #{l1} and #{l2}"
	
	x1 = l1.p1.x
	x2 = l1.p2.x
	x3 = l2.p1.x
	x4 = l2.p2.x
	y1 = l1.p1.y
	y2 = l1.p2.y
	y3 = l2.p1.y
	y4 = l2.p2.y

	den = (x1-x2)*(y3-y4) - (y1-y2)*(x3-x4)
	if den.zero? # lines paraller or coincident
		puts "\tlines parallel"
		return nil
	end
	
	t_up = (x1-x3)*(y3-y4) - (y1-y3)*(x3-x4)
	u_up = (x1-x3)*(y1-y2) - (y1-y3)*(x1-x2) # izdebski

	t = t_up / den.to_f
	u = u_up / den.to_f
	
	unless t >= 0 && t <= 1 && u >= 0 && u <= 1
		puts "\tlines not crossing"
		return nil
	end
	
	puts "\tt: #{t}, u: #{u}"
	
	# below points should be equal
	point = Point.new(x1+t*((x2-x1).abs), y1+t*((y2-y1).abs))
	#puts "\ttp: #{point}"
	point = Point.new(x3+u*((x4-x3).abs), y3+u*((y4-y3).abs))
	#puts "\tup: #{point}"

	if 	l1.p1 == point ||
		l1.p2 == point ||
		l2.p1 == point ||
		l2.p2 == point
		puts "point on start/end of l1 or l2"
		return nil 
	end
	puts "\tFOUND: L1: #{l1}, L2: #{l2}, point=#{point}"
				
	point
end

# length from origin
def length_from_origin(point)
	point.x.abs + point.y.abs
end

def line_length_intersect(line, int_point)
	if !line.has_point?(int_point)
		puts "no point, add #{line.length}"
		return line.length
	else
		puts "intersection in line #{line} found at #{int_point}"
		line = Line.new(line.p1, int_point)
		puts "intersect length #{line.length}"
		return line.length
	end
end

intersections = []
w1_il = []
w2_il = []
wire1.each do |w1|
	wire2.each do |w2|
		x = inter(w1, w2) 
		if x
			intersections << x
		end
	end
end

puts "Intersections found:"
puts intersections

lenghts = intersections.map{ |x| length_from_origin(x) }.sort
puts "Closest:"
puts lenghts[0]

puts "------------- part2 ------------"

wire_int_lenghts = []
intersections.each do |int_point|
	int_len = [0,0]
	puts "w1"
	wire1.each do |line|
		inter_len = line_length_intersect(line, int_point)
		int_len[0] += inter_len
		break if inter_len != line.length # not full line means intersect
	end
	puts "w2"
	wire2.each do |line|
		inter_len = line_length_intersect(line, int_point)
		int_len[1] += inter_len
		break if inter_len != line.length # not full line means intersect	
	end
	puts "len: #{int_len}"
	wire_int_lenghts << int_len
end
puts "=----"
puts wire_int_lenghts.map { |a,b| a+b }.min
