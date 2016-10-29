class Elections
  SECTIONS = "data/sections_25.10.2015.txt"
  PROTOCOLS = "data/protocols_25.10.2015.txt"
  CANDIDATES = "data/local_candidates_25.10.2015.txt"
  VOTES = "data/votes_25.10.2015.txt"
  DEPUTIES = 240
  POSSIBLE_MARGIN = 5000

  def initialize
    @voting_areas = []
    @deputies = Hash.new(0)
    @deputies_per_area = {}
    @candidates_per_areas = {}
    @votes = {}
    @all_areas = {}
    @voters_per_areas = Hash.new(0)
    @all_voters = 0
  end

  def load_uniq_areas
    file = File.new(SECTIONS, "r")
    while (line = file.gets)
      area = line.split(';')
      @all_areas[area[1]] = area[2].split('.')[1].strip
    end
    file.close
    # puts "All areas: #{@all_areas.values.size}"
  end

  def calculate_all_people_with_vote_permission
    file = File.new(PROTOCOLS, "r")
    while (line = file.gets)
      protocols = line.split(';')
      @all_voters += protocols[6].to_i
      @voters_per_areas[protocols[2]] += protocols[6].to_i
    end
    file.close
    # puts "Voters: #{@all_voters}"
  end

  def load_candidates_per_area
    file = File.new(CANDIDATES, "r")
    while (line = file.gets)
      area = line.split(';')
      @candidates_per_areas[area[0]] = {} unless @candidates_per_areas[area[0]] 
      @candidates_per_areas[area[0]][area[2]] = area[3]
    end
    file.close
  end

  def load_votes
    file = File.new(VOTES, "r")
    while (line = file.gets)
      section = line.split(';')
      @votes[section[1]] = {} unless @votes[section[1]]
      section[2..-1].each_slice(3).to_a.each do |votes_for_party| 
        @votes[section[1]][votes_for_party[0]] = 0 unless @votes[section[1]][votes_for_party[0]]
        @votes[section[1]][votes_for_party[0]] += votes_for_party[1].to_i
      end
    end
    file.close
  end

  def get_uniq_areas
    @all_areas.values
  end

  def load_voters_per_area
    self.sort_voters_per_area
    # @voters_per_areas.each { |area_id, voters| puts "Voteres in #{@all_areas[area_id]}: #{voters}" }
  end

  def sort_voters_per_area
    @voters_per_areas = @voters_per_areas.sort_by {|_key, value| value }.reverse.to_h
  end

  def calculate_approximate_area_people
    @all_voters / DEPUTIES
  end

  def load_deputies_per_area
    self.sort_voters_per_area
    total = 0
    people_per_area = calculate_approximate_area_people
    remaining_voters = 0
    remaining_voters_areas = []

    @voters_per_areas.each do |area_id, voters|
      voters += POSSIBLE_MARGIN
      deputies = voters / people_per_area
      if deputies > 0
        @voting_areas << [area_id]
        total += deputies;
        @deputies_per_area[area_id] = deputies
      else
        remaining_in_area = voters % people_per_area
        if remaining_voters + remaining_in_area >= people_per_area
          deputies = (remaining_voters + remaining_in_area) / people_per_area
          total += deputies
          @deputies_per_area[area_id] = deputies
          remaining_voters_areas << area_id
          @voting_areas << remaining_voters_areas
          remaining_voters = 0
          remaining_voters_areas = []
        else
          remaining_voters += remaining_in_area
          remaining_voters_areas << area_id
        end
      end
    end
  end

  def calculate_votes
    @voting_areas.each do |area|
      if area.size > 1
        parties = Hash.new(0)
        area.each do |area_id|
          votes_for_area = @votes[area_id]
          votes_for_area.each do |party_id, total_votes|
            party_name = @candidates_per_areas[area_id][party_id]
            parties[party_name] += total_votes.to_i
          end
        end
        winner_party = parties.sort_by {|_key, value| value }.reverse[0][0]
        @deputies[winner_party] += 1
      else
        winner_party_id = @votes[area[0]].sort_by {|_key, value| value }.reverse[0][0]
        winner_party = @candidates_per_areas[area[0]][winner_party_id]
        @deputies[winner_party] += @deputies_per_area[area[0]]
      end
    end
    @deputies = @deputies.sort_by {|_key, value| value }.reverse
    @deputies.each { |party| puts "#{party[0]} - #{party[1]}" }
  end

  def run
    self.load_uniq_areas
    self.calculate_all_people_with_vote_permission
    self.load_candidates_per_area
    self.load_votes
    self.load_voters_per_area
    self.load_deputies_per_area
    self.calculate_votes
  end

end

elections = Elections.new
elections.run