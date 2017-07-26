require './chess.rb'
class Board
  include BasicSerializable
  attr_accessor :grid, :current_color, :black_king, :white_king

  def initialize
    @grid = []
    @pieces = []
    64.times { @grid << " "}
    @current_color = "w"
  end
  
  def setup
    (0..7).each do |num|
      replace_square([num, 1], Pawn.new("b", [num, 1]))
      replace_square([num, 6], Pawn.new("w", [num, 6]))
    end
    [0, 7].each do |num|
      replace_square([num, 0], Rook.new("b", [num, 0]))
      replace_square([num, 7], Rook.new("w", [num, 7]))
    end
    [1, 6].each do |num|
      replace_square([num, 0], Knight.new("b", [num, 0]))
      replace_square([num, 7], Knight.new("w", [num, 7]))
    end
    [2, 5].each do |num|
      replace_square([num, 0], Bishop.new("b", [num, 0]))
      replace_square([num, 7], Bishop.new("w", [num, 7]))
    end
    replace_square([3, 0], Queen.new("b", [3, 0]))
    replace_square([3, 7], Queen.new("w", [3, 7]))
    @black_king = King.new("b", [4, 0])
    replace_square([4, 0], @black_king)
    @white_king = King.new("w", [4, 7])
    replace_square([4, 7], @white_king)
    @grid.each do |square|
      if square.is_a?(Piece)
        square.link_board(self)
        @pieces << square
      end
    end
  end

  def display
    display = @grid.map do |square|
      if square.is_a?(Piece)
        square.symbol
      else
        square
      end
    end
    line = "  -----------------------------------------\n"
    puts "    0    1    2    3    4    5    6    7\n" + line
    [0,8,16,24,32,40,48,56].each_with_index do |n, index|
      puts "#{index} | #{display[n..n + 7].join("  | ")}  |\n" + line
    end
  end

  def position(coordinates)
    (coordinates[0] + 1) + coordinates[1] * 8 - 1
  end

  def square(coordinates)
    @grid[position(coordinates)]
  end

  def replace_square(coordinates, replacement)
    @grid[position(coordinates)] = replacement
  end

  def switch_colors
    @current_color = @current_color == "w" ? "b" : "w"
  end

  def opposite_color
    @current_color == "w" ? "b" : "w"
  end

  def unserialize(string)
    obj = @@serializer.parse(string)
    obj.each do |var, value|
      next if var == "@grid"
      if var == "@pieces"
        #Iterate through the array and create pieces for each element
        value.each do |piece, piece_string|
          #Scan the object tag string for its class as a string
          piece_type = piece.scan(/<(\w+):/).flatten[0]
          #Then convert that string into a constant
          piece_type = Object.const_get(piece_type)
          piece = piece_type.new(:c, [0,0])
          piece.unserialize(piece_string)
          @pieces << piece
        end
      else
        instance_variable_set(var, value)
      end
    end
  end

  def load
    @pieces.each do |piece|
      replace_square(piece.coordinates, piece)
      piece.link_board(self)
      if piece.is_a?(King)
        if piece.color == "w"
          @white_king = piece
        else
          @black_king = piece
        end
      end
    end
  end

  def <<(piece)
    @pieces << piece
  end

  def serialize
    obj = {}
    instance_variables.map do |var|
    #Grid doesn't need to be serialized if we know coordinates for every piece
      next if var == :@grid
      if var == :@pieces
        pieces = {}
        instance_variable_get(var).each do |piece|
          pieces[piece] = piece.serialize
        end
        obj[var] = pieces
      else
        obj[var] = instance_variable_get(var)
      end
    end
    @@serializer.dump obj
  end


end
