require 'pry'
class Moon
	attr_accessor :x, :y, :z, :vx, :vy, :vz
	def initialize(pos_x, pos_y, pos_z)
		@x = pos_x
		@y = pos_y
		@z = pos_z
		@vx = 0
		@vy = 0
		@vz = 0
	end
	def position
		[x,y,z]
	end
	def velocity
		[vx,vy,vz]
	end
	def apply_gravity(other)
		apply_gravity_x(other)
		apply_gravity_y(other)
		apply_gravity_z(other)
	end
	def apply_gravity_x(other)
		dx = @x <=> other.x
		@vx -= dx
		other.vx += dx
	end
	def apply_gravity_y(other)
		dy = @y <=> other.y
		@vy -= dy
		other.vy += dy
	end
	def apply_gravity_z(other)
		dz = @z <=> other.z
		@vz -= dz
		other.vz += dz
	end
	def pot
		position.map(&:abs).sum
	end
	def kin
		velocity.map(&:abs).sum
	end
	def energy
		pot * kin
	end
	def apply_velocity
		@x += @vx
		@y += @vy
		@z += @vz
	end
	def to_s
		"pos=<x=#{x}, y=#{y}, z=#{z}>,\tvel=<x=#{vx}, y=#{vy}, z=#{vz}>"
	end
end

m1 = Moon.new(0, 4, 0)
m2 = Moon.new(-10,-6, -14)
m3 = Moon.new(9,-16,-3)
m4 = Moon.new(6,-1,2)

galaxy = [m1,m2,m3,m4]
pairs = galaxy.combination(2)


1000.times do |index|
	pairs.each do |a,b|
		a.apply_gravity(b)
	end
	galaxy.each(&:apply_velocity)
end

puts m1
puts m2
puts m3
puts m4
puts

puts galaxy.map(&:energy).sum

# =========================================

m1 = Moon.new(0,4,0)
m2 = Moon.new(-10,-6,-14)
m3 = Moon.new(9,-16,-3)
m4 = Moon.new(6,-1,2)
galaxy = [m1,m2,m3,m4]
pairs = galaxy.combination(2)

lcm = []
[0,1,2].each do |axis|
	loops = 1
	while(1) do
		pairs.each do |a,b|
			case axis
			when 0
				a.apply_gravity_x(b)
			when 1
				a.apply_gravity_y(b)
			when 2
				a.apply_gravity_z(b)
			end
			
		end
		galaxy.each(&:apply_velocity)
		if 	m1.position[axis] == [0,4,0][axis] &&
			m2.position[axis] == [-10,-6,-14][axis] &&
			m3.position[axis] == [9,-16,-3][axis] &&
			m4.position[axis] == [6,-1,2][axis] &&
			m1.velocity == [0,0,0] &&
			m2.velocity == [0,0,0] &&
			m3.velocity == [0,0,0] &&
			m4.velocity == [0,0,0]
				lcm << loops 
				break
		end
		loops += 1
	end
end
puts lcm.reduce(1, :lcm)

