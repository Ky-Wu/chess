require 'json'
module BasicSerializable
  @@serializer = JSON
  def serialize
    obj = {}
    instance_variables.map do |var|
      obj[var] = instance_variable_get(var)
    end
    @@serializer.dump obj
  end
  def unserialize(string)
    obj = @@serializer.parse(string)
    obj.keys.each do |key|
      instance_variable_set(key, obj[key])
    end
  end
end

class Chess
  include BasicSerializable

  def unserialize(string)
    obj = @@serializer.parse(string)
    obj.each do |var, var_string|
      if var == "@board"
        @board = Board.new()
        @board.unserialize(var_string)
        @board.load
      else
      instance_variable_set(var, var_string)
      end
    end
  end

  def serialize
    obj = {}
    instance_variables.map do |var|
      if instance_variable_get(var).is_a?(Board)
        obj[var] = instance_variable_get(var).serialize
      elsif instance_variable_get(var).is_a?(Array)
        obj[var] = instance_variable_get(var).map {|n| n.serialize }
      else
        obj[var] = instance_variable_get(var)
      end
    end
    @@serializer.dump obj
  end


  def initialize
    @board = Board.new()
    @board.setup
    @captured_white_pieces = []
    @captured_black_pieces = []
    @playing = true
    @draw = false
  end

  def play
    while @playing
      @board.display
      get_move
      @board.switch_colors
    end
    game_over(@board.current_color)
  end

  def options(moving_piece = nil)
    unless moving_piece.nil?
      info = [moving_piece.coordinates, moving_piece.possible_moves]
    else
      info = []
    end
    ["-Enter coordinates of the square where you want to move to.",
    "---Square being moved: #{info[0]}",
    "---Valid moves: #{info[1]}",
    "-Enter \"back\" to go back to selecting a square to move.",
    "-Enter \"concede\" to surrender the win to your opponent.",
    "-Enter \"save\" to save your game to the local save file.",
    "-Enter \"draw\" to declare a draw.",
    "---Make sure both players agree on a draw before declaring one.",
    "-Enter \"exit\" to quit this game (without saving)."]
  end

  def select_square
    puts "Current color: #{current_player_s}"
    puts "\nOptions:\n"
    puts "-Input coordinates to select a piece with your color."
    puts "Format: Horizontal #, Vertical #."
    puts options[4..8]
    while input = gets.chomp
      coordinates = input.scan(/[0-7]/)
      if coordinates.length == 2
        coordinates.map! {|num| num.to_i}
        if @board.square(coordinates).is_a?(Piece) &&
           @board.square(coordinates).color == @board.current_color
           return coordinates
           break
        end
      else
        case input
        when 'concede'
          @playing = false
          @board.switch_colors
          return nil
        when 'save'
          save
          puts "Saved! Continue on."
        when "draw"
          puts "#{current_player_s} has declared a draw."
          @playing = false
          @draw = true
          return nil
        when "exit"
          exit
        else
          puts "Please use the format: H#, V#,"\
              "to select a piece with the current color or type another option."
        end
      end
    end
  end

  def get_move
    moving_piece_coords = select_square
    return if moving_piece_coords.nil?
    moving_piece = @board.square(moving_piece_coords)
    puts "\nOptions:"
    options(moving_piece).each {|line| puts line}
    while input = gets.chomp.downcase
      puts "\n____________________________________________________\n\n"
      coords = input.scan(/[0-7]/)
      # If the input contains two integers for coordinates
      if coords.length == 2
        coords.map! {|num| num.to_i }
        if moving_piece.possible_moves.include?(coords)
          make_move(moving_piece_coords, coords)
          break
        end
      else
        case input
        when 'back'
          @board.display
          # Go back to the beginning of this method
          get_move
          break
        when 'concede'
          @playing = false
          @board.switch_colors
          break
        when 'save'
          save
          puts "Saved! Continue on."
        when "draw"
          puts "#{current_player_s} has declared a draw."
          @playing = false
          @draw = true
          break
        else
          puts "Not valid input. Please make a valid move or enter \"back\"."
        end
      end

    end
  end

  def save
    File.open("../save/save_file.json", "w") { |file| file.puts serialize }
  end

  def load
    save_file = File.open("../save/save_file.json").readline
    unserialize(save_file)
  end


  def make_move(start_coords, end_coords)
    moving_piece = @board.square(start_coords)
    end_square = @board.square(end_coords)
    capture(end_square) if end_square.is_a?(Piece)
    if moving_piece.is_a?(Pawn)
      #Capture the passed piece if the pawn is performing an en passant
      check_en_passant_move(moving_piece, end_coords)
      #Then move the Pawn to the square
      move_to(moving_piece, end_coords)
      #Check to see if the pawn is enabling en passants
      enabled_pieces = enable_possible_enpassants(moving_piece)
      #The pawn has made a move; it's lost its initial double move
      moving_piece.restrict_moves if moving_piece.not_moved?
      #Restrict pawn moves to eliminate en passants after 1 turn
      restricted_pawns = restrict_pawn_moves(enabled_pieces)
      promote(moving_piece) if moving_piece.eighth_rank?
    elsif moving_piece.is_a?(King)
      move_to(moving_piece, end_coords)
      unless piece_unattackable?(moving_piece)
        puts "#{current_player_s} put their own King into check!"
      end
    else
      move_to(moving_piece, end_coords)
    end
    if end_square.is_a?(King)
      @playing = false
      @board.display
    else
      print_king_status(moving_piece)
    end
  end

  def promote(pawn)
    pawn_coords = pawn.coordinates
    queen = Queen.new(pawn.color, pawn_coords)
    @board.replace_square(pawn_coords, queen)
    queen.link_board(@board)
  end

  def restrict_pawn_moves(exceptions)
    @board.grid.each do |square|
      if square.is_a?(Pawn) && !exceptions.include?(square) &&
      !square.not_moved?
        square.restrict_moves
      end
    end
  end

  def move_to(piece, end_coords)
    start_coords = piece.coordinates
    piece.coordinates = end_coords
    @board.replace_square(end_coords, piece)
    @board.replace_square(start_coords, " ")
  end

  def check_en_passant_move(pawn, end_coords)
    #Find the direction of the en passant based on the pawn's color
    passed_square_change = pawn.color == "w" ? [0, 1] : [0, -1]
    passed_square_coords = add_coordinates(end_coords, passed_square_change)
    #If coordinates are invalid, stop before passing it to the method
    coord_validity = passed_square_coords.all? {|num| (0..7).include?(num) }
    passed_square = @board.square(passed_square_coords)
    if passed_square.is_a?(Pawn) &&
      passed_square.color == @board.opposite_color && coord_validity
      capture(passed_square)
    end
  end

  def enable_possible_enpassants(pawn)
    enabled_pieces = []
    #Break unless the pawn can move two squares, meaning it hasn't moved yet
    en_passant_row = pawn.color == "w" ? 4 : 3
    #Stops from enabling fraud E.Ps if the pawn moves forward one square
    if pawn.coordinates[1] == en_passant_row &&
    pawn.coordinate_changes.any? {|c| c.include?(2) || c.include?(-2)  }
      adjacent_squares = pawn.adjacent_squares
      left = adjacent_squares[0]
      right = adjacent_squares[1]
      #If the piece's left is a pawn,
      #Allow the left piece to make an en passant to the right
      if left.is_a?(Pawn)
        left.enable_en_passant(:r)
        enabled_pieces << left
      elsif right.is_a?(Pawn)
        right.enable_en_passant(:l)
        enabled_pieces << right
      end
    end
    enabled_pieces
  end

  def capture(piece)
    if piece.color == "w"
      @captured_white_pieces << piece
    else
      @captured_black_pieces << piece
    end
    @board.replace_square(piece.coordinates, " ")
  end

  def current_player_s
    if @board.current_color == "w"
      "White"
    else
      "Black"
    end
  end

  def game_over(color)
    #If a player begins their turn without a king, their opponent has won.
    player = color == "b" ? "White" : "Black"
    if @draw
      puts "This game ended in a tie."
    else
      puts "#{player} won!"
    end
  end
