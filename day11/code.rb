require 'pry'

class Opcode
  class EndOfCode < StandardError
  end

  def initialize(program)
    @pc = program.dup
    @ip = 0
    @input = nil
	@output = nil
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

  def run(input=nil, output=nil)
    return_value = nil
    @input ||= input
	@output ||= output
	while(1) do
      # puts "PC b4: #{@pc}. @IP=#{@ip}"
      ret = next_step
      return_value = ret if ret
    end
  #rescue EndOfCode
	#puts "ALL: #{@output}"
    #return_value
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
        while(@input.empty?) do
			sleep(0.01)
		end
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
      #puts "Output: #{value}"
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

class Painter
	def initialize
		program = [3,8,1005,8,318,1106,0,11,0,0,0,104,1,104,0,3,8,1002,8,-1,10,101,1,10,10,4,10,1008,8,0,10,4,10,102,1,8,29,1006,0,99,1006,0,81,1006,0,29,3,8,102,-1,8,10,1001,10,1,10,4,10,108,1,8,10,4,10,1001,8,0,59,3,8,102,-1,8,10,101,1,10,10,4,10,1008,8,1,10,4,10,102,1,8,82,1,1103,3,10,2,104,14,10,3,8,102,-1,8,10,101,1,10,10,4,10,108,1,8,10,4,10,102,1,8,111,1,108,2,10,2,1101,7,10,1,1,8,10,1,1009,5,10,3,8,1002,8,-1,10,101,1,10,10,4,10,108,0,8,10,4,10,102,1,8,149,3,8,1002,8,-1,10,101,1,10,10,4,10,1008,8,1,10,4,10,101,0,8,172,3,8,1002,8,-1,10,1001,10,1,10,4,10,108,0,8,10,4,10,1001,8,0,193,1006,0,39,2,103,4,10,2,1103,20,10,3,8,1002,8,-1,10,1001,10,1,10,4,10,1008,8,0,10,4,10,102,1,8,227,1,1106,8,10,2,109,15,10,2,106,14,10,3,8,102,-1,8,10,101,1,10,10,4,10,1008,8,1,10,4,10,101,0,8,261,3,8,102,-1,8,10,1001,10,1,10,4,10,1008,8,0,10,4,10,102,1,8,283,1,1109,9,10,2,1109,5,10,2,1,2,10,1006,0,79,101,1,9,9,1007,9,1087,10,1005,10,15,99,109,640,104,0,104,1,21101,936333124392,0,1,21101,0,335,0,1106,0,439,21102,1,824663880596,1,21102,346,1,0,1105,1,439,3,10,104,0,104,1,3,10,104,0,104,0,3,10,104,0,104,1,3,10,104,0,104,1,3,10,104,0,104,0,3,10,104,0,104,1,21102,1,179519553539,1,21101,393,0,0,1106,0,439,21102,46266515623,1,1,21101,0,404,0,1106,0,439,3,10,104,0,104,0,3,10,104,0,104,0,21101,0,983925826324,1,21101,0,427,0,1106,0,439,21101,988220642048,0,1,21102,1,438,0,1105,1,439,99,109,2,21201,-1,0,1,21102,1,40,2,21101,0,470,3,21101,460,0,0,1106,0,503,109,-2,2105,1,0,0,1,0,0,1,109,2,3,10,204,-1,1001,465,466,481,4,0,1001,465,1,465,108,4,465,10,1006,10,497,1101,0,0,465,109,-2,2106,0,0,0,109,4,2102,1,-1,502,1207,-3,0,10,1006,10,520,21101,0,0,-3,22102,1,-3,1,21202,-2,1,2,21102,1,1,3,21102,1,539,0,1105,1,544,109,-4,2106,0,0,109,5,1207,-3,1,10,1006,10,567,2207,-4,-2,10,1006,10,567,21202,-4,1,-4,1106,0,635,21202,-4,1,1,21201,-3,-1,2,21202,-2,2,3,21102,1,586,0,1105,1,544,21202,1,1,-4,21102,1,1,-1,2207,-4,-2,10,1006,10,605,21101,0,0,-1,22202,-2,-1,-2,2107,0,-3,10,1006,10,627,21202,-1,1,1,21102,1,627,0,105,1,502,21202,-2,-1,-2,22201,-4,-2,-4,109,-5,2106,0,0]
		@comp = Opcode.new(program)
		@x = 0
		@y = 0
		@rotation = :up
		@map = {}
	end
	
	attr_accessor :x, :y, :comp, :map
	
	def run
		input = [1]
		output = []
		Thread.abort_on_exception = true
		t = Thread.new { comp.run(input, output) }
		while 1 do
			while(output.empty?) do
				sleep(0.01)	
			end
			#puts output.inspect
			color = output.shift
			turn_direction = output.shift
			#puts "I'm at #{x},#{y} facing #{@rotation.to_s}. \tI painted it #{color == 0 ? 'black' : 'white'} and I'm rotating #{turn_direction == 0 ? 'left' : 'right'}"
			paint(color)
			turn(turn_direction)
			#show
			step_forward
			#puts "I moved to #{x},#{y}"
			next_input = if map.has_key?("#{x},#{y}")
							map["#{x},#{y}"]
						else
							0 # 0 - black, 1 - white
						end
			
			input << next_input
		end
	rescue
		puts map.keys.count
		show
	end
	
	def paint(color)
		#puts "painting to #{color}"
		map["#{x},#{y}"] = color
	end
	
	def turn(rotation) # 0 - 90 deg left, 1 - 90 deg right
		@rotation = case @rotation
		when :up
			rotation == 0 ? :left : :right
		when :down
			rotation == 0 ? :right : :left 
		when :left
			rotation == 0 ? :down : :up
		when :right
			rotation == 0 ? :up : :down
		end
	end
	
	def step_forward
		case @rotation
		when :up
			@y += 1
		when :down
			@y -= 1
		when :left
			@x -= 1
		when :right
			@x += 1
		end 
	end
	
	def show
		size = 150
		m = Array.new(size) { Array.new(size) {'.'} }
		x_offset = size/2
		y_offset = size/2
		map.each do |key, color|
			px, py = key.split(',').map{|g| Integer(g)}
			m[py+y_offset][px+x_offset] = color == 0 ? '#' : '.'
		end
		m[@y+y_offset][@x+x_offset] = case @rotation
		when :up
			'^'
		when :down
			'v'
		when :left
			'<'
		when :right
			'>'
		end 
		
		m.reverse.each do |row|
			puts row.join('')
		end
	end
end

x = Painter.new
x.run