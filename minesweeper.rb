require 'byebug'
require 'yaml'

class Tile

  NEIGHBOR_SPACES = [
    [-1,-1],
    [-1, 0],
    [-1, 1],
    [0, -1],
    [0,  1],
    [1, -1],
    [1,  0],
    [1,  1]
  ]

  attr_accessor :internal_state, :pos, :reveal_state, :grid

  def initialize(grid, pos, reveal_state, internal_state)
    # pos = [i, j]
    @grid = grid
    @pos = pos
    @reveal_state = reveal_state
    @internal_state = internal_state
  end

  def flag
    @reveal_state = "F"
  end

  def lose
    if @reveal_state == "B"
      puts "you lose"
      exit
    end
  end

  def reveal
    #byebug
    @reveal_state = @internal_state
    lose

    bomb_neighbors = 0
    # n = 0

    NEIGHBOR_SPACES.each do |space|
      new_i = @pos[0] + space[0]
      new_j = @pos[1] + space[1]
      new_tile = @grid[new_i][new_j] if new_i.between?(0, 8) && new_j.between?(0, 8)

      next if new_tile.nil? || new_tile.reveal_state == new_tile.internal_state


      if new_tile.internal_state.is_a?(Fixnum)
        new_tile.reveal_state = new_tile.internal_state unless @internal_state.is_a?(Fixnum)
        # break
      elsif new_tile.internal_state == "_"
         new_tile.reveal
      end
      # @reveal_state = @internal_state if @grid[new_i][new_j].internal_state == "_"
    end
  end

  def neighbors
    # @neighbors ||= begin
      # NEIGHBOR_SPACES.map do |space|
      #   new_i = @pos[0] + space[0]
      #   new_j = @pos[1] + space[1]
      #
      #   if new_i.between?(0, 8) && new_j.between?(0, 8)
      #     tile = @grid[new_i][new_j]
      #     # bomb_neighbors += 1 if tile && tile.internal_state == "B"
      #   end
      # end
    # end
  end

  def neighbor_bomb_count

    bomb_neighbors = 0
    NEIGHBOR_SPACES.each do |space|
      new_i = @pos[0] + space[0]
      new_j = @pos[1] + space[1]

      if new_i.between?(0, 8) && new_j.between?(0, 8)
        tile = @grid[new_i][new_j]
        bomb_neighbors += 1 if tile && tile.internal_state == "B"
      end

    end
    @internal_state = bomb_neighbors if bomb_neighbors > 0 && @internal_state != "B"

  end

  def inspect
    reveal_state
  end

end

class Board
  attr_reader :grid, :start_time, :end_time, :elapsed_time

  def initialize
    @start_time = Time.now
    @elapsed_time = 0
    @end_time = 0
    @grid = Array.new(9) { Array.new(9, nil) }
    create_tiles
    seed_bombs
    bomb_counter

  end

  def create_tiles
    @grid.each_with_index do |row, i|
      row.each_with_index do |space, j|
        @grid[i][j] = Tile.new(@grid, [i, j], "*", "_")
      end
    end
  end

  def bomb_coords
    bomb_pos = []
    until bomb_pos.count == 1
      i = rand(9)
      j = rand(9)
      bomb_pos << [i, j] unless bomb_pos.include?([i, j])
    end
    bomb_pos
  end

  def seed_bombs
    bomb_pos = bomb_coords
    bomb_pos.each do |pos|
      t =  @grid[pos[0]][pos[1]]
      t.internal_state = "B"
    end
  end

  def bomb_counter
    @grid.each do |row|
      row.each do |tile|
        tile.neighbor_bomb_count
      end
    end
  end

  def render
    display_grid = Array.new(9) { Array.new(9, "*") }

    @grid.each_with_index do |row, i|
      p row
    end
  end

  def end_game
    @end_time = Time.now
    @elapsed_time += @start_time - @end_time
    @grid.each do |row|
      row.each do |tile|
        return false unless tile.internal_state == tile.reveal_state ||
                            tile.internal_state == "B" && tile.reveal_state == "F"
      end
    end
    true
  end

end


class Game

  attr_accessor :board

  def initialize
    puts "load new game or continue (n/c)"
    case gets.chomp
    when "n"
      new_game
    when "c"
      puts "enter filename"
      filename = gets.chomp
      File.open("#{filename}.yaml") do |f|
        board = YAML::load(f)
        @board = board
        board.start_time = Time.now
        play
      end
    end
  end

  def new_game
    @board = Board.new
    play
  end

  def play
    until @board.end_game
      @board.render
      response = nil
      saving
      loop do
        puts "Would you like to reveal or flag a tile? (r/f)"
        response = gets.chomp
        break if response == "r" || response == "f"
      end

      if response == "r"
        puts "Which tile would you like to reveal?"
        pos = gets.chomp.split(", ")
        # pos = "1, 2"
        @board.grid[pos[0].to_i][pos[1].to_i].reveal
      end

      if response == "f"
        puts "Which tile would you like flag?"
        pos = gets.chomp.split(", ")
        @board.grid[pos[0].to_i][pos[1].to_i].flag
      end

    end
    time_taken = board.elapsed_time
    puts "Time: #{time_taken}"
    puts "You won!"
    exit
  end

  def saving
    board.end_time = Time.now
    puts "Would you like to save? (y/n)"
    case gets.chomp
    when "y"
      board.elapsed_time += (board.end_time - board.start_time)
      puts "#{elapsed_time}"
      save_game
      exit
    when "n"
      nil
    end
  end

  def save_game
    puts "enter filename"
    filename = gets.chomp
    File.open("#{filename}.yaml", "w") do |f|
      f.puts @board.to_yaml
    end
    exit
  end

  def load_game

  end

end

g = Game.new
