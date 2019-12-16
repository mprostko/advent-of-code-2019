class Opcode
	class EndOfCode < StandardError
	end 
	
	def initialize(program)
		@pc = program
	end

	def write(position, value)
		@pc[position] = value
	end

	def read(position)
		@pc[position]
	end

	def run
		@pc.each_slice(4) do |opcode, pos_a, pos_b, pos_o|
			value = opcode(opcode, pos_a, pos_b)
			write(pos_o, value)
		end
	rescue EndOfCode
	end

	def opcode(code, pos_a, pos_b)
		a = read(pos_a)
		b = read(pos_b)
		value = case(code)
		when 1
			a + b
		when 2
			a * b	
		when 99
			raise EndOfCode
		end
	end
end

program = []
File.readlines('program.txt').each do |line|
	program = line.split(',').map{|x| Integer(x)}
end

# replace positions
program[1] = 12
program[2] = 2

x = Opcode.new(program).run

puts program[0]	