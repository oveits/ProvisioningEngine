class CustomersController < ProvisioningobjectsController #ApplicationController

  # GET /customers
  # GET /customers.json
  def index
  end

 # GET /customers/new
  def new
    @customer = Customer.new
    @provisioningobject = @customer
    @myparams = {"id"=>'ro', "name"=>rw, "language"=>'showLanguageDropDown', "created_at"=>'', "updated_at"=>'', "status"=>'', "target_id"=>'showTargetDropDown'}
  end

  # GET /customers/1/edit
  def edit
    @myparams = {"id"=>ro, "name"=>rw, "language"=>'showLanguageDropDown', "customer_id"=>ro, "created_at"=>ro, "updated_at"=>ro, "status"=>ro, "target_id"=>ro }
  end

  # POST /customers
  # POST /customers.json
  def create
    # TODO: the next line is still needed. Is this the right place to control, whether a param is ro or rw?
    @myparams = {"id"=>'ro', "name"=>rw, "created_at"=>'', "language"=>'showLanguageDropDown', "updated_at"=>'', "status"=>'', "target_id"=>'showTargetDropDown'}

    @provisioningobject = Customer.new(provisioningobject_params)
#abort @provisioningobject.inspect
    @customer = @provisioningobject
    @className = @provisioningobject.class.to_s
#abort @provisioningobject.provisioningtime.inspect

    super
  end

  # PATCH/PUT /customers/1
  # PATCH/PUT /customers/1.json
  def update
    @myparams = {"id"=>ro, "name"=>rw, "language"=>'showLanguageDropDown', "customer_id"=>ro, "created_at"=>ro, "updated_at"=>ro, "status"=>ro, "target_id"=>ro }
    @provisioningobject = @customer

    super
  end

  # PATCH /customers/1/deprovision
  # PATCH /customers/1/deprovision.json
  def deprovision
    provisioningobject_provisionings_path = customer_provisionings_path(@provisioningobject, active: true )
    async = true

    super
  end

  # DELETE /customers/1
  # DELETE /customers/1.json
  def destroy(deprovision = false)
    @provisioningobject = @customer
    @className = @provisioningobject.class.to_s
    @redirectPath = customers_url

    super
  end

  # allow for a possibility to remove all provisionins using a single button press:
  # see http://stackoverflow.com/questions/21489528/unable-to-delete-all-records-in-rails-4-through-link-to
  def removeAll
    @provisioningobjects = Customer.all
    @redirectPath = customers_url

    super
  end

  # PATCH /customers/1/synchronize
  # -> find single customer on target and synchronize the data to the local database
  # PATCH /customers/synchronize
  # -> find all customers of all known target (i.e. targets found in the local database), and synchronize them to the local database
  def synchronize
    # @partentTargets = nil means all parent targets for the synchronizeAll function
    @partentTargets = nil;
    @myClass = Customer
    #@async_all = false # async does not yet work; not clear, why not, since the same code works fine with "Delayed::Worker.delay_jobs = false"
    #@async_individual = false
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

  # PATCH       /customers/1/provision
  def provision
    @async = true
    @provisioningobject = Customer.find(params[:id])
    
    super
  end # def provision


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_provisioningobject
      @customer = Customer.find(params[:id])
      @provisioningobject = @customer
    end
 
    def set_provisioningobjects
      @customers = Customer.all
      @provisioningobjects = @customers
    end


    # Never trust parameters from the scary internet, only allow the white list through.
    def provisioningobject_params
      params.require(:customer).permit(:name, :target_id, :language, :provisioningtime)
    end


  
end
