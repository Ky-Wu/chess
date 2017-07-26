require './chess.rb'
class Piece
  include BasicSerializable
  attr_accessor :color, :coordinates
  
  def initialize(color, coordinates)
    @color = color
    @coordinates = coordinates
  end

  def serialize
    obj = {}
    instance_variables.map do |var|
      next if var == "@board"
      obj[var] = instance_variable_get(var)
    end
    @@serializer.dump obj
  end

  def link_board(board)
    @board = board
  end

  def valid_coordinate?(coordinate)
    coordinate.all? { |coord| (0..7).include?(coord) }
  end

  def possible_moves
    possible_moves = []
    @position_changes.each do |change|
      possible_move = @coordinates
      until !valid_coordinate?(possible_move)
        s = @board.square(possible_move)
        if s.is_a?(Piece) && possible_move != @coordinates
          break if s.color == @board.current_color
          possible_moves << possible_move
          #Make the coordinate invalid to cut off the path in that direction
          #if it's a piece of the opposite color
          break if s.color == @board.opposite_color
        elsif possible_move != @coordinates
          possible_moves << possible_move  unless possible_move == @coordinates
        end
        possible_move = add_coordinates(change, possible_move)
      end
    end
    possible_moves
  end

  def adjacent_squares
    left_coords = add_coordinates(@coordinates, [-1, 0])
    left_square = @board.square(left_coords)
    right_coords = add_coordinates(@coordinates, [1, 0])
    right_square = @board.square(right_coords)
    [left_square, right_square]
  end

end

class Pawn < Piece
  attr_accessor :coordinate_changes
  def initialize(color, coordinates)
    super(color, coordinates)
    @coordinate_changes = @color == "w" ? [[0,-1], [0, -2]] : [[0,1], [0,2]]
  end

  def possible_moves
    check_diagonal_moves
    possible_moves = []
    @coordinate_changes.each do |change|
      move = add_coordinates(change, @coordinates)
      possible_moves << move if valid_coordinate?(move)
    end
    possible_moves
  end

  def check_diagonal_moves
    diagonal_changes = @color == "w" ? [[1,-1],[-1,-1]] : [[1,1],[-1,1]]
    diagonal_changes.each do |change|
      diagonal_coord = add_coordinates(change, @coordinates)
      diagonal_square = @board.square(diagonal_coord)
      if valid_coordinate?(diagonal_coord) && diagonal_square.is_a?(Piece) &&
         diagonal_square.color == @board.opposite_color
        @coordinate_changes << change
      end
    end
  end

  def enable_en_passant(left_or_right)
    diagonal_changes = @color == "w" ? [[1,-1],[-1,-1]] : [[1,1],[-1,1]]
    if left_or_right == :l
      @coordinate_changes << diagonal_changes[1]
    else
      @coordinate_changes << diagonal_changes[0]
    end
  end

  def restrict_moves
    @coordinate_changes = @color == "w" ? [[0,-1]] : [[0,1]]
  end

  def symbol
    @color == "w" ? "\u2659" : "\u265F"
  end

  def not_moved?
    @coordinate_changes.any? do |c|
      c.include?(2) || c.include?(-2)
    end
  end

  def eighth_rank?
    eighth_rank = @color == "w" ? 0 : 7
    @coordinates[1] == eighth_rank
  end
end

class Rook < Piece

  def initialize(color, coordinates)
    super(color, coordinates)
    @position_changes = [[1,0],[-1,0],[0,1],[0,-1]]
  end

  def symbol
    @color == "w" ? "\u2656" : "\u265C"
  end

end

class Knight < Piece
  def possible_moves
    moves = []
    changes = [[1,2],[-1,2],[1,-2],[-1,-2],[2,1],[-2,1],[2,-1],[-2,-1]]
    changes.each do |change|
      move = add_coordinates(change, @coordinates)
      if valid_coordinate?(move)
        s = @board.square(move)
        next if s.is_a?(Piece) && s.color == @color
        moves << move
      end
    end
    moves
  end

  def symbol
    @color == "w" ? "\u2658" : "\u265E"
  end

end

class Bishop < Piece
  def initialize(color, coordinates)
    super(color, coordinates)
    @position_changes = [[1,1],[1,-1],[-1,1],[-1,-1]]
  end

  def symbol
    @color == "w" ? "\u2657" : "\u265D"
  end
end

class Queen < Piece
  def initialize(color, coordinates)
    super(color, coordinates)
    @position_changes = [[1,1],[1,-1],[-1,1],[-1,-1],[1,0],[-1,0],[0,1],[0,-1]]
  end

  def symbol
    @color == "w" ? "\u2655" : "\u265B"
  end
end

class King < Piece
  def possible_moves
    moves = []
    changes = [[1,0],[-1,0],[0,1],[0,-1],[1,1],[-1,1],[1,-1],[-1,-1]]
    changes.each do |change|
      move = add_coordinates(change, @coordinates)
      if valid_coordinate?(move)
        s = @board.square(move)
        next if s.is_a?(Piece) && s.color == @color
        moves << move
      end
    end
    moves
  end

  def symbol
    @color == "w" ? "\u2654" : "\u265A"
  end
end

def add_coordinates(c1, c2)
  [c1[0] + c2[0], c1[1] + c2[1]]
end
