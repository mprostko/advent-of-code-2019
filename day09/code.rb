require 'pry'
require 'rspec'

class Opcode
  class EndOfCode < StandardError
  end

  def initialize(program)
    @pc = program.dup
    @ip = 0
    @input = nil
	@output = []
	@rb = 0 # relative base
  end

  def write(position, value)
    #puts "writing #{value} at pos #{position}"
    @pc[position] = value
  rescue
	# Out of bounds, increase memory
	@pc += Array.new(position - @pc.size + 1, 0)
	write(position, value)
  end

  def read(position)
    #puts "readin from position #{position}, value: #{@pc[position]}"
    @pc.fetch(position)
  rescue
	# Out of bounds, increase memory
	@pc += Array.new(position - @pc.size + 1, 0)
	read(position)
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
	puts "ALL: #{@output}"
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
    case(type)
	when 0
	  # type position
      # puts "param from address #{address} in position mode, value = #{read(value)}"
      read(value)
	when 1 # type immediate
      # puts "param from address #{address} in immediate mode, value = #{value}"
      value
	when 2 # type relative
	  #puts "Reading from #{value} + #{@rb} = #{read(value + @rb)}"
	  read(value + @rb)
	else
		raise 'Wrong argument type'
    end
  end
  
  def write_parameter(address, type)
	address = read(address)
	case type
	when 0, 1
		address
	when 2
		address + @rb
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
      a = write_parameter(@ip+3, ma)
      @ip += 3
      write(a, c + b)
    when 2
      #puts "MULTIPLY CMD"
      c = parameter(@ip+1, mc)
      b = parameter(@ip+2, mb)
      a = write_parameter(@ip+3, ma)
      #a = read(@ip+3)
      @ip += 3
      write(a, c * b)
    when 3
      #puts "INPUT CMD"
	  c = write_parameter(@ip+1, mc)
      input = if @input
        @input.shift
      else
        puts "Input required: "
        Integer(gets.chomp)
      end
      @ip += 1
      #puts "writing input = #{input} to addr #{c}"
	  write(c, input)
    when 4
      #puts "OUTPUT CMD"
      value = parameter(@ip+1, mc)
      @ip += 2 # 1 from paramteer, second because we're missing the ip+1 from the ed of the switch by using return
      puts "Output: #{value}"
	  @output << value
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
      a = write_parameter(@ip+3, ma)
      @ip += 3
      #puts "LT #{c} < #{b}, output to #{a}"
      write(a, c < b && 1 || 0) # change true/false to integer
    when 8
      #puts "EQ CMD"
      c = parameter(@ip+1, mc)
      b = parameter(@ip+2, mb)
      a = write_parameter(@ip+3, ma)
      @ip += 3
      #puts "EQ #{c} == #{b}, write #{c == b} to addr #{a}"
      write(a, c == b && 1 || 0) # change true/false to integer
	when 9
		c = parameter(@ip+1, mc)
		#puts "REL CHNG +#{c}, total: #{@rb}"
		@rb += c
		@ip += 1
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

