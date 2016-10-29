class Elections
  VOTES = "data/votes_pe2014.txt"
  PARTIES = "data/parties_pe2014.txt"
  PROTOCOLS = "data/protocols_pe2014.txt"
  DEPUTIES = 240
  START_COUNTRIES_ID = 320100001
  POSSIBLE_MARGIN = -250

  def initialize
    @votes_per_section = {}
    @people_per_section = {}
    @deputies_per_section = []
    @parties = {}
    @deputies = Hash.new(0)
    @all_voters = 0
  end

  def load_parties
    file = File.new(PARTIES, "r")
    while (line = file.gets)
      party = line.split(';')
      @parties[party[0]] = party[1]
    end
    file.close
    puts @parties
  end

  def calculate_all_people_with_vote_permission
    file = File.new(PROTOCOLS, "r")
    while (line = file.gets)
      section = line.split(';')
      index = section[0].to_i < START_COUNTRIES_ID ? 3 : 4 
      people_in_section = section[index].to_i
      @people_per_section[section[0]] = people_in_section
      @all_voters += people_in_section
    end
    file.close
    puts "Total people: #{@all_voters}"
  end

  def calculate_approximate_area_people
    @all_voters / DEPUTIES
  end

  def load_votes
    file = File.new(VOTES, "r")
    while (line = file.gets)
      section = line.split(';')
      section_id = section[0]
      section_votes = section[1..-1]
      @votes_per_section[section_id] = {}
      section_votes.each_slice(2).to_a.each_with_index do |party_vote, index|
        @votes_per_section[section_id][index+1] = party_vote[0]
      end
    end
    file.close
  end

  def group_votes_per_areas
    counter = 0
    sections = []
    @people_per_section.each do |section_id, people|
      counter += people
      if counter > self.calculate_approximate_area_people + POSSIBLE_MARGIN
        @deputies_per_section << sections
        counter = 0
        sections = []
      else
        sections << section_id
      end
    end
    if counter > 0 && sections.size > 0
      @deputies_per_section << sections
    end
  end

  def calculate_deputies
    @deputies_per_section.each do |areas|
      results_per_area = Hash.new(0)
      areas.each do |section_id|
        @votes_per_section[section_id].each do |party_id, votes|
          results_per_area[party_id] += votes.to_i
        end
      end
      results_per_area = results_per_area.sort_by {|_key, value| value }.reverse
      @deputies[results_per_area[0][0]] += 1
    end
  end

  def print_results
    @deputies.each { |party_id, deputies| puts "#{@parties[party_id.to_s].strip} - #{deputies}" }
  end

  def run
    self.load_parties
    self.calculate_all_people_with_vote_permission
    self.load_votes
    self.group_votes_per_areas
    self.calculate_deputies
    self.print_results
  end

end

elections = Elections.new
elections.run