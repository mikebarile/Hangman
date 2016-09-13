class Hangman
  attr_reader :guesser, :referee, :board, :guessed_letters, :num_guesses

  def initialize(players = {})
  	@referee = players[:referee]
  	@guesser = players[:guesser]
  	@guessed_letters = []
  	@num_guesses = 0
  end

  def setup
  	create_players if @referee == nil && guesser == nil
  	length = @referee.pick_secret_word
  	@guesser.register_secret_length(length)
  	@board = Array.new(length, nil)
  end

  def take_turn
  	board = @board.map{ |elem| if elem == nil then "_" else elem end}
  	p "Guessed letters: #{guessed_letters.sort.join(", ")}" unless @num_guesses == 0
  	p "Number of guesses: #{num_guesses}" unless @num_guesses == 0
  	p "Board: #{board.join(" ")}"
  	guess = @guesser.guess(@board)
  	@guessed_letters << guess
  	@num_guesses += 1
  	if @board.count{ |letter| letter == nil} == 1
  		killblow = @board.find_index(nil)
  		indices = @referee.check_guess(guess, killblow)
  	else
  		indices = @referee.check_guess(guess)
  	end
  	update_board(guess, indices)
  	@guesser.handle_response(guess, indices)
  end

  def update_board(guess, indices)
  	indices.each do |index|
  		@board[index] = guess
  	end
  end

  def run_game
  	setup
  	while @board.include?(nil)
  		take_turn
  	end
  	p "Board: #{board.join(" ")} !!!!!!"
  	p guesser.win!(@num_guesses)
  end

  def create_players
  	dictionary = File.readlines('lib/dictionary.txt').map{ |line| line.chomp}
  	computer = ComputerPlayer.new(dictionary)

  	p "Player, enter your name."
	name = gets.chomp.capitalize
	human = HumanPlayer.new(name)

	response = nil
	while response != "ref" && response != "guesser"
		p "#{name}! Would you like to be the ref or the guesser? Enter either 'ref' or 'guesser'"
		response = gets.chomp.downcase
	end

	if response == "ref"
		@referee = human
		@guesser = computer
	else
		@referee = computer
		@guesser = human
	end
  end

end

class HumanPlayer

	attr_reader :name, :secret_length, :guessed_letters

	def initialize(name = "")
		@name = name
		@guessed_letters = []
	end

	def guess(board)\
		p "Enter your guess."
		guess = gets.chomp

		while @guessed_letters.include?(guess)
			p "You've already guessed that letter! Enter a new guess."
			guess = gets.chomp
		end

		@guessed_letters << guess
		guess
	end

	def check_guess(guess, killblow = false)
		response = nil
		while response != "yes" && response != "no"
			p "#{@name}! The computer guessed #{guess}. Does this letter appear in your word? (Enter 'yes' or 'no')"
			response = gets.chomp.downcase
		end

		if response == "yes" && killblow != false
			return [killblow]
		end

		if response == "yes"
			p "At what indices does the letter appear? (Enter in the format 'index1, index2, etc.')"
			indices = gets.chomp
			indices = indices.split(",")

			indices.map!{ |index| index.to_i - 1}
			while indices.max >= @secret_length || indices.min < 0
				p "Invalid response! Please reenter the indices."
				indices = gets.chomp
				indices = indices.split(", ")
				indices.map!{ |index| index.to_i - 1}
			end
		else
			indices = []
		end
		indices
	end

	def handle_response(guess, indices)
		p "#{name}! Your guess '#{guess}' appears at the following indices: #{indices}"
	end

	def pick_secret_word
		p "#{name}! Pick a secret word and enter its length."
		response = gets.chomp.to_i
		until response.is_a?(Integer)
			p "Invalid entry! Try again."
			response = gets.chomp
		end
		@secret_length = response.to_i
	end

	def register_secret_length(length)
		p "#{name}! The secret word is #{length} characters long."
	end

	def win!(turns)
		p "#{name}, you've won the game in #{turns} turns!"
	end

end

class ComputerPlayer

	LETTERS = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n",
				"o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]

	attr_reader :dictionary, :secret_word, :secret_length, :board, :guessed_letters

	def initialize(dictionary)
		@dictionary = dictionary
		@guessed_letters = []
	end

	def pick_secret_word
		@secret_word = @dictionary.shuffle[0]
		@secret_word.length
	end

	def register_secret_length(length)
		@secret_length = length
		@board = Array.new(length, nil)
		@dictionary = @dictionary.select { |word| word.length == @secret_length }
	end

	def check_guess(letter, killblow = false)
		indices = []
		@secret_word.split("").each_with_index do |char, index|
			indices << index if char == letter
		end
		indices
	end

	def guess(board)
		letters = Hash.new(0)
		
		unless @dictionary.length == 0
			@dictionary.each do |word|
				word.split("").each do |letter|
					letters[letter] += 1
				end
			end

			letters = letters.select{ |letter, times_appears| !board.include?(letter)}
			guess = letters.max_by{ |letter, times_appears| times_appears }[0]			
		else
			letters = LETTERS.select do |letter, times_appears| 
				!board.include?(letter) && !@guessed_letters.include?(letter)
			end
			guess = letters.shuffle[0]
		end

		@guessed_letters << guess
		guess
	end

	def candidate_words(guess = nil, indices = nil)
		unless guess == nil
			@dictionary = @dictionary.select do |word|
				matches = true
				word.split("").each_with_index do |letter, index|
					matches = false if indices.include?(index) && letter != guess
					matches = false if !indices.include?(index) && letter == guess 
				end
				matches = false if word.length != @secret_length
				matches
			end 
		end 		

		@dictionary
	end

	#need to delete words from the dictionary in handle response method
	def handle_response(guess, indices)
		indices.each do |index|
  			@board[index] = guess
  		end
  		candidate_words(guess, indices)
	end

	def win!(turns)
		p "The computer has won the game in #{turns} turns!"
	end

end
