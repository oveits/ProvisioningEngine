class CustomersController < ApplicationController
  before_action :set_customer, only: [:show, :edit, :update, :destroy]

  # GET /customers
  # GET /customers.json
  def index
    @customers = Customer.all
  end

  # GET /customers/1
  # GET /customers/1.json
  def show
  end

  # GET /customers/new
  def new
    @customer = Customer.new
    ro = 'readonly'; rw = 'readwrite'
    #@myparams = {"id"=>'ro', "name"=>rw, "created_at"=>'', "updated_at"=>'', "status"=>'', "target_id"=>'showTargetDropDown'}
    @myparams = {"id"=>'ro', "name"=>rw, "language"=>'showLanguageDropDown', "created_at"=>'', "updated_at"=>'', "status"=>'', "target_id"=>'showTargetDropDown'}
    #@myparams = {"id"=>'ro', "name"=>rw, "language"=>rw, "created_at"=>'', "updated_at"=>'', "status"=>'', "target_id"=>'showTargetDropDown'}

  end

  # GET /customers/1/edit
  def edit
    ro = 'readonly'; rw = 'readwrite'
    @myparams = {"id"=>ro, "name"=>rw, "language"=>'showLanguageDropDown', "customer_id"=>ro, "created_at"=>ro, "updated_at"=>ro, "status"=>ro, "target_id"=>ro }
  end

  # POST /customers
  # POST /customers.json
  def create
    # TODO: the next 2 lines are still needed. Is this the right place to control, whether a param is ro or rw?
    ro = 'readonly'; rw = 'readwrite'
    @myparams = {"id"=>'ro', "name"=>rw, "created_at"=>'', "language"=>'showLanguageDropDown', "updated_at"=>'', "status"=>'', "target_id"=>'showTargetDropDown'}

    @object = Customer.new(customer_params)
    @customer = @object
    @className = @object.class.to_s
#abort @object.provisioningtime.inspect

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

  # PATCH/PUT /customers/1
  # PATCH/PUT /customers/1.json
  def update
    ro = 'readonly'; rw = 'readwrite'
    @myparams = {"id"=>ro, "name"=>rw, "language"=>'showLanguageDropDown', "customer_id"=>ro, "created_at"=>ro, "updated_at"=>ro, "status"=>ro, "target_id"=>ro }

    respond_to do |format|
      if @customer.update(customer_params)
        format.html { redirect_to @customer, notice: 'Customer was successfully updated.' }
        format.json { render :show, status: :ok, location: @customer }
        format.js
      else
        format.html { render :edit }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
        format.js
      end
    end
  end

  # PATCH /customers/1/deprovision
  # PATCH /customers/1/deprovision.json
  def deprovision
    @object = Customer.find(params[:id])
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

  # DELETE /customers/1
  # DELETE /customers/1.json
  def destroy(deprovision = true)
    @object = @customer
    @className = @object.class.to_s
    
    if @object.provisioned?
      if deprovision
        @object.provision(:destroy)
        flash[:success] = "#{@className} #{@object.name} is being de-provisioned."
        #redirectPath = :back
        redirectPath = customers_url
      else
        flash[:alert] = "#{@className} #{@object.name} is deleted from the database, but note that it might be is still configured on a target system."
        #flash[:success] = "#{@className} #{@object.name} is deleted, but note that it might be is still configured on a target system."
        redirectPath = customers_url
      end
      
    else
      flash[:success] = "#{@className} #{@object.name} deleted."
      redirectPath = customers_url
      @object.destroy!
      
    end 

    
    respond_to do |format|
      format.html { redirect_to redirectPath }
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

  # allow for a possibility to remove all provisionins using a single button press:
  # see http://stackoverflow.com/questions/21489528/unable-to-delete-all-records-in-rails-4-through-link-to
  def removeAll
    @customers = Customer.all

    @customers.each do |customer| 
      customer.destroy
    end
    flash[:notice] = "All customers have been deleted."
    redirect_to customers_url
  end

  def synchronize

    # none of them work: CustomersHelper seems to be known, but ttt is not known, although defined in app/helpers/customers_helper.rb
    #abort CustomersHelper::ttt
    #abort CustomersHelper:ttt
    #abort CustomersHelper.ttt

    # Status:
    # - for synchronization of all customers of a target, here the first POC is implemented with target = CSL9DEV
    # - not nice: since customer.synchronize is to be issued, a dummy customer has to be created
    # TODO:
    # - test as rspec: DONE
    # - remove the test deletions and cleanup
    # - synchronize for all targets, or show a dropdown, which target(s) is (are) to be synchronized
    # - get rid of the dummy Customer concept
    #   - ideas: 
    #     1) directly call UpdateDB.new(..).perform: in this case the method 'perform' needs to be extended, sp it can be called with a target instead of a customer
    #     2) or directly call Provisioning.new(...).perform(:read,...) instead of dummyCustomer.synchronize().
    #     see app/models/provisioningobject.rb method 'synchroniz()', what is to be done in addition
    #     3) create class specific modules that run the read and create commands without the need of a dummy object...
    # - apply to Sites and Users (and Targets?)   

	#abort params[:id].inspect
    if params[:id].nil?
      # PATCH       /customers/synchronize
      recursive = false # recursive not yet supported
 
