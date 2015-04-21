class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  # GET /users
  # GET /users.json
  def index
    
    if(params[:site_id])
      @site = Site.find(params[:site_id])
      @users = User.where(site: params[:site_id])
    elsif(params[:customer_id])
      @customer = Customer.find(params[:customer_id])
      @users = User.where(customer: params[:customer_id])      
    else
      @users = User.all
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
    
    if(params[:site_id])
      @site = Site.find(params[:site_id])
    end
    
    ro = 'readonly'; rw = 'readwrite'
    @myparams = {"id"=>'none', "name"=>'none', "site_id"=>'showCustomerDropDown', "created_at"=>'none', "updated_at"=>'none', "status"=>'none', "email"=>rw, "extension"=>rw, "givenname"=>rw, "familyname"=>rw }

  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def createOld
    @user = User.new(user_params)
    
    ro = 'readonly'; rw = 'readwrite'
    @myparams = {"id"=>'none', "name"=>rw, "customer_id"=>'showCustomerDropDown', "created_at"=>'none', "updated_at"=>'none', "status"=>'none', "sitecode"=>rw, "countrycode"=>rw, "areacode"=>rw, "localofficecode"=>rw, "extensionlength"=>rw, "mainextension"=>rw, "gatewayIP"=>rw }


    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User is being created.' }
        format.json { render :show, status: :created, location: @user }
        
        @site = @user.site
        @customer = @site.customer        
        inputBody ="action=Add User, OSVIP=, XPRIP=, UCIP=, customerName=#{@customer.name}, SiteName=#{@site.name} "
        inputBody += ", X=#{user_params[:extension]}, givenName=#{user_params[:givenname]}, familyName=#{user_params[:familyname]} "
        inputBody += ", assignedEmail=#{user_params[:email]}, imAddress=#{user_params[:email]}"
        @user.provision(inputBody)
        
