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
    @input = input
    while(1) do
      puts "PC b4: #{@pc}. @IP=#{@ip}"
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
      puts "param from address #{address} in immediate mode, value = #{value}"
      value
    else # type position
      puts "param from address #{address} in position mode, value = #{read(value)}"
      read(value)
    end
  end

  def next_step
    jump = false
    mc,mb,ma,instruction = decode_opcode
    puts "CBA = #{mc}, #{mb}, #{ma}"

    case(instruction)
    when 1
      puts "ADD CMD"
      c = parameter(@ip+1, mc)
      b = parameter(@ip+2, mb)
      a = parameter(@ip+3, 1) # always immidiate
      @ip += 3
      write(a, c + b)
    when 2
      puts "MULTIPLY CMD"
      c = parameter(@ip+1, mc)
      b = parameter(@ip+2, mb)
      a = parameter(@ip+3, 1) # always immidiate
      a = read(@ip+3)
      @ip += 3
      write(a, c * b)
    when 3
      puts "INPUT CMD"
      c = parameter(@ip+1, 1) # always immidiate
      input = if @input
        @input
      else
        puts "Input required: "
        Integer(gets.chomp)
      end
      @ip += 1
      puts "writing input = #{input} to addr #{c}"
      write(c, input)
    when 4
      puts "OUTPUT CMD"
      value = parameter(@ip+1, mc)
      @ip += 2 # 1 from paramteer, second because we're missing the ip+1 from the ed of the switch by using return
      puts "Output: #{value}"
      return value
    when 5
      puts "JIT CMD" # jump if true
      c = parameter(@ip+1, mc)
      b = parameter(@ip+2, mb)
      puts "JIT, c=#{c}, jumpto=#{b}"
      if c > 0
        puts "jumping to #{c}"
        jump = true
        @ip = b
      else
        @ip += 2
      end
    when 6
      puts "JIF CMD" # jump if false
      c = parameter(@ip+1, mc)
      b = parameter(@ip+2, mb)
      puts "JIT, c=#{c}, jumpto=#{b}"
      if c == 0
        puts "jumping to #{c}"
        jump = true
        @ip = b
      else
        @ip += 2
      end
    when 7
      puts "LT CMD"
      c = parameter(@ip+1, mc)
      b = parameter(@ip+2, mb)
      a = parameter(@ip+3, 1) # always immidiate
      @ip += 3
      puts "LT #{c} < #{b}, output to #{a}"
      write(a, c < b && 1 || 0) # change true/false to integer
    when 8
      puts "EQ CMD"
      c = parameter(@ip+1, mc)
      b = parameter(@ip+2, mb)
      a = parameter(@ip+3, 1) # always immidiate
      @ip += 3
      puts "EQ #{c} == #{b}, write #{c == b} to addr #{a}"
      write(a, c == b && 1 || 0) # change true/false to integer
    when 99
      puts "EXIT"
      raise EndOfCode
    end
    @ip += 1 unless jump # next instruction
  end
end

org_program = []
# File.readlines('program.txt').each do |line|
#   org_program = line.split(',').map{|x| Integer(x)}
# end

