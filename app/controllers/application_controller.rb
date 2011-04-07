# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery  :only => [:update, :delete]# See ActionController::RequestForgeryProtection for details

  def index
    docs = File.read("#{RAILS_ROOT}/README.markdown")
    response.headers['Content-type'] = 'text/plain'
    render :text => docs
  end

end
