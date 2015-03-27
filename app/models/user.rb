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
    
    if record.givenname.length.to_i + record.givenname.length.to_i > 29
      record.errors[:givenname] << "too long. Sum length of #{:givenname.to_s} and #{:familyname.to_s} must not exceed 29"      
      #record.errors[:familyname] << "too long. Sum length of #{:givenname.to_s} and #{:familyname.to_s} must not exceed 29"      
    end
       
  end # def
end

class User < Provisioningobject #< ActiveRecord::Base
  
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

  def provisioningAction(method)
    
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
    
    case method
      when :create
        inputBody ="action=Add User, OSVIP=, XPRIP=, UCIP=, customerName=#{site.customer.name}, SiteName=#{site.name} "
        inputBody += ", X=#{extension}, givenName=#{givenname}, familyName=#{familyname} "
        inputBody += ", assignedEmail=#{email}, imAddress=#{email}"
        return inputBody
      when :destroy
        return "action=Delete User, X=#{extension}, customerName=#{site.customer.name}, SiteName=#{site.name}"
      when :read
        return "action=List Users"
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
  
  validates :site, presence: true
  
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
