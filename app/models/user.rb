class ValidateSiteExists < ActiveModel::Validator
  def validate(record)
      if User.parentClass.exists? id: record.site_id
        return true
      else
        record.errors[:site_id] << "id=#{record.site_id} does not exist in the database!"
      end
  end
end

class Validate_ExtensionLength < ActiveModel::Validator
  def validate(record)
    
    if !record.site.nil?
      @site = Site.find(record.site)
    end
    
    if !@site.nil?
      if record.extension.length.to_i != @site.extensionlength.to_i
        record.errors[:extension] << "length must be #{@site.extensionlength.to_s}" # + " but is #{record.extension.length.to_s}"      
      end
    end
       
  end # def
end

class Validate_DisplayLength < ActiveModel::Validator
  def validate(record)
    
    givennamelength = record.givenname.nil? ? 0 : record.givenname.length.to_i
        #abort givennamelength.inspect
    familynamelength = record.familyname.nil? ? 0 : record.familyname.length.to_i
    
    maxlength = 29
    errormessage = "too long (#{givennamelength + familynamelength}). Sum length of #{:givenname.to_s} (#{givennamelength.to_s}) and #{:familyname.to_s} (#{familynamelength.to_s}) must not exceed #{maxlength}"
     
    errortargetsymbol = givennamelength > familynamelength ? :givenname : :familyname
    errortargetsymbol = :givenname_or_familyname
    
    
    if givennamelength + familynamelength > 29
      record.errors[errortargetsymbol] << errormessage      
      #record.errors[:familyname] << "too long. Sum length of #{:givenname.to_s} and #{:familyname.to_s} must not exceed 29"      
    end 
       
  end # def
end

class User < Provisioningobject #< ActiveRecord::Base

  def self.all_cached
#    cache_time = Rails.cache.fetch('User.all.cache_time', expires_in: 1.minute) { Time.now }
    Rails.cache.fetch('User.all', expires_in: 1.minute) { all }
#    if Time.now - cache_time > 10.seconds
#      Rails.cache.write('User.all.cache_time', Time.now) 
#      Rails.cache.write('User.all') { all }
#    else
#      Rails.cache.fetch('User.all') { all }
#    end
  end
  
  def target
    Target.find(site.customer.target_id) unless site.nil? || site.customer.nil? || site.customer.target_id.nil?
  end
  
  def children
    # Users have no children, so far
    nil
  end
  
  def parent
    site
  end

  def parentClass
    Site
  end
  
  def self.parentClass
    Site
  end
  
  def parentSym
    :site
  end
  
  def self.parentSym
    :site
  end

  def self.childClass
    nil
  end
  
  def childClass
    nil
  end
  
  def self.provisioningAction(method, myparent=nil)
    # note: myparent is not needed for users, but the varible is needed for Sites, so for unification, a second argument is needed

    case method
    when :read

      # TODO: test!
#      case myparent
#      when nil? || name.nil?
#        "action=List Users"
#      when is_a?(Site) && ! name.nil?
#        "action=List Users, SiteName=#{myparent.name}"
#      else
#        abort "whatever"
#      end
      "action=List Users" if myparent.nil?
      "action=List Users, SiteName=#{myparent.name}, customerName=#{myparent.customer.name}" unless myparent.nil?
    else
      abort "unknown method for User.provisioningAction(method)"
    end
  end
  
  def self.xmlElements(xml_data)
    trace = true
    
    doc = REXML::Document.new(xml_data)
    
    myelement = doc.root
    
            if trace
              p "xmlElements(xml_data): Before removing test users with numbers 999999999[0-9]"
              myelement.elements.each do |element|
                p element.name
                p element.text
#                element.elements.each do |innerelement|
#                  p innerelement.name
#                  p innerelement.text
#                end
              end      
            end
    
    myelement.elements.each do |element|
      myelement.delete_element(element) if /\A999999999[0-9]/.match( element.text )
    end  

            if trace
              p "xmlElements(xml_data): After removing test users with numbers 999999999[0-9]"
              myelement.elements.each do |element|
                p element.name
                p element.text
