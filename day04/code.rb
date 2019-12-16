 # input is 124075-580769
 # 124075
 # 124444
 # 124445
 # 124455
 # 124456
 # 124457
 # 124458
 # 124459
 # 124466
 # 124467
 # 124555
 # 124556
 
numbers = [124075, 124444, 124445, 124455, 124456, 124457, 124458, 124459, 124466, 124467, 124467, 124468, 124469, 124555, 124556, 124557, 124558, 124559]

class Password
	def initialize(number)
		@number = number
	end
	def valid?
		number = @number.dup
		adjacent_digit_double = []
		adjacent_digit_groups = []
		last_digit = number % 10
		number = number / 10
		while(number > 0) do
			prev_digit = number % 10
			return false if prev_digit > last_digit # AB, A>B.
			if prev_digit == last_digit
				if adjacent_digit_double.include?(prev_digit)
					adjacent_digit_double.delete(prev_digit)
					adjacent_digit_groups << prev_digit
				else
					unless adjacent_digit_groups.include?(prev_digit)
						adjacent_digit_double << prev_digit
					end
				end
			end
			last_digit = prev_digit
			number = number / 10
		end
		return adjacent_digit_double.any?
	end
end

valid_numbers = 0
(124075..580769).each do |number|
	valid = Password.new(number).valid?
	#puts "#{number} is #{valid}"
	valid_numbers += 1 if valid
end

puts valid_numbers