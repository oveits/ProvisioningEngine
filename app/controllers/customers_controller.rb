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
    @myparams = {"id"=>'ro', "name"=>rw, "created_at"=>'', "updated_at"=>'', "status"=>'', "target_id"=>'showTargetDropDown'}

  end

  # GET /customers/1/edit
  def edit
    ro = 'readonly'; rw = 'readwrite'
    @myparams = {"id"=>ro, "name"=>rw, "customer_id"=>ro, "created_at"=>ro, "updated_at"=>ro, "status"=>ro, "target_id"=>ro }
  end

  # POST /customers
  # POST /customers.json
  def create 
    # TODO: simplify Provisioning!!!
    # Today: XXX_controller.yyy calls 
    # -> XXX.provision == model XXX def provision calls 
    # -> @provisioning.createdelayedjob (== model provisioning) calls
    # -> lib/PrivisioningJob.perform
    # -> calls model provisioning.deliver
    # too many steps !!!!!!!!!!!!!!!!!!!!!!!!!
    
    ro = 'readonly'; rw = 'readwrite'
    @myparams = {"id"=>'ro', "name"=>rw, "created_at"=>'', "updated_at"=>'', "status"=>'', "target_id"=>'showTargetDropDown'}

    @customer = Customer.new(customer_params)
    #@provisioning = Provisioning.new(action: "action=Add Customer, customerName=#{customer_params[:name]}", customer: @customer)  
    
    #abort 'create customer'
    respond_to do |format|         
      if @customer.save #and @provisioning.save
        #@customer.status = 'waiting for provisioning'
        @customer.update_attributes(:status => 'waiting for provisioning')
        format.html { redirect_to @customer, notice: 'Customer is being created.' }
        format.json { render :show, status: :created, location: @customer } 
        
        @customer.provision("action=Add Customer, customerName=#{customer_params[:name]}")
        #Delayed::Job.enqueue(ProvisioningJob.new(@provisioning.id), {:priority => 3 })
          # for troubleshooting of the above Delayed::Job, it is easier to replace the above command 
          # by the following two lines, so the ProvisioningJob can be debugged as a foreground process:
          #@provisioningjob = ProvisioningJob.new(@provisioning.id)
          #@provisioningjob.perform
      else
        format.html { render :new  }                   
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /customers/1
  # PATCH/PUT /customers/1.json
  def update
    respond_to do |format|
      if @customer.update(customer_params)
        format.html { redirect_to @customer, notice: 'Customer was successfully updated.' }
        format.json { render :show, status: :ok, location: @customer }
      else
        format.html { render :edit }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /customers/1
  # DELETE /customers/1.json
  def destroy
    #@customer.destroy
    #abort 'dglhsöhgös'
    
    #
    # TODO: simplify Provisioning!!!
    # Today: XXX_controller.yyy calls 
    # -> model XXX.provision 
    # -> @provisioning.createdelayedjob (== model provisioning) calls
    # -> lib/PrivisioningJob.perform
    # -> calls model provisioning.deliver
    # too many steps !!!!!!!!!!!!!!!!!!!!!!!!!
#    @customer.provision("action=Delete Customer, customerName=#{@customer.name}")
#    @provisioning = Provisioning.new(action: "action=Delete Customer, customerName=#{@customer.name}", customer: @customer)
#    @provisioning.save 
#    @provisioning.deliver
#    Delayed::Job.enqueue(ProvisioningJob.new(@provisioning.id), {:priority => -3 })
      # for troubleshooting of the above Delayed::Job, it is easier to replace the above command 
      # by the following two lines, so the ProvisioningJob can be debugged as a foreground process:
      #@provisioningjob = ProvisioningJob.new(@provisioning.id)
      #@provisioningjob.perform

    #flash[:notice] = "Customer #{@customer.name} is being destroyed." # is duplicate
    
    # we should only destroy, if no active delayed job for this object is present:
    @provisionings = Provisioning.where(customer: @customer)
    activeProvisioningJob = nil
    @provisionings.each do |provisioning|
      unless provisioning.delayedjob_id.nil?
        begin
          activeProvisioningJob = Delayed::Job.find(provisioning.delayedjob_id)
          break  # will break the do loop only, if a job was found
        rescue
          # keep: activeProvisioningJob = nil
        end
      end
    end
    # now activeProvisioningJob != nil, if an active job has been found for this site
    
    if activeProvisioningJob.nil? and @customer.provision("action=Delete Customer, customerName=#{@customer.name}")
      @customer.update_attributes(:status => 'waiting for deletion')
      respond_to do |format|
        format.html { redirect_to customers_url, notice: "Customer #{@customer.name} is being destroyed (background process)." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to customer_provisionings_path(@customer), notice: "Customer #{@customer.name} cannot be deleted, since there are active provisioning tasks running." }
        format.json { head :no_content }
      end
    end
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
    #p params.inspect
    #sleep 0.1
    @customer = Customer.find(params[:id])
    @object = @customer
        
    updateDB = UpdateDB.new
    returnBody = updateDB.perform(@object)
    #p '---------------- synchronize ----------------'
    #p returnBody       
    
    if returnBody[/ERROR/].nil? && !returnBody[/>#{@object.name}</].nil?
      # success
      @object.update_attributes(:status => 'synchronized')
      redirect_to @object.customer, notice: "Customer #{@object.name} has been synchronized: target system -> database."
    elsif !returnBody[/ERROR/].nil?
      # failure: Provisioning Error
      @object.update_attributes(:status => "synchronization failed (#{returnBody[/ERROR.*$/]})")
      redirect_to @object.customer, notice: "Customer #{@object.name} synchronization failed with Error: #{returnBody[/ERROR.*$/]}"
    elsif returnBody[/>#{@object.name}</].nil?
      # failure: Customer not (yet) provisionined on target system
      @object.update_attributes(:status => 'synchronization failed (Customer not found)')
      redirect_to @object.customer, notice: "Customer #{@object.name} synchronization failed with Error: Customer not found on target system"
    end
  end
    
  def provision
    # TODO: simplify Provisioning!!!
    # Today: XXX_controller.yyy calls 
    # -> XXX.provision == model XXX def provision calls 
    # -> @provisioning.createdelayedjob (== model provisioning) calls
    # -> lib/PrivisioningJob.perform
    # -> calls model provisioning.deliver
    # too many steps !!!!!!!!!!!!!!!!!!!!!!!!!
    @customer = Customer.find(params[:id])
    #@customer.update_attributes(:status => 'waiting for provisioning')
    respond_to do |format|
      if @customer.provision("action=Add Customer, customerName=#{customer_params[:name]}")
        @provisionings = Provisioning.where(customer: @customer)
        format.html { redirect_to @customer, notice: "Customer #{@customer.name} is being provisioned to target system(s)" }
        format.json { render :show, status: :ok, location: @customer }
      else
        format.html { redirect_to @customer, notice: "Customer #{@customer.name} could not be provisioned to target system(s)" }
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
      params.require(:customer).permit(:name, :target_id)
    end
end
