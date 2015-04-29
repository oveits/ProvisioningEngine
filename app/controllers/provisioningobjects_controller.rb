class ProvisioningobjectsController < ApplicationController
  before_action :set_provisioningobject, only: [:show, :edit, :update, :destroy, :deprovision, :provision]
  before_action :set_provisioningobjects, only: [:index] #, :removeAll]
  before_action :set_async_mode


  def ro
    'readonly'
  end

  def rw
    'readwrite'
  end

# from http://blog.laaz.org/tech/2012/12/27/rails-redirect_back_or_default/
def store_location
  session[:return_to] = if request.get?
    request.request_uri
  else
    request.referer
  end
end

def redirect_back_or_default(default = root_url, options)
  redirect_to(session.delete(:return_to) || request.referer || default, options)
end


  # GET /customers
  # GET /customers.json
  def index
    # :customer_id
    this_id_sym = "#{myClass.name.downcase}_id".to_sym
    
    # :target_id
    parent_id_sym = "#{myClass.parentClass.name.downcase}_id".to_sym
        
    if(params[parent_id_sym])
      # @parent = Target.find(params[:target_id])
      @parent = myClass.parentClass.find(params[parent_id_sym])
      
      # @target = @parent
      instance_variable_set("@#{myClass.parentClass.name.downcase}", @parent)
      
      # @these = Customer.where(target_id: params[:target_id])
      @provisioningobjects = myClass.where(target_id: params[parent_id_sym])
              #abort @these.inspect
    else
      # @these = Customer.all
      @provisioningobjects = myClass.all      
    end
    
    # @customers = @these
    instance_variable_set("@#{myClass.name.downcase.pluralize}", @provisioningobjects)
    
    #abort @customers.inspect
  end
  
  # POST /customers
  # POST /customers.json
  def create
    # in the individual object's controller, the following needs to be done (here the example of a customers_controller:
    ## TODO: the next 2 lines are still needed. Is this the right place to control, whether a param is ro or rw?
    #@myparams = {"id"=>'ro', "name"=>rw, "created_at"=>'', "language"=>'showLanguageDropDown', "updated_at"=>'', "status"=>'', "target_id"=>'showTargetDropDown'}
#
    #@provisioningobject = Customer.new(customer_params)
    #@customer = @provisioningobject
    #@className = @provisioningobject.class.to_s