org_program = [3,225,1,225,6,6,1100,1,238,225,104,0,1102,16,13,225,1001,88,68,224,101,-114,224,224,4,224,1002,223,8,223,1001,224,2,224,1,223,224,223,1101,8,76,224,101,-84,224,224,4,224,102,8,223,223,101,1,224,224,1,224,223,223,1101,63,58,225,1102,14,56,224,101,-784,224,224,4,224,102,8,223,223,101,4,224,224,1,223,224,223,1101,29,46,225,102,60,187,224,101,-2340,224,224,4,224,102,8,223,223,101,3,224,224,1,224,223,223,1102,60,53,225,1101,50,52,225,2,14,218,224,101,-975,224,224,4,224,102,8,223,223,1001,224,3,224,1,223,224,223,1002,213,79,224,101,-2291,224,224,4,224,102,8,223,223,1001,224,2,224,1,223,224,223,1,114,117,224,101,-103,224,224,4,224,1002,223,8,223,101,4,224,224,1,224,223,223,1101,39,47,225,101,71,61,224,101,-134,224,224,4,224,102,8,223,223,101,2,224,224,1,224,223,223,1102,29,13,225,1102,88,75,225,4,223,99,0,0,0,677,0,0,0,0,0,0,0,0,0,0,0,1105,0,99999,1105,227,247,1105,1,99999,1005,227,99999,1005,0,256,1105,1,99999,1106,227,99999,1106,0,265,1105,1,99999,1006,0,99999,1006,227,274,1105,1,99999,1105,1,280,1105,1,99999,1,225,225,225,1101,294,0,0,105,1,0,1105,1,99999,1106,0,300,1105,1,99999,1,225,225,225,1101,314,0,0,106,0,0,1105,1,99999,1107,677,677,224,102,2,223,223,1006,224,329,1001,223,1,223,108,677,677,224,1002,223,2,223,1005,224,344,101,1,223,223,1008,226,226,224,102,2,223,223,1006,224,359,1001,223,1,223,1107,226,677,224,102,2,223,223,1006,224,374,1001,223,1,223,8,677,226,224,102,2,223,223,1006,224,389,101,1,223,223,8,226,226,224,102,2,223,223,1006,224,404,101,1,223,223,7,677,677,224,1002,223,2,223,1006,224,419,101,1,223,223,7,677,226,224,1002,223,2,223,1005,224,434,101,1,223,223,1108,677,226,224,1002,223,2,223,1006,224,449,1001,223,1,223,108,677,226,224,1002,223,2,223,1006,224,464,101,1,223,223,1108,226,677,224,1002,223,2,223,1006,224,479,101,1,223,223,1007,677,677,224,1002,223,2,223,1006,224,494,1001,223,1,223,107,226,226,224,102,2,223,223,1005,224,509,1001,223,1,223,1008,677,226,224,102,2,223,223,1005,224,524,1001,223,1,223,1007,226,226,224,102,2,223,223,1006,224,539,101,1,223,223,1108,677,677,224,102,2,223,223,1005,224,554,1001,223,1,223,1008,677,677,224,1002,223,2,223,1006,224,569,101,1,223,223,1107,677,226,224,1002,223,2,223,1006,224,584,1001,223,1,223,7,226,677,224,102,2,223,223,1005,224,599,101,1,223,223,108,226,226,224,1002,223,2,223,1005,224,614,101,1,223,223,107,226,677,224,1002,223,2,223,1005,224,629,1001,223,1,223,107,677,677,224,1002,223,2,223,1006,224,644,101,1,223,223,1007,677,226,224,1002,223,2,223,1006,224,659,101,1,223,223,8,226,677,224,102,2,223,223,1005,224,674,1001,223,1,223,4,223,99,226]

x = Opcode.new(org_program).run
puts x

require "rspec/autorun"
RSpec.describe "opcodes" do
  xit 'reads position mode parameter' do
    program = [0,4,0,0,9]
    x = Opcode.new(program).parameter(1,0)
    expect(x).to eq(9)
  end
  xit 'reads immediate mode parameter' do
    program = [0,4,0,0,9]
    x = Opcode.new(program).parameter(1,1)
    expect(x).to eq(4)
  end
  xit "position mode eql to 8" do
    program = [3,9,8,9,10,9,4,9,99,-1,8]
    expect(Opcode.new(program).run(8)).to eq(1)
    expect(Opcode.new(program).run(7)).to eq(0)
    expect(Opcode.new(program).run(9)).to eq(0)
  end
  xit "immediate mode eql to 8" do
    program = [3,3,1108,-1,8,3,4,3,99]
    expect(Opcode.new(program).run(8)).to eq(1)
    expect(Opcode.new(program).run(7)).to eq(0)
    expect(Opcode.new(program).run(9)).to eq(0)
  end
  xit "position mode less than 8" do
    program = [3,9,7,9,10,9,4,9,99,-1,8]
    expect(Opcode.new(program).run(8)).to eq(0)
    expect(Opcode.new(program).run(7)).to eq(1)
    expect(Opcode.new(program).run(9)).to eq(0)
  end
  xit "immediate mode less than 8" do
    program = [3,3,1107,-1,8,3,4,3,99]
    expect(Opcode.new(program).run(8)).to eq(0)
    expect(Opcode.new(program).run(7)).to eq(1)
    expect(Opcode.new(program).run(9)).to eq(0)
  end
  xit "jump position mode" do
    program = [3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9]
    expect(Opcode.new(program).run(0)).to eq(0)
    expect(Opcode.new(program).run(1)).to eq(1)
    expect(Opcode.new(program).run(5)).to eq(1)
  end
  xit "jump immediate mode" do
    program = [3,3,1105,-1,9,1101,0,0,12,4,12,99,1]
    expect(Opcode.new(program).run(0)).to eq(0)
    expect(Opcode.new(program).run(1)).to eq(1)
    expect(Opcode.new(program).run(5)).to eq(1)
  end
  xit "bigger example" do
    program = [3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,
1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,
999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99]
    expect(Opcode.new(program).run(3)).to eq(999)
    expect(Opcode.new(program).run(8)).to eq(1000)
    expect(Opcode.new(program).run(50)).to eq(1001)
  end
end