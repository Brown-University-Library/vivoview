require "cgi"
require "./lib/sparql/http_json.rb"

module Sparql
  class Query
    attr_reader :raw_response, :raw_results
    def initialize(fuseki_url, query)
      executed = false
      query_escaped = CGI.escape(query.gsub(/\n/, ''))
      url = "#{fuseki_url}?query=#{query_escaped}&output=json&stylesheet="
      @raw_response = HttpJson.get(url)
      @raw_results = @raw_response["results"]["bindings"]
    end

    # Returns an array of hashes. Each hash has the results
    # for a single row, e.g: results[0] = {k1: v1, k2: v2}
    # Notice that we are losing whether the value is a literal
    # or a URI, since we treat them all as literals here.
    def results
      @hashes ||= begin
        rows = @raw_response["results"]["bindings"]
        rows.map do |row|
          hash = {}
          row.keys.each do |key|
            hash[key.to_sym] = row[key]["value"]
          end
          hash
        end
      end
    end

    def to_value
      return nil if results.count == 0
      results.first.values.first
    end

    # Uses the array of results to populate an object of the
    # given klass. This is used when the results are in the
    # form:
    #      results[0] = {p: p1, o: v10}
    #      results[1] = {p: p2, o: v20
    #      results[2] = {p: p3, o: v30}
    #
    # Notice that all the results have "p" and "o" keys. The
    # value in the "p" key is the predicate used to determine
    # what attribute in the given class should be set with
    # the value in the "o" key.
    #
    # Returns an object with the values set as follows
    #       x.k1 = v10
    #       x.k2 = v20
    #       x.k3 = v30
    #
    # `klass` should implement method
    # `field_for_predicate(predicate) => attr_name`
    # that receives a string with the predicate and returns
    # the name of the attribute in klass that is associated
    # with it.
    def to_object(klass)
      if klass.methods.include?(:field_for_predicate) == false
        raise "Klass must provide field_for_predicate() method"
      end
      obj = klass.new
      results.each do |tuple|
        predicate = tuple[:p]
        value = tuple[:o]
        field_def = klass.field_for_predicate(predicate)
        if field_def
          if field_def[:type] == "a"
            # it's an array
            obj.send(field_def[:prop]) << value
          else
            # assume is single value
            obj.send(field_def[:prop]+"=", value)
          end
        end
      end
      obj
    end
  end
end
