class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  # OV added (see http://api.rubyonrails.org/classes/ActionController/RequestForgeryProtection.html)
  skip_before_action :verify_authenticity_token, if: :json_request?
  
  
  def root
    redirect_to customers_path
  end
  
  add_flash_types :error, :success

  # OV (see http://api.rubyonrails.org/classes/ActionController/RequestForgeryProtection.html)
  protected
    def json_request?
      request.format.json?
    end
  
end
