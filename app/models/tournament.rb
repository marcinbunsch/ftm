class Tournament < ActiveRecord::Base
	
	belongs_to :user
  belongs_to :tournament_type

  has_one :tournament_metadata
  
  has_one :schedule

  has_many :tournament_teams
  has_many :teams, :through => :tournament_teams
  has_many :tournament_fields
  has_many :fields, :through => :tournament_fields

  # Creates games and game slots. This is an entry point for scheduling a tournament.
  def empty_schedule
    if self.fields.size > 0 and self.teams.size == self.tournament_metadata.teams_count
      self.game_slots.destroy_all
      self.games.destroy_all
      teams_count = self.tournament_metadata.teams_count
      games_count = teams_count * (teams_count - 1) / 2
      games_count.times do
        game_slot = GameSlot.new
        game_slot.start = self.start_date.to_datetime
        game_slot.end = game_slot.start + self.tournament_metadata.default_game_duration.minutes
        game_slot.field = self.fields.first
        self.game_slots << game_slot
      end
    end
  end

  # Creates games and games slots using round-robin algorithm.
  # TODO: currently assuming even number of teams, improve this!
  def round_robin_schedule
    if self.fields.size > 0 and self.teams.size == self.tournament_metadata.teams_count
      self.empty_schedule
      self.games.destroy_all
      teams_count = self.teams.size
      games_count = self.game_slots.count
      games_per_round = teams_count / 2
      rounds = self.game_slots.size / games_per_round
      home = []
      away = []
      for i in 0..games_per_round - 1
        home << self.teams[i]
        away << self.teams[2 * games_per_round - i - 1]
      end
      for i in 0..rounds - 1
        for j in 0..games_per_round - 1
          current_game = create_game home[j], away[j]
          current_game.game_slot = self.game_slots[games_per_round * i + j]
          current_game.tournament = self
          current_game.save
        end
        rotate_teams home, away
      end
    end
  end

  def rotate_teams(home, away)
    stable = home.shift
    home.unshift away.shift
    away.push home.pop
    home.unshift stable
  end

  def round_robin_ftm_schedule
    if self.fields.size > 0 and self.teams.size == self.tournament_metadata.teams_count
      self.empty_schedule
      self.games.destroy_all
      teams_count = self.teams.size
      games_count = self.game_slots.count
      games_per_round = teams_count / 2
      rounds = self.game_slots.size / games_per_round
      for game_no in 0..games_count - 1
        round = game_no / games_per_round
        k1 = game_no - round * games_per_round
        k2 = teams_count - 1 - k1
        home_team = self.teams[round_robin_permutation teams_count, round, k1]
        away_team = self.teams[round_robin_permutation teams_count, round, k2]
        current_game = create_game home_team, away_team
        current_game.game_slot = self.game_slots[game_no]
        current_game.tournament = self
        current_game.save
      end
    end
  end

  def round_robin_permutation(teams_count, r, k)
    if k == 0
      return 0
    elsif k <= r
      return teams_count - r + k - 1
    else
      return k - r 
    end
  end

  def create_game(home_team, away_team)
    game = Game.new
    game.home_team = home_team
    game.away_team = away_team
    game
  end

  def benchmark
    Benchmark.bm(10) do |x|
      x.report("round robin ftm schedule") do
        self.round_robin_ftm_schedule
      end
      x.report("round robin schedule") do
        self.round_robin_schedule
      end
    end
  end

end
