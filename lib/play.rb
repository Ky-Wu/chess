require "./board.rb"
require "./chess.rb"
require "./pieces.rb"

def game_menu
  puts "Welcome to Chess. Please enter a number to make your choice:"
  puts "1. Load your save file."
  puts "2. Start a new game."
  puts "3. Credits"
  puts "4. Exit"
  while input = gets.chomp
    case input
    when '1'
      game = Chess.new()
      game.load
      game.play
      break
    when '2'
      game = Chess.new()
      game.play
      break
    when '3'
      puts "A terminal chess game created by Kyle L. Wu."
    when '4'
      exit
    end
  end
end

game_menu

# Terminal chess game by Kyle L. Wu
