
#make the console print while the code is executing instead of waiting until all code is executed to print
STDOUT.sync = true

class Trie < Hash
  def initialize
  	#this initializes in the same manner as a Hash object by invoking the term 'super'
    super
  end

  def build(array)
  	#for each word in the array
    for word in array
    	#self is the initial value, h is the modified value that the inject function is "adding to"
    	word.chars.inject(self) do |h, char|
    	 # print "dict: ", self
    	 # puts
    	 # print "h: ", h
    	 # puts
    	 # print "char: ", char
    	 # puts
    	 # puts
     	 h[char] ||= { }
   		end
    end
  end
end


class Board
	attr_accessor :board_array, :word_count, :dictionary, :word_checker, :word_list 

	def initialize(vertical_squares, horizontal_squares)
		print "Building Boggle Board..."
		puts
    @board_array = Array.new(horizontal_squares){Array.new(vertical_squares){"_"}}
    @word_count = 0
    @word_list = []  #keeps a running count of the words in the board
    @dictionary = make_dictionary  #creates a hash from letterpress dictionary text file.  this allows for O(1) lookup of full words.
    @word_checker = build_word_checker  #create a trie from dictionary file -- allows for O(N) look up of potential words.
    fill_board(@board_array)  #populate the inital board
    
  end

  def fill_board(board)
  	#three dots means up to but not including
  	# letters = [["P", "A", "G", "H"], ["A", "T", "S", "D"], ["M", "G", "U", "O"], ["Z", "B", "E", "T"]]
  	for h in 0...board.length
  		for v in 0...board[0].length
  			# letter = letters[h][v]
  			board[h][v] = Square.new([h,v], random_letter, board.length)
  		end
  	end 
  end

  def random_letter
  	charset = Array('A'..'Z')
  	letter = charset.sample(1)
  	letter = letter[0]
  end 

  def display_board
  	puts
  	for h in 0...@board_array.length
  			for v in 0...@board_array[0].length
  				print "[",@board_array[h][v].value,"]"
  			end
  			puts
  	end
  	puts
  end

  def make_dictionary
		words = {}
		File.open("letterpress_en_dictionary.txt") do |file|
		  file.each do |line|
		    words[line.strip] = true
		  end
		end
		words
  end

  def build_word_checker
  	words = []
		File.open("letterpress_en_dictionary.txt") do |file|
		  file.each do |line|
		    words<<line.strip
		  end
		end
		trie = Trie.new
		trie.build(words)
		return trie
  end
end


class Square
	attr_accessor :position, :value, :square_id
	def initialize(position, letter, size_of_grid)
    @position = position
    @value = letter
    #create an id for each square on the board to help define a path
    @square_id = create_square_id(position, size_of_grid)
  end

  def create_square_id(position, size_of_grid)
  	#create unique id 
  	id = position[0]*size_of_grid+position[1]
  	return id
  end
end


def find_all_boggle_paths(board)
	print "Finding all boggle paths..."
	#for each letter on the board
	for h in 0...board.board_array.length
		for v in 0...board.board_array[0].length	
			#passes the board as well as the starting square
			find_all_words_for_square(board, [board.board_array[v][h]])
		end
	end
end

def find_all_words_for_square(board, path)
	moves = ["R", "RD", "D", "LD", "L", "LU", "U", "RU"]
	for move in moves
		if is_valid_move?(board, path, move) then
			updated_path = make_move(board, path, move, true)
			# puts "valid move"
			# print found words
			# if updated_path.length >= 4 then
			# 	for i in 0...updated_path.length
			# 		print updated_path[i].value
			# 	end
			# 	puts
			# 	board.word_count+=1
			# end
			find_all_words_for_square(board, updated_path)
		else
			# puts "INVALID move"
		end
	end
end

def is_valid_move?(board, current_path, move)
	#check if contemplated move is a) within the bounds of the board and b) on a new square

	potential_move = make_move(board, current_path, move, false)

	if potential_move[-1] == nil then return false end

	return true
end

def make_move(board, current_path, move, for_real)

	# print "beginnin pos:", current_path[-1].position.dup
	# puts
	# print "move: ", move
	# puts

	cur_position = current_path[-1].position.dup
	case move
		when "R"
			cur_position[1]+=1
		when "RD"
			cur_position[1]+=1	
			cur_position[0]+=1					
		when "D"
			cur_position[0]+=1			
		when "LD"
			cur_position[1]-=1			
			cur_position[0]+=1				
		when "L"
			cur_position[1]-=1
		when "LU"
			cur_position[1]-=1		
			cur_position[0]-=1						
		when "U"
			cur_position[0]-=1			
		when "RU"			
			cur_position[1]+=1			
			cur_position[0]-=1
		else
			puts move
			puts "that's an error jim"			
	end

	column = cur_position[1]
	row = cur_position[0]
	updated_path = current_path.dup

	if column >= board.board_array[0].length || column < 0 then
		updated_path<<nil
	elsif row >= board.board_array.length || row < 0 then
		updated_path<<nil
	elsif repeat_square?(board.board_array[cur_position[0]][cur_position[1]], current_path)
		updated_path<<nil
	else
		updated_path<<board.board_array[cur_position[0]][cur_position[1]]
		word = ""
		for i in 0...updated_path.length
			word+=updated_path[i].value
		end
		# if for_real then puts word end
		if !potential_word?(board.word_checker, word) then updated_path<<nil end
		if is_a_word?(board.dictionary, word) && for_real then 
			board.word_list<<word 
			print "."
		end
	end
	return updated_path
end

def repeat_square?(new_square, current_path)
	id = new_square.square_id
	for i in 0...current_path.length
		if id == current_path[i].square_id then return true end
	end
	return false
end

def potential_word?(word_trie, current_word)
	current_path = word_trie
	current_word.each_char do |letter|
		if current_path[letter] then return false end
		current_path = current_path[letter.downcase]
	end
	return current_path
end

def is_a_word?(dictionary, current_word)
	dictionary[current_word.downcase]
end

boggle_board = Board.new(10,10)

find_all_boggle_paths(boggle_board)

puts
boggle_board.word_list.uniq.length
puts boggle_board.word_list.uniq.sort
boggle_board.display_board


# list = ['ant', 'and', 'abs']

# trie = Trie.new

# trie.build(list)









