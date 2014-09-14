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
    @myparams = {"id"=>'none', "name"=>rw, "customer_id"=>'showCustomerDropDown', "created_at"=>'none', "updated_at"=>'none', "status"=>'none', "sitecode"=>rw, "countrycode"=>rw, "areacode"=>rw, "localofficecode"=>rw, "extensionlength"=>rw, "mainextension"=>rw, "gatewayIP"=>rw }

  end

  # GET /sites/1/edit
  def edit
    # @customer is needed in the edit form (_form.html.erb)
    @customer = @site.customer
    ro = 'readonly'; rw = 'readwrite'
    @myparams = {"id"=>ro, "name"=>rw, "customer_id"=>ro, "created_at"=>ro, "updated_at"=>ro, "status"=>ro, "sitecode"=>rw, "countrycode"=>rw, "areacode"=>rw, "localofficecode"=>rw, "extensionlength"=>rw, "mainextension"=>rw, "gatewayIP"=>rw }

  end

  # POST /sites
  # POST /sites.json
  def create
    @site = Site.new(site_params)
    #@customer = Customer.find(params[:customer_id])
    @site.status = 'waiting for provisioning'
      
    respond_to do |format|
      if @site.save
        format.html { redirect_to @site.customer, notice: 'Site is being created.' }
        format.json { render :show, status: :created, location: @site }

        @customer = @site.customer
        inputBody = "action=Add Site, customerName=#{@customer.name}, SiteName=#{site_params[:name]}, SC=#{site_params[:sitecode]}"          
        inputBody += ", GatewayIP=#{site_params[:gatewayIP]}, CC=#{site_params[:countrycode]}, AC=#{site_params[:areacode]}, LOC=#{site_params[:localofficecode]}, XLen=#{site_params[:extensionlength]}"       
        inputBody += ", EndpointDefaultHomeDnXtension=#{site_params[:mainextension]}"

        @site.provision(inputBody)
        
      else
        format.html { 
          ro = 'readonly'; rw = 'readwrite'
          @myparams = {"id"=>'', "name"=>rw, "customer_id"=>'showCustomerDropDown', "created_at"=>'', "updated_at"=>'', "status"=>'', "sitecode"=>rw, "countrycode"=>rw, "areacode"=>rw, "localofficecode"=>rw, "extensionlength"=>rw, "mainextension"=>rw, "gatewayIP"=>rw }
          render :new }
        format.json { render json: @site.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sites/1
  # PATCH/PUT /sites/1.json
  def update
    respond_to do |format|
      if @site.update(site_params)
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
    #p params.inspect
    #sleep 0.1
    @site = Site.find(params[:id])
        
    updateDB = UpdateDB.new
    returnBody = updateDB.perform(@site)
    #p '---------------- synchronize ----------------'
    #p returnBody       
    
    if returnBody[/ERROR/].nil? && !returnBody[/>#{@site.name}</].nil?
      # success
      @site.update_attributes(:status => 'synchronized')
      redirect_to @site.customer, notice: "Site #{@site.name} has been synchronized: target system -> database."
    elsif !returnBody[/ERROR/].nil?
      # failure: Provisioning Error
      @site.update_attributes(:status => "synchronization failed (#{returnBody[/ERROR.*$/]})")
      redirect_to @site.customer, notice: "Site #{@site.name} synchronization failed with Error: #{returnBody[/ERROR.*$/]}"
    elsif returnBody[/>#{@site.name}</].nil?
      # failure: Site not (yet) provisionined on target system
      @site.update_attributes(:status => 'synchronization failed (Site not found)')
      redirect_to @site.customer, notice: "Site #{@site.name} synchronization failed with Error: Site not found on target system"
    end
  end
  
  def provision
    @site = Site.find(params[:id])
    respond_to do |format|
      if @site.provision
        @provisionings = Provisioning.where(site: @site)
        format.html { redirect_to @site, notice: "Site #{@site.name} is being provisioned to target system(s)" }
        format.json { render :show, status: :ok, location: @site }
      else
        format.html { redirect_to @site, notice: "Site #{@site.name} could not be provisioned to target system(s)" }
        format.json { render json: @site.errors, status: :unprocessable_entity }
      end # if
    end # do  
  end # def provision

  # DELETE /sites/1
  # DELETE /sites/1.json  
  def destroyOld   
    #@site.destroy 
    @provisioning = Provisioning.new(action: "action=Delete Site, customerName=#{@site.customer.name}, SiteName=#{@site.name}", site: @site)
    @provisioning.save 


    # we can only destroy, if no active delayed job for this object is present:
    @provisionings = Provisioning.where(site: @site)
    job = nil
    @provisionings.each do |provisioning|
      unless provisioning.delayedjob.nil?
        begin
          job = Delayed::Job.find(provisioning.delayedjob)
          break  # will break the do loop only, if a job was found
        rescue
          # keep: job = nil
        end
      end
    end
    # now job != nil, if an active job has been found for this site
    
    @customer = @site.customer
          
    if job.nil? 
      # no active job exists, so a destroy job can be created 

      flash[:notice] = "Site #{@site.name} is being destroyed (background process)."
      @site.update_attributes(:status => 'deletion in progress')
         
      @provisioning.createdelayedjob
      
      respond_to do |format|
        format.html { redirect_to @customer, notice: "Site #{@site.name} is being destroyed (background process)." }
        format.json { head :no_content }
      end
    else
      flash[:notice] = "Site #{@site.name} cannot be deleted, since there are active provisioning tasks running"
      
      @provisioning.destroy
      
      respond_to do |format|
        format.html { redirect_to site_provisionings_path(@site), notice: "Site #{@site.name} cannot be deleted, since there are active provisioning tasks running." }
        format.json { head :no_content }
      end
    end     
  end
  
  def destroy
    #@site = Site.find(params[:id])          
    @customer = @site.customer
    inputBody = "action=Delete Site, customerName=#{@customer.name}, SiteName=#{@site.name}"
    
    # we should only destroy, if no active delayed job for this object is present:
    @provisionings = Provisioning.where(site: @site)
    activeProvisioningJob = nil
    @provisionings.each do |provisioning|
      unless provisioning.delayedjob.nil?
        begin
          activeProvisioningJob = Delayed::Job.find(provisioning.delayedjob)
          break  # will break the do loop only, if a job was found
        rescue
          # keep: activeProvisioningJob = nil
        end
      end
    end
    # now activeProvisioningJob != nil, if an active job has been found for this site
     
    if activeProvisioningJob.nil? and @site.provision(inputBody)
      respond_to do |format|
        format.html { redirect_to @customer, notice: "Site #{@site.name} is being destroyed (background process)." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to site_provisionings_path(@site), notice: "Site #{@site.name} cannot be deleted, since there are active provisioning tasks running." }
        format.json { head :no_content }
      end
    end    
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_site
      @site = Site.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def site_params
      params.require(:site).permit(:name, :customer_id, :sitecode, :gatewayIP, :countrycode, :areacode, :localofficecode, :extensionlength, :mainextension)
    end
end

