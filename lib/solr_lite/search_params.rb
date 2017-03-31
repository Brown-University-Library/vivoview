require "./lib/solr_lite/facet_field.rb"
module SolrLite
  class SearchParams
    attr_accessor :q, :fq, :facets, :page, :page_size, :fl, :sort

    DEFAULT_PAGE = 1
    DEFAULT_PAGE_SIZE = 20

    def initialize(q = "", fq = [], facets = [], page = DEFAULT_PAGE, page_size = DEFAULT_PAGE_SIZE)
      @q = q
      @fq = fq
      @facets = facets
      @page = page
      @page_size = page_size
      @fl = nil
      @sort = ""
    end

    def start_row()
      (@page - 1) * @page_size
    end

    def star_row=(start)
      # recalculate the page
      if @page_size == 0
        @page = 0
      else
        @page = (start / @page_size) + 1
      end
      nil
    end

    # Returns the string that we need render on the Browser to execute
    # a search with the current parameters.
    def to_user_query_string(facet_to_ignore = nil, q_override = nil)
      qs = ""
      q_value = q_override != nil ? q_override : @q
      if q_value != "" && @q != "*"
        qs += "&q=#{@q}"
      end
      @fq.each do |filter|
        if facet_to_ignore == filter
          # don't add this to the query string
        else
          qs += "&fq=#{filter}"
        end
      end
      qs += "&rows=#{@page_size}" if @page_size != DEFAULT_PAGE_SIZE
      qs += "&page=#{@page}" if @page != DEFAULT_PAGE
      qs += "&sort=#{@sort}" if sort != ""
      qs
    end

    # Returns the string that we need to pass Solr to execute a search
    # with the current parameters.
    def to_solr_query_string()
      qs = ""
      if @q != ""
        qs += "&q=#{@q}"
      end
      @fq.each do |filter|
        qs += "&fq=#{filter}"
      end
      qs += "&rows=#{@page_size}"
      qs += "&start=#{start_row()}"
      if sort != ""
        qs += "&sort=#{@sort}"
      end
      if @facets.count > 0
        qs += "&facet=on"
        @facets.each do |f|
          qs += "&facet.field=#{f}&f.#{f}.facet.mincount=1"
        end
      end
      qs
    end

    def to_form_values(include_q)
      values = []
      if include_q && @q != ""
        values << {name: "q", value: @q}
      end
      # Notice that we create an individual fq_n HTML form value for each
      # fq value because Rails does not like the same value on the form.
      @fq.each_with_index do |filter, i|
        values << {name: "fq_#{i}", value: filter}
      end

      values << {name: "rows", value: @page_size} if @page_size != DEFAULT_PAGE_SIZE
      values << {name: "page", value: @page} if @page != DEFAULT_PAGE
      # values << {name: "start", value: start_row()} if start_row > 0
      values << {name: "sort", value: @sort} if sort != ""
      values
    end

    def to_s()
      "q=#{@q}\nfq=#{@fq}"
    end

    def self.from_query_string(qs, facets = [])
      params = SearchParams.new
      params.facets = facets
      tokens = qs.split("&")
      tokens.each do |token|
        values = token.split("=")
        name = values[0]
        value = values[1]
        next if value == nil || value.empty?
        case
        when name == "q"
          params.q = value
        when name == "rows"
          params.page_size = value.to_i
        when name == "page"
          params.page = value.to_i
        when name == "fq"
          # Query string contains fq when _we_ build the query string, for
          # example as the user clicks on different facets on the UI.
          # A query string can have multiple fq values.
          params.fq << value
        when name.start_with?("fq_")
          # Query string contains fq_n when _Rails_ pushes HTML FORM values to
          # the query string. Rails does not like duplicate values in forms
          # and therefore we force them to be different by appending a number
          # to them (fq_1, f1_2, ...)
          params.fq << CGI::unescape(value)
        end
      end
      params
    end
  end
end
