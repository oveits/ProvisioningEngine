class UsersController < ProvisioningobjectsController #ApplicationController

  # GET /users
  # GET /users.json
  def index
    super
  end

  def indexOld
    
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
    # @partentTargets = nil means all parent targets for the synchronizeAll function
    @partentTargets = nil;
    @myClass = User
    @recursive_all = false
    @recursive_individual = true
    @id = params[:id]
                #@partentTargets = Target.where(name: "CSL9DEV (OSV V8R0 Development Machine)")
                                #abort @partentTargets.inspect
                # for testing:
                #nonexistentcustomer = Customer.where(name: "ExampleCustomerV8") #, target_id: targets.last.id)
                #nonexistentcustomer.last.destroy! unless nonexistentcustomer.count == 0
                #abort "dehgosdöhgliöodsf"
    super
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
  

  # PATCH /users/1/deprovision
  # PATCH /users/1/deprovision.json
  def deprovision
    @object = User.find(params[:id])
    @className = @object.class.to_s
    @classname = @className.downcase

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
  end # def destroy

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_provisioningobject
      @user = User.find(params[:id])
      @provisioningobject = @user
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:name, :site_id, :extension, :givenname, :familyname, :email, :provisioningtime)
    end
end
