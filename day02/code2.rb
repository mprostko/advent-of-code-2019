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

org_program = []
File.readlines('program.txt').each do |line|
	org_program = line.split(',').map{|x| Integer(x)}
end

values = (1..99).to_a.permutation(2).to_a

values.each do |noun, verb|
	program = org_program.dup
	program[1] = noun
	program[2] = verb
	x = Opcode.new(program).run
	if program[0] == 19690720
		puts 100 * noun + verb
		break
	end
end