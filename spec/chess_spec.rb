require "board.rb"
require "pieces.rb"
require "chess.rb"

describe "#add_coordinates" do
  context "when adding [1,1] and [2,3]" do
    it "returns [3,4]" do
      expect(add_coordinates([1,1],[2,3])).to eql([3,4])
    end
  end
end
describe "Pieces" do

  describe "#symbol" do
    context "when a black pawn's symbol is called" do
      it "returns a black pawn symbol" do
        black_pawn = Pawn.new(:b, [0,0])
        expect(black_pawn.symbol).to eql("\u265F")
      end
    end
  end

  describe "#possible_moves" do
    context "with a black pawn at [0,0]" do
      it "includes [0,1]" do
        black_pawn = Pawn.new(:b, [0,0])
        black_pawn.link_board(Board.new)
        expect(black_pawn.possible_moves).to include([0,1])
      end
    end
  end
end

describe Board do
  describe "#position" do
    context "when called with coordinates [4,5]" do
      it "returns 44, its index in the grid array" do
        expect(subject.position([4,5])).to eql(44)
      end
    end
  end

  describe "#square" do
    context "when given coordinates to find a marked square" do
      it "returns the marked square" do
        subject.grid[subject.position([3,7])] = "test"
        expect(subject.square([3,7])).to eql("test")
      end
    end
  end
end
