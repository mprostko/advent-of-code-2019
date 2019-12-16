def fuel(mass)
	(mass / 3.0).floor - 2
end

total_fuel = 0

File.readlines('mass.txt').each do |line|
	mass = Integer(line)
	fuel_for_mass = fuel(mass)
	while(fuel_for_mass > 0) do
		total_fuel += fuel_for_mass
		fuel_for_mass = fuel(fuel_for_mass)
	end
end

puts total_fuel
