class Chess
  def initialize
    @board = Board.new()
    @board.setup
    @captured_white_pieces = []
    @captured_black_pieces = []
    @playing = true
  end

  def play
    while @playing
      @board.display
      get_move
      @board.switch_colors
    end
    game_over(@board.current_color)
  end

  def get_move
    moving_piece_coords = select_square
    moving_piece = @board.square(moving_piece_coords)
    puts "Please do one of the following:"
    puts "-Enter coordinates of the square where you want to move to."
    puts "---Square being moved: #{moving_piece_coords}"
    puts "---Valid moves: #{moving_piece.possible_moves}"
    puts "-Enter \"back\" to go back to selecting a square to move."
    while input = gets.chomp
      coords = input.scan(/[0-7]/)
      # If the input contains two integers for coordinates
      if coords.length == 2
        coords.map! {|num| num.to_i }
        if moving_piece.possible_moves.include?(coords)
          make_move(moving_piece_coords, coords)
          break
        end
      elsif input.downcase == 'back'
        @board.display
        # Go back to the beginning of this method
        get_move
        break
      else
        puts "Not valid input. Please make a valid move or enter \"back\"."
      end
    end
  end

  def make_move(start_coords, end_coords)
    moving_piece = @board.square(start_coords)
    end_square = @board.square(end_coords)
    capture(end_square) if end_square.is_a?(Piece)
    if end_square.is_a?(King)
      @playing = false
    elsif moving_piece.is_a?(Pawn)
      #Capture the passed piece if the pawn is performing an en passant
      check_en_passant_move(moving_piece, end_coords)
      #Then move the Pawn to the square
      move_to(moving_piece, end_coords)
      #Check to see if the pawn is enabling en passants
      enabled_pieces = enable_possible_enpassants(moving_piece)
      #The pawn has made a move; it's lost its initial double move
      if moving_piece.not_moved?
        moving_piece.restrict_moves
      end
      #Restrict pawn moves to eliminate en passants after 1 turn
      restricted_pawns = restrict_pawn_moves(enabled_pieces)
    else
      move_to(moving_piece, end_coords)
    end

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
    passed_square_change = pawn.color == :w ? [0, 1] : [0, -1]
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
    en_passant_row = pawn.color == :w ? 4 : 3
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
    if piece.color == :w
      @captured_white_pieces << piece
    else
      @captured_black_pieces << piece
    end
    @board.replace_square(piece.coordinates, " ")
  end

  def select_square
    puts "Please input coordinates to select a square with your piece."
    puts "Format: Horizontal #, Vertical #."
    puts "Current color: #{@board.current_color.to_s.upcase}"
    while input = gets.chomp
      coordinates = input.scan(/[0-7]/)
      if coordinates.length == 2
        coordinates.map! {|num| num.to_i}
        if @board.square(coordinates).is_a?(Piece) &&
           @board.square(coordinates).color == @board.current_color
           return coordinates
           break
        end
      end
      puts "Please use the format: H#, V#,"\
           "to select a square with the current color."
    end
  end

  def game_over(color)
    #If a player begins their turn without a king, their opponent has won.
    player = color == :b ? "White" : "Black"
    puts "#{player} won!"
  end

  def draw_game
  end

end
