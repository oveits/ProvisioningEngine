class ProvisioningsController < ApplicationController
  before_action :set_provisioning, only: [:show, :edit, :update, :destroy]

  def stop
    @provisioning = Provisioning.find(params[:id])
    @provisioning.destroydelayedjob
    flash[:notice] = "Provisioning [id: #{params[:id]}] stopped."
    #redirect_to provisionings_url
    redirect_to :back
  end
  
  def deliver
    @provisioning = Provisioning.find(params[:id])
    #@provisioning.createdelayedjob
    @provisioning.deliverasynchronously
    flash[:notice] = "Provisioning in progress."
    #redirect_to provisionings_url
    redirect_to :back
  end

  # GET /provisionings
  # GET /provisionings.json
  def index
    @active = params[:active]
    # can be :true, :any
    
#abort "provisionings index test"

    #TODO: today,this index will only display customer provisionings, if called from a customer context
    # however, we also want to see all provisioning of child objects, e.g. the sites of this customer
    # see TODO below
    
    if @provisionings.nil?   
      if(params[:user_id])
        @user = User.find(params[:user_id])
        @provisionings = Provisioning.where(user: params[:user_id])
      elsif(params[:site_id])
        @site = Site.find(params[:site_id])
        @provisionings = Provisioning.where(site: params[:site_id])
      elsif(params[:customer_id])
        @customer = Customer.find(params[:customer_id])
        @provisionings = Provisioning.where(customer: params[:customer_id]) 
        #TODO: search for all provisionings, where customer: this customer(done), or site: one of the sites of this customer (open) or user: one of the users of the sites of this customer (open)
      else
        @provisionings = Provisioning.all
      end
    end

#abort @provisionings.inspect    
    #abort @provisionings.count.to_s + "params[:customer_id] = " + params[:customer_id].to_s
    
    # debugging:
    Provisioning.all.each do |provisioning|
      p '##############################################'
      p provisioning.customer.to_s
    end
    
    # show only active provisioning jobs:
    if @active
      @activeProvisionings= []
      @provisionings.each do |provisioning|
        @activeProvisionings << provisioning if provisioning.activeJob?
      end
      
      #abort @activeProvisionings.inspect
      @provisionings =  @activeProvisionings
    end 
    
    #abort @provisionings.inspect
            
  end

  # GET /provisionings/1
  # GET /provisionings/1.json
  def show
  end

  # GET /provisionings/new
  def new
    @provisioning = Provisioning.new
  end

  # GET /provisionings/1/edit
  def edit
  end

  # POST /provisionings
  # POST /provisionings.json
  def create
    # TODO: in provisioning_params:action, prepend target.configuration of the customer or site.customer or user.site.customer
    @provisioning = Provisioning.new(provisioning_params)
    
    respond_to do |format|
      if @provisioning.save
        format.html { redirect_to @provisioning, notice: 'Provisioning was successfully created.' }
        format.json { render :show, status: :created, location: @provisioning }
        #@provisioning.send_later(:deliver)
        @delayedjob = Delayed::Job.enqueue(ProvisioningJob.new(@provisioning.id), {:priority => 0 })
            # for troubleshooting of the above Delayed::Job, it is easier to replace the above command 
            # by the following two lines, so the ProvisioningJob can be debugged as a foreground process:
            #@provisioningjob = ProvisioningJob.new(@provisioning.id)
            #@provisioningjob.perform
            p '++++++++++++++++++++++++++++++++'
            p "@delayedjob.id = " + @delayedjob.id.to_s
            p '++++++++++++++++++++++++++++++++'
            
       #abort @provisioning.inspect
            @provisioning.update_attributes!(:delayedjob_id => @delayedjob.id)
            #
            # Note: delayedjob attribute will be removed again at the end of the ProvisioningJob
            #
            p '++++++++++++++++++++++++++++++++'
            p "@provisioning.delayedjob.id = " + @provisioning.delayedjob.id.to_s
            p '++++++++++++++++++++++++++++++++'
      else
        format.html { render :new }
        format.json { render json: @provisioning.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /provisionings/1
  # PATCH/PUT /provisionings/1.json
  def update
    respond_to do |format|
      if @provisioning.update(provisioning_params)
        format.html { redirect_to @provisioning, notice: 'Provisioning was successfully updated.' }
        format.json { render :show, status: :ok, location: @provisioning }
      else
        format.html { render :edit }
        format.json { render json: @provisioning.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /provisionings/1
  # DELETE /provisionings/1.json
  def destroy
    @provisioning.destroydelayedjob
    @provisioning.destroy
    respond_to do |format|
      format.html { redirect_to provisionings_url, notice: 'Provisioning was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  # allow for a possibility to remove all provisionings using a single button press:
  # see http://stackoverflow.com/questions/21489528/unable-to-delete-all-records-in-rails-4-through-link-to
  
  def removeAll
    @provisionings = Provisioning.all

    @provisionings.each do |provisioning| 
      provisioning.destroy # is not calling the controller's destroy method, but is only removing the database entry
      provisioning.destroydelayedjob # destroydelayedjob is defined in models/provisioning.rb
    end
    flash[:notice] = "All provisionings have been deleted."
    redirect_to provisionings_url
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_provisioning
      @provisioning = Provisioning.find(params[:id])
      #@provisionings = Provisioning.all
      #redirect_to provisionings_path
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def provisioning_params
      params.require(:provisioning).permit(:action, :site, :customer, :active)
    end
end
