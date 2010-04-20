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

class PageController < ApplicationController
  before_filter :common_init

  def redirect_to_frontpage
    redirect_to :controller => 'page', :action => 'view', :page => Raki.frontpage
  end

  def view
    current_revision = @page_provider.page_revisions(@page).last
    @page_info = {:date => current_revision.date.strftime(t 'datetime_format'), :user => current_revision.user }
    respond_to do |format|
      format.html
      format.txt { render :inline => @page_provider.page_contents(@page, @revision), :content_type => 'text/plain' }
    end
  end

  def info
    redirect_if_page_not_exists
    @revisions = @page_provider.page_revisions @page
  end

  def edit
  end

  def update
    @page_provider.page_save @page, params[:content], params[:message], User.current
    redirect_to :controller => 'page', :action => 'view', :page => @page
  end

  def rename
    redirect_if_page_not_exists
    unless @page_provider.page_exists? params[:name]
      @page_provider.page_rename @page, params[:name], User.current
      redirect_to :controller => 'page', :action => 'view', :page => params[:name]
    else
      flash[:notice] = t 'page.info.page_already_exists'
      redirect_to :controller => 'page', :action => 'info', :page => @page
    end
  end

  def delete
    redirect_if_page_not_exists
    @page_provider.page_delete @page, User.current
    redirect_to :controller => 'page', :action => 'info', :page => Raki.frontpage
  end

  private

  def common_init
    @page = params[:page]
    @revision = params[:revision]
    @page_provider = Raki::Providers.page
    @title = @page
  end

  def redirect_if_page_not_exists
    unless @page_provider.page_exists?(@page)
      redirect_to :controller => 'page', :action => 'view', :page => @page
    end
  end

end
