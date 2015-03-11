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
    
#abort 'create test'
    ro = 'readonly'; rw = 'readwrite'
    @myparams = {"id"=>'ro', "name"=>rw, "created_at"=>'', "language"=>'showLanguageDropDown', "updated_at"=>'', "status"=>'', "target_id"=>'showTargetDropDown'}

    @object = Customer.new(customer_params)
    @customer = @object
    @className = @object.class.to_s

    respond_to do |format|         
      if @object.save
        @object.provision(:create)
        format.html { redirect_to @object, notice: "#{@className} is being created." }
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

  # DELETE /customers/1
  # DELETE /customers/1.json
  def destroy
    @object = @customer
    @method = "Delete"
    @className = @object.class.to_s
    @classname = @className.downcase
    async = true
    
#flash[:notice] = "#{@className} #{@object.name} cannot be destroyed: has active jobs running."
#redirect_to customers_url, :flash => { :success => "oops!" }
#format.html { redirect_to customers_url }
#abort flash[:error]

#if false    
    if @object.activeJob?
      flash[:error] = "#{@className} #{@object.name} cannot be destroyed: has active jobs running: see below."
      #redirectPath = customer_provisionings_path(@object, true)
      redirectPath = customer_provisionings_path(@object, active: true )
      #does not work: redirectPath = provisioningobject_provisionings_path(@object)
    elsif @object.provisioned?
      flash[:notice] = "#{@className} #{@object.name} is being de-provisioned."
      redirectPath = :back
      
      #provisionTaskExistsAlready =  @object.provisionNew(provisioningAction, async)
      #provisionTaskExistsAlready =  @object.de_provision(async)
      @object.provision(:destroy)
    else
      flash[:success] = "#{@className} #{@object.name} deleted."
      redirectPath = customers_url
      
      @object.destroy!
    end 
    
    respond_to do |format|
      format.html { redirect_to redirectPath }
      format.json { head :no_content }
    end

#end   
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
      @object.update_attributes!(:status => 'synchronized')
      redirect_to @object.customer, notice: "Customer #{@object.name} has been synchronized: target system -> database."
    elsif !returnBody[/ERROR/].nil?
      # failure: Provisioning Error
      @object.update_attributes!(:status => "synchronization failed (#{returnBody[/ERROR.*$/]})")
      redirect_to @object.customer, notice: "Customer #{@object.name} synchronization failed with Error: #{returnBody[/ERROR.*$/]}"
    elsif returnBody[/>#{@object.name}</].nil?
      # failure: Customer not (yet) provisionined on target system
      @object.update_attributes!(:status => 'synchronization failed (Customer not found)')
      redirect_to @object.customer, notice: "Customer #{@object.name} synchronization failed with Error: Customer not found on target system"
    end
  end
    
  def provision
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
      #params.require(:customer).permit(:name, :target_id, :language)
      params.permit(:name, :target_id, :language)
    end
end