#Piece = the piece that threatens check or checkmate
  def checkmate?
    friendly_pieces = friendly_pieces(@board.current_color)
    enemy_pieces = friendly_pieces(@board.opposite_color)
    checkmate = false
    king_moves = enemy_king.possible_moves
    king_must_move = false
    friendly_pieces.each do |piece|
      if check?(piece, enemy_king.coordinates) && piece_unattackable?(piece)
        king_must_move = true
        break
      end
    end
    return false unless king_must_move
  #This means that the opponent must move their king next turn.
  #If the king has no safe spaces to move to, checkmate.
    king_moves.each do |s_coords|
      friendly_pieces.each do |f_piece|
        #In other words, if that square is under attack by the friendly piece
        king_moves -= f_piece.possible_moves
      end
    end
    king_moves.empty? ? true : false
  end

  def friendly_pieces(color)
    friendly_pieces = []
    @board.grid.each do |square|
      if square.is_a?(Piece) && square.color == color
        friendly_pieces << square
      end
    end
    friendly_pieces
  end

  def piece_unattackable?(piece)
    enemy_pieces = friendly_pieces(@board.opposite_color)
    enemy_pieces.none? do |enemy_piece|
      enemy_piece.possible_moves.include?(piece.coordinates)
    end
  end

  def check?(piece, king_coordinates = enemy_king.coordinates)
    piece.possible_moves.include?(king_coordinates)
  end

  def enemy_king
    @board.current_color == "w" ? @board.black_king : @board.white_king
  end

  def print_king_status(moved_piece)
    if checkmate?
      puts "#{current_player_s} has checkmated their opponent!"
      @playing = false
    elsif check?(moved_piece)
      puts "#{current_player_s} puts the opponent's king in check!"
    end
  end

end
