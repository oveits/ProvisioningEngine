class SitesController < ApplicationController
  before_action :set_site, only: [:show, :edit, :update, :destroy]

  # GET /sites
  # GET /sites.json
  def index
    if(params[:customer_id])
      @customer = Customer.find(params[:customer_id])
      @sites = Site.where(customer: params[:customer_id])
    else
      @sites = Site.all
    end
  end
  
  def list
    if(params[:customer_id])
      #@customer = Customer.find(params[:customer_id])
      @sites = Site.find(params[:customer_id])
    end
  end

  # GET /sites/1
  # GET /sites/1.json
  def show
  end

  # GET /sites/new
  def new
    @site = Site.new
    if(params[:customer_id])
      @customer = Customer.find(params[:customer_id])
    end
    
    ro = 'readonly'; rw = 'readwrite'
    #@myparams = {"id"=>'none', "name"=>rw, "customer_id"=>'showCustomerDropDown', "created_at"=>'none', "updated_at"=>'none', "status"=>'none', "sitecode"=>rw, "countrycode"=>rw, "areacode"=>rw, "localofficecode"=>rw, "extensionlength"=>rw, "mainextension"=>rw, "gatewayIP"=>rw }
    #@myparams = {"id"=>'none', "name"=>rw, "customer_id"=>'showCustomerDropDown', "created_at"=>'none', "updated_at"=>'none', "status"=>'none', "sitecode"=>'none', "countrycode"=>rw, "areacode"=>rw, "localofficecode"=>rw, "extensionlength"=>rw, "mainextension"=>rw, "gatewayIP"=>rw }
    @myparams = {"id"=>'none', "name"=>rw, "customer_id"=>'showCustomerDropDown', "created_at"=>'none', "updated_at"=>'none', "status"=>'none', "sitecode"=>'none', "countrycode"=>'showDropDown', "areacode"=>rw, "localofficecode"=>rw, "extensionlength"=>rw, "mainextension"=>rw, "gatewayIP"=>rw }

  end

  # GET /sites/1/edit
  def edit
    # @customer is needed in the edit form (_form.html.erb)
    @customer = @site.customer
    ro = 'readonly'; rw = 'readwrite'
    #@myparams = {"id"=>ro, "name"=>rw, "customer_id"=>ro, "created_at"=>ro, "updated_at"=>ro, "status"=>ro, "sitecode"=>rw, "countrycode"=>rw, "areacode"=>rw, "localofficecode"=>rw, "extensionlength"=>rw, "mainextension"=>rw, "gatewayIP"=>rw }
    @myparams = {"id"=>ro, "name"=>rw, "customer_id"=>ro, "created_at"=>ro, "updated_at"=>ro, "status"=>ro, "sitecode"=>rw, "countrycode"=>'showDropDown', "areacode"=>rw, "localofficecode"=>rw, "extensionlength"=>rw, "mainextension"=>rw, "gatewayIP"=>rw }

  end

  # POST /sites
  # POST /sites.json
  def create 
    ro = 'readonly'; rw = 'readwrite'
    #@myparams = {"id"=>'none', "name"=>rw, "customer_id"=>'showCustomerDropDown', "created_at"=>'none', "updated_at"=>'none', "status"=>'none', "sitecode"=>rw, "countrycode"=>rw, "areacode"=>rw, "localofficecode"=>rw, "extensionlength"=>rw, "mainextension"=>rw, "gatewayIP"=>rw }
    @myparams = {"id"=>'none', "name"=>rw, "customer_id"=>'showCustomerDropDown', "created_at"=>'none', "updated_at"=>'none', "status"=>'none', "sitecode"=>rw, "countrycode"=>'showDropDown', "areacode"=>rw, "localofficecode"=>rw, "extensionlength"=>rw, "mainextension"=>rw, "gatewayIP"=>rw }

    @object = Site.new(site_params)
    @site = @object
    @className = @object.class.to_s
    async = true

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

  # PATCH/PUT /sites/1
  # PATCH/PUT /sites/1.json
  def update
     ro = 'readonly'; rw = 'readwrite'
    #@myparams = {"id"=>ro, "name"=>rw, "customer_id"=>ro, "created_at"=>ro, "updated_at"=>ro, "status"=>ro, "sitecode"=>rw, "countrycode"=>rw, "areacode"=>rw, "localofficecode"=>rw, "extensionlength"=>rw, "mainextension"=>rw, "gatewayIP"=>rw }
    @myparams = {"id"=>ro, "name"=>rw, "customer_id"=>ro, "created_at"=>ro, "updated_at"=>ro, "status"=>ro, "sitecode"=>rw, "countrycode"=>'showDropDown', "areacode"=>rw, "localofficecode"=>rw, "extensionlength"=>rw, "mainextension"=>rw, "gatewayIP"=>rw }

    respond_to do |format|
      if @site.update(site_params)
        @site.update_attributes!(:status => 'edited (provisioning status unknown)')
        format.html { redirect_to @site, notice: "Site #{@site.name} successfully updated in the database, but provisioning of target systems is not yet supported. Click \"synchronize\", for re-gaining consistency." }
        #format.html { redirect_to @site.customer, notice: 'Site was successfully updated.' }
        format.json { render :show, status: :ok, location: @site }
      else
        format.html { render :edit }
        format.json { render json: @site.errors, status: :unprocessable_entity }
      end
    end
  end

  def synchronize
    @object = Site.find(params[:id])
    updateDB = UpdateDB.new
    @object.update_attributes!(:status => 'synchronization in progress')
    returnBody = updateDB.delay.perform(@object)
    redirect_to :back, notice: "Site #{@object.name} is being synchronized."
  end
  
  def provision
    @site = Site.find(params[:id])
    respond_to do |format|
      if @site.provision(:create)
        #@provisionings = Provisioning.where(site: @site)
        format.html { redirect_to :back, notice: "Site #{@site.name} is being provisioned to target system(s)" }
        format.json { render :show, status: :ok, location: @site }
      else
        format.html { redirect_to :back, notice: "Site #{@site.name} could not be provisioned to target system(s)" }
        format.json { render json: @site.errors, status: :unprocessable_entity }
      end # if
    end # do  
  end # def provision

  # PATCH /sites/1/deprovision
  # PATCH /sites/1/deprovision.json
  def deprovision
    @object = Site.find(params[:id])
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

  # DELETE /sites/1
  # DELETE /sites/1.json  
  
  def destroy
    @object = @site
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
      redirectPath = site_provisionings_path(@object, active: true )
      #does not work: redirectPath = provisioningobject_provisionings_path(@object)
    elsif @object.provisioned?
      flash[:notice] = "#{@className} #{@object.name} is being de-provisioned."
      redirectPath = :back
      
      @object.update_attributes!(:status => 'waiting for deletion') unless @object.activeJob?
      #provisionTaskExistsAlready =  @object.provisionNew(provisioningAction, async)
      #provisionTaskExistsAlready =  @object.de_provision(async)
      @object.provision(:destroy)
    else
      flash[:success] = "#{@className} #{@object.name} deleted."
      redirectPath = sites_url
      
      @object.destroy!
    end 
    
    respond_to do |format|
      format.html { redirect_to redirectPath }
      format.json { head :no_content }
    end

#end   
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_site
      @site = Site.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def site_params
      params.require(:site).permit(:name, :customer_id, :sitecode, :gatewayIP, :countrycode, :areacode, :localofficecode, :extensionlength, :mainextension, :provisioningtime)
    end
end

