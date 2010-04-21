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

class UserPageController < ApplicationController
  before_filter :common_init

  def redirect_to_userpage
    if User.current.nil?
      redirect_to :controller => 'page', :action => 'view', :page => Raki.frontpage
    else
      redirect_to :controller => 'user_page', :action => 'view', :user => User.current.username
    end
  end

  def view
    current_revision = @provider.userpage_revisions(@user).last
    @page_info = {:date => current_revision.date.strftime(t 'datetime_format'), :user => current_revision.user, :version => current_revision.version} unless current_revision.nil?
    respond_to do |format|
      format.html
      format.txt { render :inline => @provider.userpage_contents(@user, @revision), :content_type => 'text/plain' }
    end
  end

  def info
    return if redirect_if_userpage_not_exists
    @revisions = @provider.userpage_revisions @user
  end

  def edit
  end

  def update
    @provider.userpage_save @user, params[:content], params[:message], User.current
    redirect_to :controller => 'user_page', :action => 'view', :user => @user
  end
  
  private

  def common_init
    @user = params[:user]
    @revision = params[:revision]
    @provider = Raki.provider(:user_page)
    @title = @user
  end

  def redirect_if_userpage_not_exists
    unless @provider.userpage_exists?(@user)
      redirect_to :controller => 'user_page', :action => 'view', :user => @user
      true
    end
    false
  end

end
