def fuel(mass)
	(mass / 3.0).floor - 2
end

total_fuel = 0

File.readlines('mass.txt').each do |line|
	mass = Integer(line)
	total_fuel += fuel(mass)
end

puts total_fuel
