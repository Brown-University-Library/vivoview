require "net/http"
require "./lib/solr/search_params.rb"
module Solr
  class Solr
    def initialize(solr_url)
      @solr_url = solr_url
      @verbose = ENV["SOLR_VERBOSE"] == "true"
      @logger = Rails::logger
    end

    def search(params)
      query_string = "fl=uri,record_type"
      query_string += "&wt=json&indent=on"
      query_string += "&" + params.to_solr_query_string()
      url = "#{@solr_url}/select?#{query_string}"
      get(url)
    end

    # shortcut for search
    def search_text(terms)
      facets = ["record_type", "affiliations.name"]
      params = SearchParams.new(terms, facets)
      search(params)
    end

    def start_row(page, page_size)
      (page - 1) * page_size
    end

    def update(json)
      url = @solr_url + "/update/json/docs"
      r1 = post(url, json)
      r2 = commit()
      [r1, r2]
    end

    def update_fast(json)
      url = @solr_url + "/update/json/docs"
      r1 = post(url, json)
      # r2 = commit()
      [r1, nil]
    end

    def delete_all!()
      url = @solr_url + "/update"
      payload = "<delete><query>*:*</query></delete>"
      payload = '{ "delete" : { "query" : "*:*" } }'
      r1 = post(url, payload)
      r2 = commit()
      [r1, r2]
    end

    def commit()
      commit_url = @solr_url + "/update?commit=true"
      get(commit_url)
    end

    private
      def post(url, payload)
        log_msg("Solr HTTP POST #{url}")
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        if url.start_with?("https://")
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        request = Net::HTTP::Post.new(uri.request_uri)
        request["Content-Type"] = "application/json"
        request.body = payload
        response = http.request(request)
        JSON.parse(response.body)
      end

      def get(url)
        log_msg("Solr HTTP GET #{url}")
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        if url.start_with?("https://")
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        request = Net::HTTP::Get.new(uri.request_uri)
        request["Content-Type"] = "application/json"
        response = http.request(request)
        JSON.parse(response.body)
      end

      def log_msg(msg)
        return if @verbose == false
        if @logger
          @logger.info msg
        else
          puts msg
        end
      end
  end
end
