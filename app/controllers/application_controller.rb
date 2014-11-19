class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  def root
    redirect_to customers_path
  end
  
  add_flash_types :error, :success
end
