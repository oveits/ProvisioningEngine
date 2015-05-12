class ProvisioningobjectsController < ApplicationController
  before_action :set_provisioningobject, only: [:show, :edit, :update, :destroy, :deprovision, :provision]
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
    @params = params
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
    my_array_object = myClass.all_in(ancestor, false)
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

  def indexOld
    unless @ancestor.nil?

        # if ancestor is the grandpa or grandgrandpa..., no such column is availsble. Instead, we read all items form the database and do the filtering afterwards:
        all_children_of_ancestor = [@ancestor]
        currentClass = @ancestor.class
        while currentClass != myClass
          all_children_of_ancestor = @ancestor.children
          currentClass = currentClass.childClass
        end # if @ancestor.class == myClass.parentClass
        # now all_children_of_ancestor is a list or parents, that matches the anchestor
        parent_list = all_children_of_ancestor

#abort myClass.where(parent_id_sym => 579).map {|i| i }.inspect
#abort myClass.all.inspect
#abort parent_list.inspect

        @provisioningobjects = []
        parent_list.each do |parent|
#abort ([].concat []).inspect
          provisioningobjects_of_this_parent = myClass.where(parent_id_sym => parent.id).map {|i| i } 
#abort provisioningobjects_of_this_parent.inspect if provisioningobjects_of_this_parent.count > 0
#abort provisioningobjects_of_this_parent.class.name if provisioningobjects_of_this_parent.count > 0
          @provisioningobjects = @provisioningobjects.concat provisioningobjects_of_this_parent if provisioningobjects_of_this_parent.count > 0
#abort @provisioningobjects.inspect if provisioningobjects_of_this_parent.count > 0
#abort provisioningobjects_of_this_parent.inspect

abort @provisioningobjects.inspect
abort all_children_of_ancestor.inspect
abort currentClass.inspect
        all_provisioningobjects = myClass.all.map {|i| i }
abort all_provisioningobjects.first.send("target").inspect
abort all_provisioningobjects.inspect
        @provisioningobjects = all_provisioningobjects.select { |i|  i.send(ancestorMethodString)  }
      end # else # @ancestor.class == myClass.parentClass
      # ancestor not found, e.g. in case the link was called as GET /customers/

      # e.g. @target = @parent
# not needed?
#      instance_variable_set("@#{ancestorClass.name.downcase}", @ancestor)
      
      # e.g. @these = Customer.where(target_id: params[:target_id])
      #@provisioningobjects = myClass.where(ancestor_id_sym => params[ancestor_id_sym])
abort all_provisioningobjects.where(ancestor_id_sym => params[ancestor_id_sym]).inspect
      @provisioningobjects = myClass.where(ancestor_id_sym => params[ancestor_id_sym])

    else # @parent == nil; i.e. the index waa called plainly with path GET /customers/ (as an example)

      # @these = Customer.all
      @provisioningobjects = myClass.all.map {|i| i }      

    end
    
    # e.g. @customers = @these
    instance_variable_set("@#{myClass.name.downcase.pluralize}", @provisioningobjects)

    # at this point, both, @provisioningobjects and @customers are set to the ActiveRecords relation (list)
    
    		#abort @customers.inspect
    		abort @provisioningobjects.inspect
  end

  # GET /customers/new  
  def new
    @provisioningobject = myClass.new
    
    parent_id_sym = "#{myClass.parentClass.name.downcase}_id".to_sym 

    if(params[parent_id_sym])
      @parent = parentClass.find(params[parent_id_sym])
    end
    
    @provisioningtime = params[:provisioningtime]
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
  
  def set_async_mode
    if ENV["WEBPORTAL_ASYNC_MODE"] == "true"
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
