 require 'pry'
require 'rspec'

class Opcode
  class EndOfCode < StandardError
  end

  def initialize(program)
    @pc = program.dup
    @ip = 0
    @input = nil
  end

  def write(position, value)
    #puts "writing #{value} at pos #{position}"
    @pc[position] = value
  end

  def read(position)
    #puts "readin from position #{position}, value: #{@pc[position]}"
    @pc[position]
  end

  def run(input=nil)
    return_value = nil
    @input = input ? Array(input) : nil
	while(1) do
      # puts "PC b4: #{@pc}. @IP=#{@ip}"
      ret = next_step
      return_value = ret if ret
    end
  rescue EndOfCode
    return_value
  end

  def decode_opcode
    code = read(@ip)
    #puts "Decoded command #{code}"
    instruction = code % 100
    code = code / 100
    mode_param_c = code % 10
    code = code / 10
    mode_param_b = code % 10
    code = code / 10
    mode_param_a = code % 10

    [mode_param_c, mode_param_b, mode_param_a, instruction]
  end

  def parameter(address, type)
    value = read(address)
    if type == 1 # type immediate
      #puts "param from address #{address} in immediate mode, value = #{value}"
      value
    else # type position
      #puts "param from address #{address} in position mode, value = #{read(value)}"
      read(value)
    end
  end

  def next_step
    jump = false
    mc,mb,ma,instruction = decode_opcode
    #puts "CBA = #{mc}, #{mb}, #{ma}"

    case(instruction)
    when 1
      #puts "ADD CMD"
      c = parameter(@ip+1, mc)
      b = parameter(@ip+2, mb)
      a = parameter(@ip+3, 1) # always immidiate
      @ip += 3
      write(a, c + b)
    when 2
      #puts "MULTIPLY CMD"
      c = parameter(@ip+1, mc)
      b = parameter(@ip+2, mb)
      a = parameter(@ip+3, 1) # always immidiate
      a = read(@ip+3)
      @ip += 3
      write(a, c * b)
    when 3
      #puts "INPUT CMD"
      c = parameter(@ip+1, 1) # always immidiate
      input = if @input
        @input.shift
      else
        puts "Input required: "
        Integer(gets.chomp)
      end
      @ip += 1
      puts "writing input = #{input} to addr #{c}"
      write(c, input)
    when 4
      #puts "OUTPUT CMD"
      value = parameter(@ip+1, mc)
      @ip += 2 # 1 from paramteer, second because we're missing the ip+1 from the ed of the switch by using return
      puts "Output: #{value}"
      return value
    when 5
      #puts "JIT CMD" # jump if true
      c = parameter(@ip+1, mc)
      b = parameter(@ip+2, mb)
      #puts "JIT, c=#{c}, jumpto=#{b}"
      if c > 0
        #puts "jumping to #{c}"
        jump = true
        @ip = b
      else
        @ip += 2
      end
    when 6
      #puts "JIF CMD" # jump if false
      c = parameter(@ip+1, mc)
      b = parameter(@ip+2, mb)
      #puts "JIT, c=#{c}, jumpto=#{b}"
      if c == 0
        #puts "jumping to #{c}"
        jump = true
        @ip = b
      else
        @ip += 2
      end
    when 7
      #puts "LT CMD"
      c = parameter(@ip+1, mc)
      b = parameter(@ip+2, mb)
      a = parameter(@ip+3, 1) # always immidiate
      @ip += 3
      #puts "LT #{c} < #{b}, output to #{a}"
      write(a, c < b && 1 || 0) # change true/false to integer
    when 8
      #puts "EQ CMD"
      c = parameter(@ip+1, mc)
      b = parameter(@ip+2, mb)
      a = parameter(@ip+3, 1) # always immidiate
      @ip += 3
      #puts "EQ #{c} == #{b}, write #{c == b} to addr #{a}"
      write(a, c == b && 1 || 0) # change true/false to integer
    when 99
      #puts "EXIT"
      raise EndOfCode
    end
    @ip += 1 unless jump # next instruction
  end
end

org_program = []
# File.readlines('program.txt').each do |line|
#   org_program = line.split(',').map{|x| Integer(x)}
# end

org_program = [3,8,1001,8,10,8,105,1,0,0,21,30,55,76,97,114,195,276,357,438,99999,3,9,102,3,9,9,4,9,99,3,9,1002,9,3,9,1001,9,5,9,1002,9,2,9,1001,9,2,9,102,2,9,9,4,9,99,3,9,1002,9,5,9,1001,9,2,9,102,5,9,9,1001,9,4,9,4,9,99,3,9,1001,9,4,9,102,5,9,9,101,4,9,9,1002,9,4,9,4,9,99,3,9,101,2,9,9,102,4,9,9,1001,9,5,9,4,9,99,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,2,9,4,9,3,9,101,1,9,9,4,9,99,3,9,1002,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,101,1,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,101,2,9,9,4,9,3,9,102,2,9,9,4,9,99,3,9,101,1,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,1,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,1,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,1,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,1001,9,1,9,4,9,99,3,9,1001,9,1,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,101,2,9,9,4,9,3,9,101,1,9,9,4,9,3,9,1001,9,1,9,4,9,99,3,9,101,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,101,2,9,9,4,9,3,9,101,1,9,9,4,9,3,9,101,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,2,9,9,4,9,99]

# phase num is 0-4, used only once
#numbers = [0,1,2,3,4]
#arr = numbers.permutation(5).map do |phases|
#	input = 0
#	phases.each do |phase|
#		puts "Phase #{phase}, input: #{input}"
#		input = Opcode.new(org_program).run([phase, input])
#	end
#	input
#end
#puts arr.max

org_program = [3,26,1001,26,-4,26,3,27,1002,27,2,27,1,27,26,
27,4,27,1001,28,-1,28,1005,28,6,99,0,0,5]

phases = [9,8,7,6,5]
input = 0
loop_run = 0

	phase = phases[loop_run%5]
	puts "Phase #{phase}, input: #{input}, run: #{loop_run}"
	input = Opcode.new(org_program).run([9,0,8,7,6,5])
	puts "AAAA #{input}"
	loop_run += 1