org_program = [1102,34463338,34463338,63,1007,63,34463338,63,1005,63,53,1102,1,3,1000,109,988,209,12,9,1000,209,6,209,3,203,0,1008,1000,1,63,1005,63,65,1008,1000,2,63,1005,63,904,1008,1000,0,63,1005,63,58,4,25,104,0,99,4,0,104,0,99,4,17,104,0,99,0,0,1101,234,0,1027,1101,0,568,1023,1102,844,1,1025,1101,0,23,1008,1102,1,1,1021,1102,27,1,1011,1101,0,26,1004,1102,1,586,1029,1102,29,1,1014,1101,0,22,1015,1102,36,1,1016,1101,35,0,1013,1102,20,1,1003,1102,1,37,1019,1101,30,0,1006,1102,34,1,1000,1101,571,0,1022,1102,1,28,1005,1101,39,0,1009,1102,38,1,1017,1102,591,1,1028,1102,1,31,1007,1102,24,1,1010,1101,0,33,1001,1101,0,21,1018,1101,0,0,1020,1101,25,0,1002,1102,32,1,1012,1101,0,237,1026,1101,0,853,1024,109,29,1206,-9,195,4,187,1106,0,199,1001,64,1,64,1002,64,2,64,109,-26,2102,1,0,63,1008,63,23,63,1005,63,223,1001,64,1,64,1105,1,225,4,205,1002,64,2,64,109,16,2106,0,8,1106,0,243,4,231,1001,64,1,64,1002,64,2,64,109,-19,21101,40,0,10,1008,1010,40,63,1005,63,265,4,249,1106,0,269,1001,64,1,64,1002,64,2,64,109,-2,2107,31,8,63,1005,63,289,1001,64,1,64,1105,1,291,4,275,1002,64,2,64,109,2,1208,7,28,63,1005,63,307,1106,0,313,4,297,1001,64,1,64,1002,64,2,64,109,-1,1207,9,24,63,1005,63,335,4,319,1001,64,1,64,1105,1,335,1002,64,2,64,109,5,1201,0,0,63,1008,63,25,63,1005,63,355,1105,1,361,4,341,1001,64,1,64,1002,64,2,64,109,-13,1202,9,1,63,1008,63,34,63,1005,63,383,4,367,1105,1,387,1001,64,1,64,1002,64,2,64,109,32,1205,-3,403,1001,64,1,64,1106,0,405,4,393,1002,64,2,64,109,-14,2108,31,-2,63,1005,63,423,4,411,1105,1,427,1001,64,1,64,1002,64,2,64,109,11,1206,1,439,1105,1,445,4,433,1001,64,1,64,1002,64,2,64,109,-21,1208,4,20,63,1005,63,467,4,451,1001,64,1,64,1105,1,467,1002,64,2,64,109,6,1207,-5,33,63,1005,63,487,1001,64,1,64,1106,0,489,4,473,1002,64,2,64,109,-12,1202,8,1,63,1008,63,34,63,1005,63,509,1106,0,515,4,495,1001,64,1,64,1002,64,2,64,109,28,1205,0,529,4,521,1106,0,533,1001,64,1,64,1002,64,2,64,109,3,21101,41,0,-9,1008,1015,38,63,1005,63,557,1001,64,1,64,1106,0,559,4,539,1002,64,2,64,109,-11,2105,1,10,1105,1,577,4,565,1001,64,1,64,1002,64,2,64,109,23,2106,0,-8,4,583,1105,1,595,1001,64,1,64,1002,64,2,64,109,-15,21108,42,42,-6,1005,1015,613,4,601,1106,0,617,1001,64,1,64,1002,64,2,64,109,-14,21107,43,44,8,1005,1015,639,4,623,1001,64,1,64,1106,0,639,1002,64,2,64,109,11,2107,38,-9,63,1005,63,661,4,645,1001,64,1,64,1106,0,661,1002,64,2,64,109,-2,21107,44,43,3,1005,1019,677,1105,1,683,4,667,1001,64,1,64,1002,64,2,64,109,-7,21108,45,42,1,1005,1010,703,1001,64,1,64,1106,0,705,4,689,1002,64,2,64,109,-5,2102,1,1,63,1008,63,28,63,1005,63,727,4,711,1106,0,731,1001,64,1,64,1002,64,2,64,109,13,21102,46,1,0,1008,1017,46,63,1005,63,753,4,737,1106,0,757,1001,64,1,64,1002,64,2,64,109,-4,2101,0,-5,63,1008,63,20,63,1005,63,781,1001,64,1,64,1105,1,783,4,763,1002,64,2,64,109,1,21102,47,1,0,1008,1014,48,63,1005,63,803,1105,1,809,4,789,1001,64,1,64,1002,64,2,64,109,-3,2101,0,-4,63,1008,63,31,63,1005,63,835,4,815,1001,64,1,64,1105,1,835,1002,64,2,64,109,6,2105,1,7,4,841,1001,64,1,64,1105,1,853,1002,64,2,64,109,-21,2108,33,10,63,1005,63,873,1001,64,1,64,1105,1,875,4,859,1002,64,2,64,109,6,1201,4,0,63,1008,63,30,63,1005,63,901,4,881,1001,64,1,64,1105,1,901,4,64,99,21102,27,1,1,21102,1,915,0,1106,0,922,21201,1,64720,1,204,1,99,109,3,1207,-2,3,63,1005,63,964,21201,-2,-1,1,21102,1,942,0,1105,1,922,21202,1,1,-1,21201,-2,-3,1,21101,957,0,0,1105,1,922,22201,1,-1,-2,1105,1,968,21202,-2,1,-2,109,-3,2106,0,0]

Opcode.new(org_program).run