#           # for test:
#           Customer.where(name: 'OllisTestCustomer').last.destroy unless Customer.where(name: 'OllisTestCustomer').count == 0
#           Customer.where(name: 'OllisTestCustomer2').last.destroy unless Customer.where(name: 'OllisTestCustomer2').count == 0
#           
#           # cleanup (for test only; cannot be done later, since another sync process might be in need of the dummy customer):
#           Customer.where('name LIKE ?', "_sync_dummyCustomer_________________%").each do |element|
#             element.destroy
#           end
      
      Customer.synchronizeAll
      redirect_to :back, notice: "All Customers are being synchronized."

if false

           #      # test via targets:
           #      targets=Target.where(name: 'CSL9DEV')
           #      updateDB = UpdateDB.new
           #      targets.each do |target|
           #        responseBody = updateDB.perform(target)
           #      end
           
           #     # test via dummyCustomer
           #      # need to create a dummy customer in order to call synchronizeAll method

      # for now, test CSL9DEV sync only:
      targets = Target.where('name LIKE ?', 'CSL9DEV%')
      target = targets.last
      target_id = target.id
	#abort target.inspect
      if Customer.where(name: "_sync_dummyCustomer_________________#{target.id}", target_id: target.id).count == 0
        dummyCustomer = Customer.new(name: "_sync_dummyCustomer_________________#{target.id}", target_id: target.id) 
      elsif Customer.where(name: "_sync_dummyCustomer_________________#{target.id}", target_id: target.id).count == 1
        dummyCustomer = Customer.where(name: "_sync_dummyCustomer_________________#{target.id}", target_id: target.id).last
      else
        abort "found more than one dummy customer with name _sync_dummyCustomer_________________#{target.id} on target #{target.name}"
      end
      #
      # bacause us async synchronization, the dummyObj needs to be saved (delayed_jobs cannot work on transient data):
      dummyCustomer.save!(validate: false)
	#abort dummyCustomer.inspect
      dummyCustomer.synchronize(async, recursive)
      #dummyCustomer.destroy

#      updateDB = UpdateDB.new
#      #responseBody = updateDB.delay.perform(dummyCustomer)
#      responseBody = updateDB.perform(dummyCustomer)

      redirect_to :back, notice: "All #{dummyCustomer.class.name.pluralize} are being synchronized."
end
    else
      # PATCH       /customers/1/synchronize
      async = true
      recursive = true
      @object = Customer.find(params[:id])
      @object.synchronize(async, recursive)
      redirect_to :back, notice: "#{@object.class.name} #{@object.name} is being synchronized."
    end
  end

  # PATCH	/customers/1/provision
  def provision
    async = true
    @object = Customer.find(params[:id])
    respond_to do |format|
      if @object.provision(:create, async)
        format.html { redirect_to :back, notice: "#{@object.class.name} #{@object.name} is being provisioned to target system(s)" }
        format.json { render :show, status: :ok, location: @object }
      else
        format.html { redirect_to :back, notice: "#{@object.class.name} #{@object.name} could not be provisioned to target system(s)" }
        format.json { render json: @object.errors, status: :unprocessable_entity }
      end # if
    end # do
  end # def provision

  def provisionOld
    # TODO: test! It is not tested since I had removed the provision button!
    @customer = Customer.find(params[:id])
    #@customer.update_attributes!(:status => 'waiting for provisioning')
    respond_to do |format|
#      if @customer.provision("action=Add Customer, customerName=#{customer_params[:name]}")
      if @customer.provision(:create)
#        @provisionings = Provisioning.where(customer: @customer)
  #      format.html { redirect_to @customer, notice: "Customer #{@customer.name} is being provisioned to target system(s)" }
        format.html { redirect_to :back, notice: "Customer #{@customer.name} is being provisioned to target system(s)" }
        format.json { render :show, status: :ok, location: @customer }
      else
        #format.html { redirect_to @customer, error: "Customer #{@customer.name} could not be provisioned to target system(s)" }
        format.html { redirect_to :back, error: "Customer #{@customer.name} could not be provisioned to target system(s)" }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end # if
    end # do  
  end # def provision
  
    
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_customer
      @customer = Customer.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def customer_params
      params.require(:customer).permit(:name, :target_id, :language, :provisioningtime)
    end
end
