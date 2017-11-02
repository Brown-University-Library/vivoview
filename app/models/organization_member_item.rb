require "./app/models/model_utils.rb"

class OrganizationMemberItem
  attr_accessor :id, :faculty_uri, :label, :general_position, :specific_position
  def initialize(values = nil)
    ModelUtils.set_values_from_hash(self, values)
    if values["uri"] != nil
      @faculty_uri = values["uri"]
    end
    @id = @faculty_uri
  end

  def vivo_id
    return "" if @id == nil
    @id.split("/").last
  end

  def self.from_hash_array(values)
    values.map { |v| OrganizationMemberItem.new(v)}.sort_by {|v| v.label || ""}
  end
end
