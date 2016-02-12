class ProvisioningobjectsController < ApplicationController
  before_action :set_provisioningobject, only: [:show, :edit, :update, :destroy, :deprovision, :provision]
  before_action :set_parent, only: [:new, :create, :show, :edit, :update, :destroy, :deprovision, :provision]
  
  #before_action :set_provisioningobjects, only: [:index] #, :removeAll]
  before_action :set_async_mode, :remove_target_id_if_needed 


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


  # e.g. GET /customers
  # e.g. GET /customers.json
  def index
    # return all items, but may be filtered. E.g. /targets/3/sites will return only sites of the specific target chosen.
    
    # needed for page refresh:
    #@params = params
    # however, this leads to DEPRECATED warning and failed tests. Therefore we need to convert the params (
    #@params = {"per_page"=>"all", "controller"=>"customers", "action"=>"index", "target_id"=>nil}
    @params = {}
    params.each do |key,value|
      # see also: http://stackoverflow.com/questions/2004491/convert-string-to-symbol-able-in-ruby
      @params[key.parameterize.underscore.to_sym] = value
    end
    # result: something like @params = {per_page: params[:per_page], controller: params[:controller], action: params[:action], target_id: params[:target_id]}
		#abort @params.class.name
		#abort @params.inspect

    # find the closets relative upwards that is specified
    # e.g. if called with GET /targets/3/sites, the closest upward relative is Target with id==3

    # init
          #abort params[:target_id].inspect
    per_page = params[:per_page]
    per_page = 10 if per_page.nil?
    per_page = 1000000 if per_page == 'all'
          #abort per_page.inspect

    ancestor = nil
    ancestorClass = myClass
    while !ancestorClass.parentClass.nil?
      ancestorClass = ancestorClass.parentClass

      # e.g. :target_id
      ancestor_id_sym = "#{ancestorClass.name.downcase}_id".to_sym 
  
      # e.g. @parent = Target.find(params[:target_id])
      ancestor = ancestorClass.find(params[ancestor_id_sym]) if params[ancestor_id_sym]
      break unless ancestor.nil? # do not stop, if ancestor was not yet found
    end

    # now ancestor is either nil, or points to the closes relative upwards, e.g. Target.find(3)
   
    # default ancestor:
    ancestor = Target.find(params[:target_id]) if ancestor.nil? && !params[:target_id].nil? && params[:target_id] != 'none'
    my_array_object = myClass.all_in(ancestor)
          #abort my_array_object.inspect
          #abort my_array_object.map!(&:target).inspect # (ruby1.9 or Ruby 1.8.7).inspect
    @provisioningobjects = Kaminari.paginate_array(my_array_object).page(params[:page]).per(per_page)
		      #abort @provisioningobjects.inspect

    # e.g. @customers = @provisioningobjects 
    # TODO: remove the next line, afer all views have been changed to wirk with @provisioningobjects instead of @targets, @customers, @sites or @users
    instance_variable_set("@#{myClass.name.downcase.pluralize}", @provisioningobjects)
		      #abort @sites.inspect
		      #abort @provisioningobjects.inspect

    # set filteredvia variable that can be used in the views to show, how the data was filtered
    @filteredvia = ancestor unless ancestor.nil?
  end

  # GET /customers/new  
  def new
        #abort params.inspect
    @provisioningobject = myClass.new
    
    @provisioningtime = params[:provisioningtime]
  end
  
  # POST /customers
  # POST /customers.json
  def create
          #abort params.inspect
    params.delete :target_id if params[:target_id].to_s == ""          
          #abort params.inspect

    respond_to do |format|         
      if @provisioningobject.save        
        if @provisioningobject.provisioningtime == Provisioningobject::PROVISIONINGTIME_IMMEDIATE
          if @provisioningobject.provision(:create, @async)
            if @async 
              @notice = "#{@provisioningobject.class.name} is being created (provisioning running in the background)."
            else
              @notice = "#{@provisioningobject.class.name} is provisioned."
            end
          else # if @provisioningobject.provision(:create, @async)
            @notice = "#{@provisioningobject.class.name} could not be provisioned"
          end
        else # if @provisioningobject.provisioningtime == Provisioningobject::PROVISIONINGTIME_IMMEDIATE
          # only save, do not provision:
          @notice = "#{@provisioningobject.class.name} is created and can be provisioned ad hoc."
        end
          
        format.html { redirect_to @provisioningobject, notice: @notice }
        format.json { render :show, status: :created, location: @provisioningobject } 
      else # if @provisioningobject.save
        format.html { render :new  }                   
        format.json { render json: @provisioningobject.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /customers/1
  # PATCH/PUT /customers/1.json
  def update
              #abort params.inspect
    params.delete :target_id if params[:target_id].to_s == "" 
          #abort params.inspect

    respond_to do |format|         
      if !@provisioningobject.provisioned? && @provisioningobject.update(provisioningobject_params)       
        if @provisioningobject.provisioningtime == Provisioningobject::PROVISIONINGTIME_IMMEDIATE
          if @provisioningobject.provision(:create, @async)
            if @async 
              @notice = "#{@provisioningobject.class.name} is being created (provisioning running in the background)."
            else
              @notice = "#{@provisioningobject.class.name} is provisioned."
            end
          else # if @provisioningobject.provision(:create, @async)
            @notice = "#{@provisioningobject.class.name} could not be provisioned"
          end
        else # if @provisioningobject.provisioningtime == Provisioningobject::PROVISIONINGTIME_IMMEDIATE
          # only save, do not provision:
          @notice = "#{@provisioningobject.class.name} is created and can be provisioned ad hoc."
          @provisioningobject.update_attribute(:status, "not provisioned")
        end
          
        format.html { redirect_to @provisioningobject, notice: @notice }
        format.json { render :show, status: :created, location: @provisioningobject } 
      else # if @provisioningobject.save
        flash[:error] = "#{@provisioningobject.class.name} could not be updated (already provisioned?)"
        format.html { render :edit  }                   
        format.json { render json: @provisioningobject.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def updateOld
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
      
      provisioningobject_provisionings_path = send("#{myClass.name.downcase}_provisionings_path", @provisioningobject)
      redirectPath = provisioningobject_provisionings_path

    elsif @provisioningobject.provisioned?
      if @async
        flash[:notice] = "#{className} #{@provisioningobject.name} is being de-provisioned."
      else
        flash[:notice] = "#{className} #{@provisioningobject.name} is de-provisioned."
      end
      
      redirectPath = :back
      
      @provisioningobject.provision(:destroy, @async)
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
        @provisioningobject.provision(:destroy, @async)
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
      
       # remove all entries with one SQL command per level (better performance than myClass.destroy_all):
       myClass.recursiveDeleteAll
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

    # individual settings are done e.g. in customers_controller.rb#deprovision
    @partentTargets = nil if @partentTargets.nil? 

    @async_all = true if @async && @async_all.nil?
    @async_individual = true if @async && @async_individual.nil?

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
    
            #abort ENV["WEBPORTAL_SYNCHRONIZE_ALL_ABORT_ON_ABORT"].inspect
            #abort (!@async_all).inspect
    if ENV["WEBPORTAL_SYNCHRONIZE_ALL_ABORT_ON_ABORT"] == "true" || @async_all
      # in case of asynchronous synchronization, we always allow to abort, since this will trigger delayed_job to retry
      # in case of synchronous synchronization, we allow to abort only, if WEBPORTAL_SYNCHRONIZE_ALL_ABORT_ON_ABORT is set to "true"
      @abortOnAbort = true
    else
      # in case of synchronous synchronization and WEBPORTAL_SYNCHRONIZE_ALL_ABORT_ON_ABORT is not set to "true", we proceed even after an abort (e.g. if a target is unreachable, other targets will still be synchronized)
      @abortOnAbort = false
    end
            #abort @abortOnAbort.inspect

    # note: @id needs to be set in the individual child classes (e.g. Customer/Site/User)
    if @id.nil?
      #
      # PATCH /customers/synchronize
      #
      # if @id is nil, we assume that all Customers/Sites/Users needs to be synchronized:

      @myClass.synchronizeAll(@partentTargets, @async_all,  @recursive_all, @abortOnAbort)
      redirect_to :back, notice: "All #{@myClass.name.pluralize} are #{being_all}synchronized."
    else
      #
      # PATCH /customers/1/synchronize
      #
      # if @id is not nil, an individual Customer/Site/User with id==@id is synchronized:
            
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
        if @async
          flashtext = "#{@provisioningobject.class.name} #{@provisioningobject.name} is being provisioned to target system(s)"
        else
          flashtext = "#{@provisioningobject.class.name} #{@provisioningobject.name} is provisioned to target system(s)"            
        end
        format.html { redirect_to :back, notice: flashtext  }
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
 
  def provisioningobject
    myClass.find(params[:id])
  end

  def set_provisioningobjects
    @provisioningobjects = provisioningobjects
  end

  def set_provisioningobject
    @provisioningobject = provisioningobject
  end
  
  def set_parent
    
        #abort @parent.inspect
    this_sym = "#{myClass.name.downcase}".to_sym
    parent_id_sym = "#{myClass.parentClass.name.downcase}_id".to_sym unless myClass.parentClass.nil?
        #abort parent_id_sym.inspect
        #abort this_sym.inspect
        #abort params[this_sym][parent_id_sym].inspect
        #abort params[parent_id_sym].inspect
        #abort params[:site][:customer_id].inspect
        #abort myClass.parentClass.find(params[this_sym][parent_id_sym]).inspect

        #abort params[this_sym].nil?.inspect
        #abort params[this_sym][parent_id_sym].to_s
        #abort (!params[this_sym].nil? && params[this_sym][parent_id_sym].to_s != "").inspect
    if(!params[parent_id_sym].nil?) # this is the format needed for all controllers but #create (e.g. #new in case of /customers/5/sites/new or /sites/new?customer_id=5)
      @parent = myClass.parentClass.find(params[parent_id_sym])
    elsif( params[this_sym].is_a?(Hash) && params[this_sym][parent_id_sym].to_s != "")  # this is the format needed for #create
            #abort this_sym.inspect
            #abort params[this_sym].inspect
            #abort (params[this_sym][parent_id_sym].to_s != "").inspect
            #abort params.inspect
            #abort params[this_sym][parent_id_sym].inspect
      if myClass.parentClass.exists? id: params[this_sym][parent_id_sym]
        @parent = myClass.parentClass.find(params[this_sym][parent_id_sym])
      else
        @parent = nil
      end
      
    elsif !params[:id].nil?
      # read parent from existing object
      @parent = myClass.find(params[:id]).parent
    end
        #abort @parent.inspect
  end
  
  def set_async_mode
    if SystemSetting.webportal_async_mode
      @async = true
    else 
      @async = false  
    end
  end
  def remove_target_id_if_needed
    def is_number?(mystring)
      true if Float(mystring) rescue false
    end
    params[:target_id] = nil unless is_number?(params[:target_id])
  end    

end
