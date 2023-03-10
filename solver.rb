# frozen_string_literal: true

require 'sudoku'
$LOAD_PATH.unshift('/Users/andrew.mcinally/Desktop/testing_grounds/sudoku/solver.rb')

puts Sudoku.solve(Sudoku::Puzzle.new(ARGF.readlines))

# The Sudoku module provides functionality for solving Sudoku puzzles.
#
# A Sudoku puzzle is a 9x9 grid of cells, with each cell containing a number between 1 and 9. The goal of the puzzle is
# to fill in the grid such that each row, column, and 3x3 sub-grid contains the numbers 1 through 9 exactly once.
#
# This module provides a class, `Puzzle`, which represents a Sudoku puzzle and can be used to solve it. It also provides
# methods for scanning the puzzle and finding possible solutions, as well as error classes for handling invalid and
# unsolvable puzzles.
#
# Example usage:
#
#     require 'sudoku'
#     puzzle = Sudoku::Puzzle.new(File.read('puzzle.txt'))
#     solution = Sudoku.solve(puzzle)
#     puts solution
#
module Sudoku

  # A class representing a Sudoku puzzle.
  class Puzzle
    ASCII = '.123456789'
    BIN = "\000\001\002\003\004\005\006\007\008\009"

    def initialize(lines)
      s = if lines.respond_to? :join
            lines.join
          else
            lines.dup
          end

      s.gsub!(/\s/, '')

      raise Invalid, 'Grid is the wrong size' unless s.size == 81

      return unless (i = s.index(/[^123456789\.]/))

      raise Invalid, "Illegal character #{s[i, 1]} in puzzle"

      s.tr!(ASCII, BIN)
      @grid = s.unpack('c*')
    end

    def to_s
      (0..8).collect { |r| @grid[r * 9, 9].pack('c9') }.join("\n").tr(BIN, ASCII)
    end

    def dup
      copy = super
      @grid = @grid.dup
      copy
    end

    def [](row, col)
      @grid[row * 9 + col]
    end

    def []=(row, col, newvalue)
      raise Invalid, 'illegal cell value' unless (0..9).include? newvalue

      @grid[row * 9 + col] = newvalue
    end

    BoxOfIndex = [
      0, 0, 0, 1, 1, 1, 2, 2, 2, 0, 0, 0, 1, 1, 1, 2, 2, 2, 0, 0, 0, 1, 1, 1, 2, 2, 2,
      3, 3, 3, 4, 4, 4, 5, 5, 5, 3, 3, 3, 4, 4, 4, 5, 5, 5, 3, 3, 3, 4, 4, 4, 5, 5, 5,
      6, 6, 6, 7, 7, 7, 8, 8, 8, 6, 6, 6, 7, 7, 7, 8, 8, 8, 6, 6, 6, 7, 7, 7, 8, 8, 8
    ].freeze

    def each_unknown
      0.upto 8 do |row|
        0.upto 8 do |col|
          index = row * 9 + col
          next if @grid[index] != 0

          box = BoxOfIndex[index]
          yield row, col, box
        end
      end
    end

    def duplicates?
      0.upto(8) { |row| return true if rowdigits(row).uniq! }
      0.upto(8) { |col| return true if coldigits(col).uniq! }
      0.upto(8) { |box| return true if boxdigits(box).uniq! }

      false
    end

    AllDigits = [1, 2, 3, 4, 5, 6, 7, 8, 9].freeze

    def possible(row, col, box)
      AllDigits - (rowdigits(row) + coldigits(col) + boxdigits(box))
    end

    private

    def rowdigits(row)
      @grid[row * 9, 9] - [0]
    end

    def coldigits(col)
      result = []
      col.step(80, 9) do |i|
        v = @grid[i]
        result << v if v != 0
      end
      result
    end

    BoxToIndex = [0, 3, 6, 27, 30, 33, 54, 57, 60].freeze

    def boxdigits(bxx)
      i = BoxToIndex[bxx]
      [
        @grid[i], @grid[i + 1], @grid[i + 2],
        @grid[i + 9], @grid[i + 10], @grid[i + 11],
        @grid[i + 18], @grid[i + 19], @grid[i + 20]
      ] - [0]
    end
  end

  class Invalid < StandardError
  end

  class Impossible < StandardError
  end

  def self.scan(puzzle)
    unchanged = false

    until unchanged
      unchanged = true
      rmin, cmin, pmin = nil
      min = 10

      puzzle.each_unknown do |row, col, box|
        p = puzzle.possible(row, col, box)

        case p.size
        when 0
          raise Impossible
        when 1
          puzzle[row, col] = p[0]
          unchanged = false
        else
          if unchanged && p.size < min
            min = p.size
            rmin = row
            cmin = col
            pmin = p
          end
        end
      end
    end

    [rmin, cmin, pmin]
  end

  def self.solve(puzzle)
    puzzle = puzzle.dup

    r, c, p = scan(puzzle)

    return puzzle if r.nil?

    p.each do |guess|
      puzzle[r, c] = guess

      begin
        return solve(puzzle)
      rescue Impossible
        next
      end
    end
    raise Impossible
  end
end
