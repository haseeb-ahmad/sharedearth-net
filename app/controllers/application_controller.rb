class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :current_user, :current_person, :redirect_to_back

  layout :dynamic_layout

  if Rails.env.production?
    # Render 404's
    rescue_from ActiveRecord::RecordNotFound, :with => :missing_record_error
    rescue_from ActionController::RoutingError, :with => :missing_page

    # Render 501's
    rescue_from ActiveRecord::StatementInvalid, :with => :generic_error
    rescue_from RuntimeError, :with => :generic_error
    rescue_from NoMethodError, :with => :no_method_error
    rescue_from NameError, :with => :generic_error
    rescue_from ActionView::TemplateError, :with => :generic_error

    rescue_from FbGraph::Unauthorized, :with => :facebook_login
  end

  private

  def fb_token
    session[:fb_token]
  end

  def next_policy_path
    if not current_user.person.accepted_tc?
      terms_path
    elsif not current_user.person.accepted_tr?
      transparency_index_path
    elsif not current_user.person.accepted_pp?
      principles_terms_path
    else
      current_person.has_reviewed_profile? ? dashboard_path : edit_person_path(current_person)
    end
  end

  def current_user
    user_id = session[:user_id]
    @current_user ||= User.find(user_id) if user_id
  end

  def current_person
    current_user.person if current_user
  end

  def authenticate_user!
    if current_user.nil? or current_person.nil?
      redirect_to root_path, :alert => I18n.t('messages.must_be_signed_in')
    elsif Settings.invitations == 'true' and not current_person.authorised?
      redirect_to root_path, :alert => I18n.t('messages.must_be_signed_in')
    elsif not current_person.accepted_tc? or
          not current_person.accepted_tr? or
          not current_person.accepted_pp?
      redirect_to next_policy_path
    elsif not session[:fb_drop_url].nil?
      url = session[:fb_drop_url]
      url = new_item_path if url == items_path
      session[:fb_drop_url] = nil
      redirect_to url
    end
  end

  # Control which layout is used.
  def dynamic_layout
    if current_user.nil?
      'welcome'
    elsif current_user.person.nil?
      'beta_welcome'
    elsif Settings.invitations == 'true' and not current_user.person.authorised?
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
      format.json do
        render :json => {:error => message }
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
      format.json do
        render :json => {:error => message}
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

  def facebook_login
    session[:fb_drop_url] = request.request_uri unless request.request_uri.blank?
    render :template => 'static_pages/fb_logged_out', :status => :not_implemented
  end
end
