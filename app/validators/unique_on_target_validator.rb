class UniqueOnTargetValidator < ActiveModel::EachValidator
  def initialize(options={})
    super
    # make the calling class accessible within validate_each:
    @myClass = options[:class]
  end

  def validate_each(record, attribute, value)
    # allow for NULL attribute:
    return true if value.nil? || value == ""
    @myObjects = @myClass.where(attribute.to_sym => value)

#raise self.inspect
    #@myObjects = @myClass.where(@options[:scope]
    # e.g. find all sites with the requested sitecode
    #@myObjects = @myClass.where(attribute.to_sym => value, scope: :areacode)
    #@myObjects = @myObjects.where(attribute.to_sym => value, scope: :areacode)
#raise record[:countrycode]
    unless @options[:scope].nil?
      @options[:scope].each do |myscope|
#raise @options[:scope].class.inspect
        @myObjects = @myObjects.where(myscope => record[myscope])
#raise record[myscope].inspect
#raise myscope.inspect
#raise @myObjects.inspect 
      end
    end  


    # for update_attributes, which is saving the object, we need to exclude the "this" site.
    # Otherwise, this validation would always fail, if the site is saved already
    @myObjects = @myObjects.where.not(id: record.id) unless record.id.nil?

    duplicate = false
    @myObjects.each do |myObject|
      if myObject.target == record.target
        duplicate = true
        break
      end unless record.target.nil?
    end

    if duplicate
      record.errors["#{attribute}"] << "[#{value}] is already taken for target \"#{record.target.name}\"!"
    end

  end
end
