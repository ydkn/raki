# Raki - extensible rails-based wiki
# Copyright (C) 2010 Florian Schwab
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
    redirect_to :controller => 'page', :action => 'view', :page => Raki.frontpage unless User.current.nil?
    @title = t 'auth.login'
    unless params[:username].nil?
      if Raki.authenticator.login(params[:username], params[:password])
        User.current = User.find(params[:username])
        session[:user] = User.current.username
        redirect_to :controller => 'page', :action => 'view', :page => Raki.frontpage
      else
        session[:user] = nil
        flash[:notice] = t 'auth.invalid_credentials'
      end
    else
      flash[:notice] = nil
    end
  end

  def logout
    User.current = nil
    reset_session
    flash[:notice] = t 'auth.logged_out'
    redirect_to :controller => 'page', :action => 'view', :page => Raki.frontpage
  end

end
