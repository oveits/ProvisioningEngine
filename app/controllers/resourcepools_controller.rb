class ResourcepoolsController < ApplicationController
  before_action :set_resourcepool, only: [:show, :edit, :update, :destroy]

  # GET /resourcepools
  # GET /resourcepools.json
  def index
    @resourcepools = Resourcepool.all
  end

  # GET /resourcepools/1
  # GET /resourcepools/1.json
  def show
  end

  # GET /resourcepools/new
  def new
    @resourcepool = Resourcepool.new
  end

  # GET /resourcepools/1/edit
  def edit
  end

  # POST /resourcepools
  # POST /resourcepools.json
  def create
    @resourcepool = Resourcepool.new(resourcepool_params)

    respond_to do |format|
      if @resourcepool.save
        format.html { redirect_to @resourcepool, notice: 'Resourcepool was successfully created.' }
        format.json { render :show, status: :created, location: @resourcepool }
      else
        format.html { render :new }
        format.json { render json: @resourcepool.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /resourcepools/1
  # PATCH/PUT /resourcepools/1.json
  def update
    respond_to do |format|
      if @resourcepool.update(resourcepool_params)
        format.html { redirect_to @resourcepool, notice: 'Resourcepool was successfully updated.' }
        format.json { render :show, status: :ok, location: @resourcepool }
      else
        format.html { render :edit }
        format.json { render json: @resourcepool.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /resourcepools/1
  # DELETE /resourcepools/1.json
  def destroy
    @resourcepool.destroy
    respond_to do |format|
      format.html { redirect_to resourcepools_url, notice: 'Resourcepool was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_resourcepool
      @resourcepool = Resourcepool.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def resourcepool_params
      params.require(:resourcepool).permit(:name, :resource)
    end
end
