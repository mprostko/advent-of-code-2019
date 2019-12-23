require 'pry'
class Asteroid
	def initialize(x,y)
		# coodrs will be an array of [a,b] values 
		# that correspond to line y = ax + b
		@sight = []
		@x = x
		@y = y
	end
	
	def add_sight(a,b)
		#puts "Adding line #{a}, #{b} to #{@x}, #{@y}"
		if a == @x && b == @y # return if self
			#puts "it's self!"
			return
		end
		
		theta = angle_from_self(a,b) # rad
		#if theta < 0
		#	theta = 2*Math::PI - theta
		#end
		#theta = theta % 2*Math::PI
		
		theta = theta * 180 / Math::PI # deg 
		theta = -theta + 180
		debug =false
		if @x == 8 && @y == 3
			#debug = true
		end
		lenght = Math.sqrt((@x-a)**2 + (@y-b)**2)
		
		asteroid = find_by_angle(theta)
		if asteroid
			puts "Found on angle: #{theta}" if debug
			if asteroid['lenght'] > lenght
				puts "this is closer, #{asteroid['lenght']} > #{lenght}" if debug
				@sight.delete(asteroid)
				@sight << {
					'coords' => [a,b],
					'angle'  => theta,
					'lenght' => lenght
				}
			end
		else
			puts "Adding on angle #{theta}" if debug
			@sight << {
				'coords' => [a,b],
				'angle'  => theta,
				'lenght' => lenght
			}
		end
	end
	
	def find_by_angle(angle)
		@sight.find { |x| x['angle'] == angle }
	end
	
	def angle_from_self(a,b)
		delta_x = a - @x #@x - a
		delta_y = b - @y #-@y + b		
		Math.atan2(delta_x, delta_y)
	end
	
	def sights
		@sight
	end
	
	def coords
		[@x, @y]
	end

	def seeing
		@sight.count
	end
	
	def to_s
		coords.inspect
	end
end

class StarMap
	def initialize(data)
		@data = data.split("\n").map{ |x| x.split('') }
		@asteroids = []
	end
	
	def to_s
		@data.map do |row|
			row.join('')
		end.join("\n")
	end
	
	def mark(x, y, val='X')
		@data[y][x] = val
	end
	
	def run
		@asteroids = []
		@data.each_with_index do |row, y|
			row.each_with_index do |space, x|
				if space == '#'
					@asteroids << Asteroid.new(x,y)
				end
			end
		end
		max_seeing = -1
		max_seeing_asteroid = nil
		@asteroids.each do |aster|
			@asteroids.each do |asteroid|
				aster.add_sight(*asteroid.coords)
			end
			seeing = aster.seeing
			if seeing > max_seeing
				max_seeing = seeing
				max_seeing_asteroid = aster
			end
		end
		puts "Max is #{max_seeing} at #{max_seeing_asteroid.coords.inspect}"
		max_seeing_asteroid
	end
	
	def scan(x, y)
		asteroid = @asteroids.find { |ast| ast.coords == [x,y] }
		ser = asteroid.sights.sort { |a,b| a['angle'] <=> b['angle'] }	
		vals = ('0'..'9').to_a + ('a'..'z').to_a
		ser.each_with_index do |s, index|
			mark(s['coords'][0], s['coords'][1], vals[index]) 
		end
	end
	
	def scan_and_destroy(x, y, idx=1)
		asteroid = @asteroids.find { |ast| ast.coords == [x,y] }
		ser = asteroid.sights.sort { |a,b| a['angle'] <=> b['angle'] }	
		ser.each_with_index do |s, index|
			if index + idx == 200
				puts "200th asteroid is at #{s['coords']}"
				return -1
			end
			mark(s['coords'][0], s['coords'][1], '.') 
		end
		ser.count
	end
end

data =<<-EOF 
#...##.####.#.......#.##..##.#.
#.##.#..#..#...##..##.##.#.....
#..#####.#......#..#....#.###.#
...#.#.#...#..#.....#..#..#.#..
.#.....##..#...#..#.#...##.....
##.....#..........##..#......##
.##..##.#.#....##..##.......#..
#.##.##....###..#...##...##....
##.#.#............##..#...##..#
###..##.###.....#.##...####....
...##..#...##...##..#.#..#...#.
..#.#.##.#.#.#####.#....####.#.
#......###.##....#...#...#...##
.....#...#.#.#.#....#...#......
#..#.#.#..#....#..#...#..#..##.
#.....#..##.....#...###..#..#.#
.....####.#..#...##..#..#..#..#
..#.....#.#........#.#.##..####
.#.....##..#.##.....#...###....
###.###....#..#..#.....#####...
#..##.##..##.#.#....#.#......#.
.#....#.##..#.#.#.......##.....
##.##...#...#....###.#....#....
.....#.######.#.#..#..#.#.....#
.#..#.##.#....#.##..#.#...##..#
.##.###..#..#..#.###...#####.#.
#...#...........#.....#.......#
#....##.#.#..##...#..####...#..
#.####......#####.....#.##..#..
.#...#....#...##..##.#.#......#
#..###.....##.#.......#.##...##
EOF

x = StarMap.new(data)
max = x.run
x.mark(*max.coords)
x.scan_and_destroy(*max.coords)