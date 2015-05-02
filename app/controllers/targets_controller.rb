class TargetsController < ProvisioningobjectsController #ApplicationController
  before_action :set_target, only: [:show, :edit, :update, :destroy]

  # GET /targets
  # GET /targets.json
  def index
    @targets = Target.all
  end

  # GET /targets/1
  # GET /targets/1.json
  def show
  end

  # GET /targets/new
  def new
    @target = Target.new
  end

  # GET /targets/1/edit
  def edit
  end

  # POST /targets
  # POST /targets.json
  def create
    @target = Target.new(target_params)

    respond_to do |format|
      if @target.save
        format.html { redirect_to @target, notice: 'Target was successfully created.' }
        format.json { render :show, status: :created, location: @target }
      else
        format.html { render :new }
        format.json { render json: @target.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /targets/1
  # PATCH/PUT /targets/1.json
  def update
    respond_to do |format|
      if @target.update(target_params)
        format.html { redirect_to @target, notice: 'Target was successfully updated.' }
        format.json { render :show, status: :ok, location: @target }
      else
        format.html { render :edit }
        format.json { render json: @target.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /targets/1
  # DELETE /targets/1.json
  def destroy
    @target.destroy
    respond_to do |format|
      format.html { redirect_to targets_url, notice: 'Target was successfully destroyed.' }
      format.json { head :no_content }
      # needed for ajax according to http://stackoverflow.com/questions/22879329/rails-ajax-with-post-function-why-template-missing
      format.js { render nothing: true }
    end
  end

  # PATCH       /target/1/provision
  def provision
    super
  end # def provision

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_target
      @target = Target.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def target_params
      params.require(:target).permit(:name, :configuration)
    end
end