#abort @provisioningobject.inspect

    respond_to do |format|         
      if @provisioningobject.save
        if @provisioningobject.provisioningtime == Provisioningobject::PROVISIONINGTIME_IMMEDIATE && @provisioningobject.provision(:create)
          @notice = "#{@provisioningobject.class.name} is being created (provisioning running in the background)."
        else
          @notice = "#{@provisioningobject.class.name} is created and can be provisioned ad hoc."
        end
        format.html { redirect_to @provisioningobject, notice: @notice }
        format.json { render :show, status: :created, location: @provisioningobject } 
      else
        format.html { render :new  }                   
        format.json { render json: @provisioningobject.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /customers/1
  # PATCH/PUT /customers/1.json
  def update
    # individual settings are done e.g. in customers_controller.rb#update
    respond_to do |format|
      if @provisioningobject.update(provisioningobject_params)
        format.html { redirect_to @provisioningobject, notice: "#{@provisioningobject.class.name} was successfully updated." }
        format.json { render :show, status: :ok, location: @provisioningobject }
        format.js
      else
        format.html { render :edit }
        format.json { render json: @provisioningobject.errors, status: :unprocessable_entity }
        format.js
      end
    end
  end

  # PATCH /customers/1/deprovision
  # PATCH /customers/1/deprovision.json
  def deprovision
    # individual settings are done e.g. in customers_controller.rb#deprovision

    # default setting:
    #@async = true if @async.nil?
    className = @provisioningobject.class.name

    if @provisioningobject.activeJob?
      flash[:error] = "#{className} #{@provisioningobject.name} cannot be de-provisioned: has active jobs running: see below."
      redirectPath = provisioningobject_provisionings_path

    elsif @provisioningobject.provisioned?
      flash[:notice] = "#{className} #{@provisioningobject.name} is being de-provisioned."
      redirectPath = :back
      
      @provisioningobject.provision(:destroy)
    else
      flash[:error] = "#{className} #{@provisioningobject.name} cannot be destroyed: is not provisioned."
      redirectPath = :back
      
    end 
    
    respond_to do |format|
      format.html { redirect_to redirectPath }
      format.json { head :no_content }
    end

  end

  # DELETE /customers/1
  # DELETE /customers/1.json
  def destroy(deprovision)
    # individual settings are done e.g. in customers_controller.rb#deprovision
    
    if @provisioningobject.provisioned?
      if deprovision
        @provisioningobject.provision(:destroy)
        flash[:success] = "#{@provisioningobject.class.name} #{@provisioningobject.name} is being de-provisioned."
        #redirectPath = :back
      else
        flash[:alert] = "#{@provisioningobject.class.name} #{@provisioningobject.name} is deleted from the database, but not from the target system."
        @provisioningobject.destroy!
      end
      
    else
      flash[:success] = "#{@provisioningobject.class.name} #{@provisioningobject.name} deleted."
      @provisioningobject.destroy!
      
    end 

    
    respond_to do |format|
      format.html { redirect_to @redirectPath }
      format.json { head :no_content }
    end

   # from http://tools.ietf.org/html/rfc7231#section-4.3:
   #If a DELETE method is successfully applied, the origin server SHOULD
   #send a 202 (Accepted) status code if the action will likely succeed
   #but has not yet been enacted, a 204 (No Content) status code if the
   #action has been enacted and no further information is to be supplied,
   #or a 200 (OK) status code if the action has been enacted and the
   #response message includes a representation describing the status.

  end

  if ENV["WEBPORTAL_REMOVEALL_LINK_VISIBLE"] == "true"
  #  removeAll_customers DELETE   /customers/removeAll
  def removeAll
    # removes all entities in the database
    # individual settings are done e.g. in customers_controller.rb#removeAll

    		#abort provisioningobjects.inspect
    @redirectPath = :back if @redirectPath.nil?
    if provisioningobjects.count > 0
      provisioningobjects.each do |provisioningobject| 
		#abort provisioningobject.inspect
        provisioningobject.destroy!
      end
      flash[:notice] = "All #{myClass.name.pluralize} have been deleted."
    else 
      flash[:notice] = "No #{myClass.name} found; nothing to do."
    end
    redirect_to @redirectPath

  end
  end

  # PATCH /customers/1/synchronize
  # -> find single customer on target and synchronize the data to the local database
  # PATCH /customers/synchronize
  # -> find all customers of all known target (i.e. targets found in the local database), and synchronize them to the local database
  def synchronize

#abort @async.inspect
    # individual settings are done e.g. in customers_controller.rb#deprovision
    @partentTargets = nil if @partentTargets.nil? 

    @async_all = true if @async && @async_all.nil?
    @async_individual = true if @async && @async_individual.nil?
		#abort @async_all.inspect

    @recursive_all = false if @recursive_all.nil?
    @recursive_individual = true if @recursive_individual.nil?

    if @async_all
      being_all = "being "
    else
      being_all = ""
    end

    if @async_individual
      being_individual = "being "
    else
      being_individual = ""
    end


    #@id = params[:id]
    		#abort @id.inspect if @id != params[:id]

    if @id.nil?
      # PATCH /customers/synchronize
      # synchronizeAll:
      #Customer.synchronizeAll(@partentTargets, @async_all,  @recursive_all)
      @myClass.synchronizeAll(@partentTargets, @async_all,  @recursive_all)
      redirect_to :back, notice: "All #{@myClass.name.pluralize} are #{being_all}synchronized."
    else
      # PATCH /customers/1/synchronize
      @provisioningobject = @myClass.find(@id)
      @provisioningobject.synchronize(@async_individual, @recursive_individual)
      redirect_to :back, notice: "#{@provisioningobject.class.name} #{@provisioningobject.name} is #{being_individual}synchronized."
    end
  end

  # PATCH	/customers/1/provision
  def provision
    # individual settings are done e.g. in customers_controller.rb#provision

    respond_to do |format|
      if @provisioningobject.provision(:create, @async)
        format.html { redirect_to :back, notice: "#{@provisioningobject.class.name} #{@provisioningobject.name} is being provisioned to target system(s)" }
        format.json { render :show, status: :ok, location: @provisioningobject }
      else
        format.html { redirect_to :back, notice: "#{@provisioningobject.class.name} #{@provisioningobject.name} could not be provisioned to target system(s)" }
        format.json { render json: @provisioningobject.errors, status: :unprocessable_entity }
      end # if
    end # do
  end # def provision

private
  def myClass
    # returns "User" or "Site" or "Customer" (String)
		#abort controller_name.classify
    controller_name.classify.constantize
  end

  def provisioningobjects
    # returns e.g. User.all
    myClass.all
  end

  def set_provisioningobjects
    @provisioningobjects = provisioningobjects
  end
  
  def set_async_mode
    if ENV["WEBPORTAL_ASYNC_MODE"] == "true"
      @async = true
    else 
      @async = false  
    end
  end
    

end
