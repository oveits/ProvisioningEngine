class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  
  # original:
  #protect_from_forgery with: :exception
  # tried the following: (works well but is unsecure):
  #skip_before_filter :verify_authenticity_token, if: :json?
  # replaced by (see http://api.rubyonrails.org/classes/ActionController/RequestForgeryProtection.html):
  protect_from_forgery with: :null_session, if: :json_request?
  # now json as well as non-json requests are successful (I do not know, why non-json works...)
  
  def root
    redirect_to customers_path
  end
  
  add_flash_types :error, :success
  
protected

  def json_request?
    request.format.json?
  end
end
