class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  alias_method :devise_current_user, :current_user

  private
  def current_user
    begin
        if session[:user_id]
            @current_user = User.find(session[:user_id]) 
        else
            @current_user = devise_current_user
        end
    rescue
        session[:user_id] = nil
    end
  end
  helper_method :current_user_general
end
