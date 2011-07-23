class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :current_user, :redirect_to_back
  
  layout :dynamic_layout
  
  # Render 404's
  rescue_from ActiveRecord::RecordNotFound, :with => :missing_record_error

  # Render 501's
  rescue_from ActiveRecord::StatementInvalid, :with => :generic_error
  rescue_from RuntimeError, :with => :generic_error
  rescue_from NoMethodError, :with => :no_method_error
  rescue_from NameError, :with => :generic_error
  rescue_from ActionView::TemplateError, :with => :generic_error

  private

  def current_user
    user_id = session[:user_id]
    @current_user ||= User.find(user_id) if user_id
    # TODO: should handle unlikely case where user with that ID no longer exists
  end
  
  def authenticate_user!
    if current_user.nil?
      redirect_to root_path, :alert => I18n.t('messages.must_be_signed_in')
    elsif !current_user.person.authorised? && Settings.invitations == 'true'
      redirect_to root_path, :alert => I18n.t('messages.must_be_signed_in')
    elsif !current_user.person.accepted_tc?
      redirect_to terms_path
    elsif !current_user.person.accepted_pp?
      redirect_to principles_terms_path
    end
  end
  
  # Control which layout is used.
  def dynamic_layout
    if current_user.nil?
      'welcome'
    elsif !current_user.person.authorised? && Settings.invitations == 'true'
      'beta_welcome'
    else
      'application'
    end
  end
  
  #Redirection with optional notice
  def redirect_to_back(options = {}, default = dashboard_path)
    if has_referer?
      redirect_to :back, :notice => options[:notice]
    else
      redirect_to default, :notice => options[:notice]
    end
  end
  
  def has_referer?
    !request.env["HTTP_REFERER"].blank? and request.env["HTTP_REFERER"] != request.env["REQUEST_URI"]
  end
  
  #Error pages
  #Error 401
  def missing_record_error(exception)
    respond_to do |format|
      format.html {render_404}
      format.any(:xml, :json) do
        render extension => {:error => exception.message}, :status => 'NO'
      end
    end
  end
  
  def missing_page(exception = nil)
    respond_to do |format|
      format.html {render_404}
    end
  end
  #Error 501
  def generic_error(exception, message = "OK that didn't work. Try something else.")
    respond_to do |format|
      format.html {render_501}
      format.any(:xml, :json) do
        render extension => {:error => message}, :status => 'NO'
      end
    end
  end
  
  def no_method_error(exception)
    generic_error(exception, "A potential syntax error in the making!")
  end
  
  def render_404
    render :template => 'static_pages/404', :status => :not_found
  end

  def render_501
    render :template => 'static_pages/501', :status => :not_implemented
  end
end
