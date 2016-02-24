class Validate_Hash_Uniqueness < ActiveModel::Validator
  def validate(record)
    
    @object_with_same_identifierhash = TextDocument.select { |i| i.identifierhash == record[:identifierhash]  }
    
    @object_with_same_identifierhash = @object_with_same_identifierhash.select {|i| i.id != record[:id]} unless record[:id].nil?
    
          #raise record[:id].inspect
    #.select {|i| i.id != record.id}
          #raise @object_with_same_identifierhash.inspect
    
    unless @object_with_same_identifierhash.count == 0
      record.errors[:identifierhash] << "has already been taken"     
            #raise record.errors.inspect
    end
       
  end # def
end


class TextDocument < ActiveRecord::Base
  serialize :identifierhash, Hash #,JSON #, YAML #, Hash
  
  # transient field for representing :identifierhash in YAML format:
  attr_accessor :identifieryaml
  
  def identifieryaml
    return nil if identifierhash.nil? || identifierhash == {}
    
    return YAML::dump(identifierhash).gsub('--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess','').gsub(/^\n/,'')
  end
  
  
  
  # find TextDocument with a => a and b => b in the hash:
  # e.g. try with rails console:
  # TextDocument.where("identifierhash LIKE ? AND identifierhash LIKE ?", "%\na: a\n%", "%\nb: b\n%")
  # yields:
  # => #<ActiveRecord::Relation [#<TextDocument id: 2, identifierhash: {"a"=>"a", "b"=>"b"}, content: "dhgsil", created_at: "2015-06-07 17:54:54", updated_at: "2015-06-0754:54">, #<TextDocument id: 3, identifierhash: {"b"=>"b", "a"=>"a"}, content: "", created_at: "2015-06-07 17:55:18", updated_at: "2015-06-07 17:55:18">]>
  
  # to see the exact format, how the hash is stored in the database, try on rails console sth. like:
  # irb(main):062:0> TextDocument.find(2).typecasted_attribute_value("identifierhash")
  # yields:
  # TextDocument Load (1.0ms)  SELECT  "text_documents".* FROM "text_documents"  WHERE "text_documents"."id" = ? LIMIT 1  [["id", 2]]
  # => "--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\na: a\nb: b\n"
  # for 
  # irb(main):063:0> TextDocument.find(2)
  # TextDocument Load (1.0ms)  SELECT  "text_documents".* FROM "text_documents"  WHERE "text_documents"."id" = ? LIMIT 1  [["id", 2]]
  # => #<TextDocument id: 2, identifierhash: {"a"=>"a", "b"=>"b"}, content: "dhgsil", created_at: "2015-06-07 17:54:54", updated_at: "2015-06-07 17:54:54">
  
  validates :identifierhash, presence: true #,   uniqueness: true
  # uniqueness above does now work correctly, so I have created a custom validator:
  validates_with Validate_Hash_Uniqueness

end
