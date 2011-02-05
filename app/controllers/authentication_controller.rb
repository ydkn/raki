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

  def login
    if authenticated?
      redirect
      return
    end
    @title = t 'auth.login'
    
    if Raki::Authenticator.respond_to? :form_fields
      @form_fields = Raki::Authenticator.form_fields
    else
      @form_fields = []
    end
    @context[:login] = true
    begin
      unless params[:loginsubmit].nil?
        resp = Raki::Authenticator.login(params, session, cookies)
        if resp.is_a? String
          redirect_to resp
        elsif resp.is_a? User
          User.current = resp
          session[:user] = resp.to_hash
        else
          User.current = AnonymousUser.new request.remote_ip
          flash[:notice] = t 'auth.invalid_credentials'
        end
      end
    rescue => e
      flash[:notice] = e.to_s
    end
  end

  def logout
    if Raki::Authenticator.respond_to? :logout
      resp = Raki::Authenticator.logout params, session, cookies
      if resp.is_a? String
        redirect_to resp
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
      if resp.is_a? User
        User.current = resp
        session[:user] = resp.to_hash
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
    redirect_to :controller => 'page', :action => 'view', :namespace => Raki.frontpage[:namespace], :page => Raki.frontpage[:name]
  end
  
  def session_reset
    User.current = AnonymousUser.new request.remote_ip
    session[:visited_pages] = []
    session.delete(:user)
    reset_session
    flash[:notice] = t 'auth.logged_out'
    redirect
  end
  
  def authenticated?
    return false if User.current.is_a? AnonymousUser
    User.current.is_a? User
  end

end
