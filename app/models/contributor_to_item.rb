require "./app/models/model_utils.rb"
class ContributorToItem
  attr_accessor :uri, :authors, :title, :volume, :issue,
    :date, :pages, :published_in, :venue, :type, :doi, :pub_med_id

  def initialize(values)
    ModelUtils.set_values_from_hash(self, values)
    @year = nil
    year = date.to_i
    if year >= 1900 && year <= 2200
      @year = year
    end
  end

  def pub_info
    info = ""
    publisher_info = publisher()
    if publisher_info != nil
      info += "#{publisher_info}. "
    end
    if @year != nil
      info += "#{@year}; "
    end
    if @volume != nil
      info += "#{@volume} "
    end
    if @issue != nil
      info += "(#{@issue}) "
    end
    if @pages != nil
      info += ": #{@pages}. "
    end
    info
  end

  def doi_url
    return nil if @doi == nil
    "http://dx.doi.org/#{@doi}"
  end

  def pub_med_url
    return nil if @pub_med_id == nil
    "http://www.ncbi.nlm.nih.gov/pubmed/?term=#{@pub_med_id}"
  end

  def pub_type
    # Typical @type values:
    #   citation:Abstract
    #   citation:Article
    #   citation:Book
    #   citation:BookSection
    #   citation:Citation
    #   citation:Conference
    #   citation:ConferenceLocation
    #   citation:ConferencePaper
    #   citation:Contributor
    #   citation:Location
    #   citation:Patent
    #   citation:Publisher
    #   citation:Review
    #   citation:Venue
    #   citation:WorkingPaper
    citationPrefix = "http://vivo.brown.edu/ontology/citation#"
    return nil if @type == nil
    return nil if !@type.start_with?(citationPrefix)
    return @type.gsub(citationPrefix,"")
  end

  def pub_type_id
    return nil if pub_type == nil
    pub_type.downcase.gsub(" ","_")
  end

  def self.from_hash_array(values)
    values.map {|v| ContributorToItem.new(v)}.sort_by {|v| v.date || ""}.reverse
  end

  private
    def publisher
      case
      when @published_in == nil && @venue == nil
        nil
      when @published_in == nil && @venue != nil
        @venue
      when @published_in != nil && @venue == nil
        @published_in
      else
        @published_in + "/" +  @venue
      end
    end
end
