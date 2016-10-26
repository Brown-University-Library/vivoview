require "./app/models/faculty.rb"
require "./lib/solr/solr.rb"
require "./lib/solr/search_params.rb"
require "./lib/solr/search_results.rb"
class FacultySolrize
  def initialize(solr_url)
    @solr_url = solr_url
    @solr = Solr::Solr.new(@solr_url)
  end

  def add_all()
    uris = Faculty.all_uris
    puts "Processing #{uris.count} faculty records..."
    uris.each_with_index do |uri, i|
      id = uri.split("/").last
      json = get_json(id)
      @solr.update(json)
      if ((i+1) % 100) == 0
        @solr.commit
        puts "...#{i+1}"
      end
    end
    @solr.commit()
  end

  def add_new()
    params = Solr::SearchParams.new()
    params.fl = ["uri"]
    uris = Faculty.all_uris
    puts "Processing #{uris.count} faculty records..."
    uris.each_with_index do |uri, i|
      params.q = "uri:\"#{uri}\""
      solr_response = @solr.search(params)
      results = Solr::SearchResults.new(solr_response)
      if results.num_found == 0
        # byebug
        id = uri.split("/").last
        json = get_json(id)
        @solr.update(json)
        puts "added #{uri}"
        if ((i+1) % 100) == 0
          @solr.commit
          puts "commit...#{i+1}"
        end
      else
        puts "skipped #{uri}"
      end
    end
    @solr.commit()
  end

  def add_one(id)
    json = get_json(id)
    @solr.update(json)
  end

  def get_json(id)
    faculty = Faculty.get_one(id)
    JSON.pretty_generate(JSON.parse(faculty.to_json))
  end
end