#        if !@site.nil?
#          @customer = @site.customer
#        end
#        
#        inputBody = ""
#        #inputBody = "offlineMode=offlineMode, "
#        inputBody +="action=Add User, OSVIP=, XPRIP=, UCIP=, customerName=#{@customer.name}, SiteName=#{@site.name} "
#        inputBody += ", X=#{user_params[:extension]}, givenName=#{user_params[:givenname]}, familyName=#{user_params[:familyname]} "
#        inputBody += ", assignedEmail=#{user_params[:email]}, imAddress=#{user_params[:email]}"
#
#        @provisioning = Provisioning.new(action: inputBody, site: @site, customer: @site.customer)
#        
#        if @provisioning.save
#          @provisioning.createdelayedjob
#        else
#          @provisioning.errors.full_messages.each do |message|
#            abort 'error in user.create: provisioning error: ' + message.to_s
#          end
#        end
     else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def create 
    ro = 'readonly'; rw = 'readwrite'
    @myparams = {"id"=>'none', "name"=>rw, "site_id"=>'showCustomerDropDown', "created_at"=>'none', "updated_at"=>'none', "status"=>'none', "email"=>rw, "extension"=>rw, "givenname"=>rw, "familyname"=>rw }

    @object = User.new(user_params)
    @user = @object
    @className = @object.class.to_s
    
    respond_to do |format|         
      if @object.save
        if @object.provisioningtime == Provisioningobject::PROVISIONINGTIME_IMMEDIATE && @object.provision(:create)
          @notice = "#{@className} is being created (provisioning running in the background)."
        else
          @notice = "#{@className} is created and can be provisioned ad hoc."
        end
        format.html { redirect_to @object, notice: @notice }
        format.json { render :show, status: :created, location: @object }

      else
        format.html { render :new  }                   
        format.json { render json: @object.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # PATCH /users/1/synchronize
  # -> find single user on target and synchronize the data to the local database
  # PATCH /users/synchronize
  # -> find all users of all known sites (i.e. sites found in the local database), and synchronize them to the local database
  def synchronize

    if params[:id].nil?
      # PATCH /users/synchronize
      targets = nil
      async = true
      recursive = false # recursive not yet supported
      
      User.synchronizeAll(targets, async, recursive)
      redirect_to :back, notice: "All Users are being synchronized."

    else
      # PATCH /users/1/synchronize
      @object = User.find(params[:id])
      updateDB = UpdateDB.new
      @object.update_attributes!(:status => 'synchronization in progress')
      returnBody = updateDB.delay.perform(@object)
      redirect_to :back, notice: "#{@object.class.name} #{@object.name} is being synchronized."
    end
  end

  def provision
    @object = User.find(params[:id])
    respond_to do |format|
      if @object.provision(:create)
        format.html { redirect_to :back, notice: "#{@object.class.name} #{@object.name} is being provisioned to target system(s)" }
        format.json { render :show, status: :ok, location: @object }
      else
        format.html { redirect_to :back, notice: "#{@object.class.name} #{@object.name} could not be provisioned to target system(s)" }
        format.json { render json: @object.errors, status: :unprocessable_entity }
      end # if
    end # do
  end # def provision

  def provisionOld
    @user = User.find(params[:id])
    @site = @user.site
    @customer = @site.customer
    inputBody ="action=Add User, OSVIP=, XPRIP=, UCIP=, customerName=#{@customer.name}, SiteName=#{@site.name} "
    inputBody += ", X=#{user_params[:extension]}, givenName=#{user_params[:givenname]}, familyName=#{user_params[:familyname]} "
    inputBody += ", assignedEmail=#{user_params[:email]}, imAddress=#{user_params[:email]}"
    
    respond_to do |format|
      if @user.provision(inputBody)
        @provisionings = Provisioning.where(user: @user)
        format.html { redirect_to @user, notice: "Site #{@user.name} is being provisioned to target system(s)" }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { redirect_to @user, notice: "Site #{@user.name} could not be provisioned to target system(s)" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end # if
    end # do  
  end # def provision

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update   
    ro = 'readonly'; rw = 'readwrite'
    @myparams = {"id"=>ro, "name"=>rw, "site_id"=>ro, "created_at"=>ro, "updated_at"=>ro, "status"=>ro, "email"=>rw, "extension"=>rw, "givenname"=>rw, "familyname"=>rw }
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: "User #{@user.name} successfully updated in the database, but provisioning of target systems is not yet supported." }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroyOrig
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  def destroyOld
    @user = User.find(params[:id])
    @site = @user.site
    @customer = @site.customer
    inputBody ="action=Delete User, X=#{@user.extension}, customerName=#{@customer.name}, SiteName=#{@site.name}"
    
    if @user.provision(inputBody)
      respond_to do |format|
        format.html { redirect_to users_path, notice: "User #{@user.name} is being destroyed (background process)." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to user_provisionings_path(@user), notice: "User #{@user.name} cannot be deleted, since there are active provisioning tasks running." }
        format.json { head :no_content }
      end
    end        
  end
  

  # PATCH /users/1/deprovision
  # PATCH /users/1/deprovision.json
  def deprovision
    @object = User.find(params[:id])
    @className = @object.class.to_s
    @classname = @className.downcase
    async = true

    if @object.activeJob?
      flash[:error] = "#{@className} #{@object.name} cannot be de-provisioned: has active jobs running: see below."
      redirectPath = customer_provisionings_path(@object, active: true )

#     not tested, therefore commented out:
#      respond_to do |format|
#        format.html { redirect_to redirectPath }
#        format.json { render json: flash[:error], status: :locked }
#      end

    elsif @object.provisioned?
      flash[:notice] = "#{@className} #{@object.name} is being de-provisioned."
      redirectPath = :back

      @object.provision(:destroy)
    else
      flash[:error] = "#{@className} #{@object.name} cannot be destroyed: is not provisioned."
      redirectPath = :back

    end

    respond_to do |format|
      format.html { redirect_to redirectPath }
      format.json { head :no_content }
    end

  end
  def destroy
    @object = @user
    @method = "Delete"
    @className = @object.class.to_s
    @classname = @className.downcase
    async = true
      
    if @object.activeJob?
      flash[:error] = "#{@className} #{@object.name} cannot be destroyed: has active jobs running: see below."
      redirectPath = user_provisionings_path(@object, active: true )
    elsif @object.provisioned?
      flash[:notice] = "#{@className} #{@object.name} is being de-provisioned."
      redirectPath = :back
      
      @object.provision(:destroy)
    else
      flash[:success] = "#{@className} #{@object.name} deleted."
      redirectPath = users_url
      
      @object.destroy!
    end 
    
    respond_to do |format|
      format.html { redirect_to redirectPath }
      format.json { head :no_content }
    end  
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:name, :site_id, :extension, :givenname, :familyname, :email, :provisioningtime)
    end
end
