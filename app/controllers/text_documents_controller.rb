class TextDocumentsController < ApplicationController
  before_action :set_text_document, only: [:show, :edit, :update, :destroy]
  #skip_before_filter :verify_authenticity_token, if: :json?
  
  skip_before_filter :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }
  # replaced by (see http://stackoverflow.com/questions/9362910/rails-warning-cant-verify-csrf-token-authenticity-for-json-devise-requests)
#  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }
  

  # GET /text_documents
  # GET /text_documents.json
  def index
    
    # filtered via best match of the identifierhash
    # try: /text_documents?identifierhash[b]=b&identifierhash[a]=a
    # will return single document, if there is an exact match (in our example, if {a: a, b: b})
    # if nothing was found, we return also documents that match all parameters but may have more parameters:
    # e.g. a document with identifierhash = {a: a, b: b, c: c} will match the filter {a: a, b: b}, 
    # if there is no 
     
    if params[:filter].nil? 
      @text_documents = TextDocument.all
    else   
      @identifierhash = params[:filter].to_hash
      @text_documents = TextDocument.select{ |i| i.identifierhash == @identifierhash}
      
      # if not found, allow for a match, if all @identifierhash is included the record's hash:
      if @text_documents.count == 0
        # allow for best match. i.e. all specified parameters match, but there is no exact match:
        @text_documents = TextDocument.select{ |i| i.identifierhash == i.identifierhash.merge(@identifierhash)}
      end
    end
    
    #if @text_documents.count == 1
      
    respond_to do |format|
      format.html { @text_documents }
      format.json { @text_documents }
      format.text { 
        if @text_documents.count == 1
          @text_documents 
        else
          render json: @text_documents, status: :unprocessable_entity
          #abort "@text_documents.count = #{@text_documents.count}" #status: :unprocessable_entity
        end
        }
    end
    

          #abort @identifierhash.inspect
          #abort params[:identifierhash].class.name.inspect
          #abort @text_documents.inspect
  end

  # GET /text_documents/1
  # GET /text_documents/1.json
  def show
  end

  # GET /text_documents/new
  def new
    @text_document = TextDocument.new
          #abort @text_document.inspect
  end

  # GET /text_documents/1/edit
  def edit
    #abort "slkgehoösdrhödl"
  end

  # POST /text_documents
  # POST /text_documents.json
  def create
          #abort request.format.inspect
          #abort Proc.new { |c| c.request.format == 'application/json'}.inspect
          #abort YAML::load(text_document_params[:identifierhash]).inspect
    # convert identifierhash text to hash:
    #new_text_document_params = {}
    new_text_document_params = text_document_params
    new_text_document_params[:identifierhash] = YAML::load(text_document_params[:identifieryaml])
    #text_document_params[:identifierhash] = YAML::load(text_document_params[:identifieryaml])
    
          #abort YAML::load(text_document_params[:identifierhash]).class.name
          #abort new_text_document_params[:identifierhash].class.name
          #abort new_text_document_params[:identifierhash].inspect
    @text_document = TextDocument.new(new_text_document_params)

    respond_to do |format|
      if @text_document.save
        format.html { redirect_to @text_document, notice: 'Text document was successfully created.' }
        format.json { render :show, status: :created, location: @text_document }
      else
        format.html { render :new, new_text_document_params
              #abort new_text_document_params.inspect
          }
        format.json { render json: @text_document.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /text_documents/1
  # PATCH/PUT /text_documents/1.json
  def update
    
    new_text_document_params = text_document_params
    new_text_document_params[:identifierhash] = YAML::load(text_document_params[:identifieryaml])

    respond_to do |format|
      if @text_document.update(new_text_document_params)
        format.html { redirect_to @text_document, notice: 'Text document was successfully updated.' }
        format.json { render :show, status: :ok, location: @text_document }
      else
        format.html { render :edit }
        format.json { render json: @text_document.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /text_documents/1
  # DELETE /text_documents/1.json
  def destroy
    @text_document.destroy
    respond_to do |format|
      format.html { redirect_to text_documents_url, notice: 'Text document was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_text_document
      @text_document = TextDocument.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def text_document_params
      params.require(:text_document).permit(:identifierhash, :identifieryaml, :content)
    end
end
