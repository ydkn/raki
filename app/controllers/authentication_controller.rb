# Raki - extensible rails-based wiki
# Copyright (C) 2010 Florian Schwab & Martin Sigloch
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class AuthenticationController < ApplicationController
  
  include AuthenticationHelper

  def login
    redirect_to :controller => 'page', :action => 'view', :type => Raki.frontpage[:type], :id => Raki.frontpage[:page] if authenticated?
    @title = t 'auth.login'
    
    if Raki::Authenticator.respond_to? :form_fields
      @form_fields = Raki::Authenticator.form_fields
    else
      @form_fields = []
    end
    @context[:login] = true
    begin
      unless params[:loginsubmit].nil?
        res = Raki::Authenticator.login(params, session, cookies)
        if res.is_a?(String)
          redirect_to res
        elsif res.is_a?(User)
          session[:user] = res
        else
          session[:user] = AnonymousUser.new request.remote_ip
          flash[:notice] = t 'auth.invalid_credentials'
        end
      end
    rescue => e
      flash[:notice] = e.to_s
    end
  end

  def logout
    if Raki::Authenticator.respond_to? :logout
      res = Raki::Authenticator.logout params, session, cookies
      if res.is_a?(String)
        redirect_to res
      else
        session_reset
      end
    else
      session_reset
    end
  end

  def callback
    begin
      params.delete(:controller)
      params.delete(:action)
      resp = Raki::Authenticator.callback params, session, cookies
      if resp.is_a?(User)
        session[:user] = resp
        User.current= resp
        redirect
      else
        flash[:notice] = t 'auth.invalid_callback'
        redirect_to :controller => 'authentication', :action => 'login'
      end
    rescue => e
      flash[:notice] = e.to_s
      redirect_to :controller => 'authentication', :action => 'login'
    end
  end
  
  private
  
  def redirect(default=nil)
    redirect_to :controller => 'page', :action => 'view', :type => Raki.frontpage[:type], :id => Raki.frontpage[:page]
  end
  
  def session_reset
    User.current = AnonymousUser.new request.remote_ip
    reset_session
    flash[:notice] = t 'auth.logged_out'
    redirect
  end

end
