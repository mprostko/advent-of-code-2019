class Node
	attr_reader :name, :children
	attr_accessor :parent
	def initialize(name, parent)
		@name = name
		@parent = parent
		@children = []
	end
	def add_child(name, parent=self)
		# puts "adding #{name} to parent #{self.name}"
		children << Node.new(name, parent)
	end
	def ==(node)
		self.name == node.name
	end
	def find_by_name(name)
	  return self if self.name == name
	  children.each do |child|
		 node = child.find_by_name(name)
		 return node if node
	  end
	  nil
	end
	def orbits(level=0	) # -1 because we have a root planet
		children.map do |child|
			child.orbits(level+1) + level
		end.sum + children.count
	end
	def display(level=0)
		puts ' '*level + name
		children.each do |child|
			child.display(level+1)
		end
	end
end
 
root = Node.new('COM', nil)

raw_planets = []
File.readlines('planets.txt').each do |line|
	raw_planets << line.chomp
end
#raw_planets = %w[ COM)B B)C C)D D)E E)F B)G G)H D)I E)J J)K K)L ]
#raw_planets = %w[ D)E B)C C)D E)F B)G COM)B G)H D)I E)J J)K K)L ]

raw_planets.each do |orbit|
	target, orbiting = orbit.split(')')
	# puts "Traget: #{target}, Planet: #{orbiting}"
	target_planet = root.find_by_name(target)
	if target_planet # target_planet planet found
		target_planet.add_child(orbiting)
	else # target_planet not found, target_planet has not yet been added
		raw_planets << orbit
	end
end

puts root.orbits

santa = root.find_by_name('SAN')
you = root.find_by_name('YOU')

santa_to_com = []
you_to_com = []

planet = santa
while(planet.name != 'COM') do
	planet = planet.parent
	santa_to_com << planet.name
end
planet = you
while(planet.name != 'COM') do
	planet = planet.parent
	you_to_com << planet.name
end

santa_to_com = santa_to_com.reverse
you_to_com = you_to_com.reverse

while(true) do
	s1 = santa_to_com.shift
	s2 = you_to_com.shift
	puts s1
	break if s1 != s2
end

puts santa_to_com.count + you_to_com.count + 2