#                element.elements.each do |innerelement|
#                  p innerelement.name
#                  p innerelement.text
#                end
              end      
            end   
    
    myelement.elements
  end
  
  def self.find_from_REXML_element(element, mytarget)
    #self.where(name: element.elements["SiteName"].text, customer: mytarget)
    #self.where(name: element.text, target_id: mytarget.id)
    this_extension = element.text.gsub(/\A#{mytarget.countrycode}#{mytarget.areacode}#{mytarget.localofficecode}(.*\Z)/,'\1')
    self.where(extension: this_extension, site: mytarget)
    #User.where(extension: this_extension, site: targetobject.site)
  end
  
  def self.create_from_REXML_element(element, mytarget)
    #self.new(name: element.elements["SiteName"].text, customer: mytarget)
    this_extension = element.text.gsub(/\A#{mytarget.countrycode}#{mytarget.areacode}#{mytarget.localofficecode}(.*\Z)/,'\1')
    self.new(name: element.text, extension: this_extension, site: mytarget)
  end

  def provisioningAction(method)
      
    case method
      when :create
        inputBody ="action=Add User, OSVIP=, XPRIP=, UCIP=, customerName=#{site.customer.name}, SiteName=#{site.name} "
        inputBody += ", X=#{extension}, givenName=#{givenname}, familyName=#{familyname} "
        inputBody += ", assignedEmail=#{email}, imAddress=#{email}"
        return inputBody
      when :destroy
        if site.nil?
          abort "cannot de-provision a user without site"
        end
        
        if site.name.nil?
          abort "cannot de-provision a user with a site with no name"
        end
        
        if site.customer.nil?
          abort "cannot de-provision a user of a site with no customer"
        end
        
        if site.customer.name.nil?
          abort "cannot de-provision a user of a site of a customer with no name"
        end
        return "action=Delete User, X=#{extension}, customerName=#{site.customer.name}, SiteName=#{site.name}"
      when :read
        # read exactly the subscriber number:
        return "action=List Users, X=#{extension}, CC=#{site.countrycode}, AC=#{site.areacode}, LOC=#{site.localofficecode}"
      else
        abort "Unsupported provisioning method: " + method.inspect
    end
  end
 
# TODO: remove after successful test 
#  def de_provision(async=true)
#    @object = self
#    @method = "Delete"
#    @className = @object.class.to_s
#    @classname = @className.downcase
#    @parentClassName = "Site"
#    @parentclassname = @parentClassName.downcase
#    @parentParentClassName = "Customer"
#    @parentparentclassname = @parentParentClassName.downcase
#    
##abort self.inspect
##abort @parentclassname
#    
#    unless @object.site.nil? || @object.site.customer.nil?
##      provisioningAction = "action=#{@method} #{@className}, X=#{@object.extension}, #{@classname}Name=#{@object.name}, #{@parentclassname}Name=#{@object.site.name}, #{@parentparentclassname}Name=#{@object.site.customer.name}" 
#      provisioningAction = "action=#{@method} #{@className}, X=#{@object.extension}, #{@parentclassname}Name=#{@object.site.name}, #{@parentparentclassname}Name=#{@object.site.customer.name}" 
#      provisionNew(provisioningAction, async)
#    else
#      abort "cannot de-provision a user without specified site and customer"
#    end
#  end

# TODO: remove after successful test 
#  def provisionOld(inputBody, async=true)
#
#    @user = User.find(id)
#    @site = Site.find(site_id)
#    @customer = site.customer
#      
#    unless @customer.nil? || @customer.target_id.nil?
#      @target = Target.find(@customer.target_id)
#      actionAppend = @target.configuration.gsub(/\n/, ', ')
#      actionAppend = actionAppend.gsub(/\r/, '')
#    end
#    
#    inputBody = inputBody + ', ' + actionAppend unless actionAppend.nil?
#
#    @provisioning = Provisioning.new(action: inputBody, user: @user, site: @site, customer: @customer)
#    
#    if @provisioning.save
#       #@provisioning.createdelayedjob
#       if async == true
#         @provisioning.deliverasynchronously
#       else
#         @provisioning.deliver
#       end
#       # success
#       return 0
#    else
#      @provisioning.errors.full_messages.each do |message|
#        abort 'provisioning error: ' + message.to_s
#      end
#    end 
#  end # def

  #
  # MAIN
  #
  belongs_to :site
  
  validates :site_id, presence: true
  
  validates :name,  #presence: true,
                    #length: { in: 3..20  }
                    length: { maximum: 20  }
  #validates :extension, unique_on_target: {:scope => [:countrycode, :areacode, :localofficecode]}
  validates :extension, #presence: true,
                    uniqueness: { scope: :site, message: "is already taken for this #{:site}" }
                    #length: { is: @site.extensionlength.to_i  }
  #validates :givenname,  presence: true
  validates_format_of :givenname, :familyname, :with => /\A[\p{L}0-9\-]+\Z/, message: "must consist of letters (unicode allowed) and/or numbers and/or hyphens (-)"
  #validates :familyname,  presence: true
  #validates_format_of :familyname, :with => /\A[\p{L}0-9\-]+\Z/, message: "must consist of letters (unicode allowed) and numbers"
  #validates :email,  presence: true
  #validates_format_of :email, :with => /\A[_A-Za-z0-9-\+]+(\.[_A-Za-z0-9-]+)*@[A-Za-z0-9-]+(\.[A-Za-z0-9]+)*(\.[A-Za-z]{2,})\Z/, message: "must be a valid email address, e.g. name@company.com"
  validates_format_of :email, :with => /\A[_A-Za-z0-9\-\+]+(\.[_A-Za-z0-9\-]+)*@[A-Za-z0-9\-]+(\.[A-Za-z0-9]+)*(\.[A-Za-z]{2,})\Z/, message: "must be a valid email address, e.g. name@company.com"
  validates_with Validate_ExtensionLength, Validate_DisplayLength

end
