class Validate_ExtensionLength < ActiveModel::Validator
  def validate(record)
    
    @site = Site.find(record.site)
    
    if record.extension.length.to_i != @site.extensionlength.to_i
      record.errors[:extension] << "length must be #{@site.extensionlength.to_s}" # + " but is #{record.extension.length.to_s}"      
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

class User < ActiveRecord::Base

  def provision(inputBody)
    @user = User.find(id)
    @site = Site.find(site_id)
    @customer = site.customer
      
    unless @customer.nil? || @customer.target_id.nil?
      @target = Target.find(@customer.target_id)
      actionAppend = @target.configuration.gsub(/\n/, ', ')
      actionAppend = actionAppend.gsub(/\r/, '')
    end
    
    inputBody = inputBody + ', ' + actionAppend unless actionAppend.nil?

    @provisioning = Provisioning.new(action: inputBody, user: @user, site: @site, customer: @customer)
    
    if @provisioning.save
       #@provisioning.createdelayedjob
       @provisioning.deliverasynchronously
       # success
       return 0
    else
      @provisioning.errors.full_messages.each do |message|
        abort 'provisioning error: ' + message.to_s
      end
    end 
  end # def

  #
  # MAIN
  #
  belongs_to :site
  
  validates :name,  #presence: true,
                    length: { in: 3..20  }
  validates :extension, #presence: true,
                    uniqueness: { scope: :site, message: "is already taken for this #{:site}" }
                    #length: { is: @site.extensionlength.to_i  }
  #validates :givenname,  presence: true
  validates_format_of :givenname, :with => /\A[\p{L}0-9]+\Z/, message: "must consist of letters (unicode allowed) and numbers"
  #validates :familyname,  presence: true
  validates_format_of :familyname, :with => /\A[\p{L}0-9]+\Z/, message: "must consist of letters (unicode allowed) and numbers"
  #validates :email,  presence: true
  #validates_format_of :email, :with => /\A[_A-Za-z0-9-\+]+(\.[_A-Za-z0-9-]+)*@[A-Za-z0-9-]+(\.[A-Za-z0-9]+)*(\.[A-Za-z]{2,})\Z/, message: "must be a valid email address, e.g. name@company.com"
  validates_format_of :email, :with => /\A[_A-Za-z0-9\-\+]+(\.[_A-Za-z0-9\-]+)*@[A-Za-z0-9\-]+(\.[A-Za-z0-9]+)*(\.[A-Za-z]{2,})\Z/, message: "must be a valid email address, e.g. name@company.com"
  validates_with Validate_ExtensionLength, Validate_DisplayLength
end
