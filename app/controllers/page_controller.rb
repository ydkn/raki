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
    redirect_to :controller => 'page', :action => 'view', :id => Raki.frontpage
  end

  def view
    current_revision = @provider.page_revisions(@page).last
    @page_info = {
      :date => current_revision.date,
      :user => current_revision.user,
      :version => current_revision.version,
      :type => 'page',
      :id => @page
    } unless current_revision.nil?
    respond_to do |format|
      format.html
      format.atom { @revisions = @provider.page_revisions @page }
      format.txt { render :inline => @provider.page_contents(@page, @revision), :content_type => 'text/plain' }
    end
  end

  def info
    return if redirect_if_page_not_exists
    @revisions = @provider.page_revisions @page
    respond_to do |format|
      format.html
    end
  end

  def edit
    if params[:content].nil?
      @content = @provider.page_contents(@page, @revision)
    else
      @content = params[:content]
      @preview = @content
    end
  end

  def update
    @provider.page_save @page, params[:content], params[:message], User.current
    redirect_to :controller => 'page', :action => 'view', :id => @page
  end

  def rename
    return if redirect_if_page_not_exists
    unless @provider.page_exists? params[:name]
      @provider.page_rename @page, params[:name], User.current
      redirect_to :controller => 'page', :action => 'view', :id => params[:name]
    else
      flash[:notice] = t 'page.info.page_already_exists'
      redirect_to :controller => 'page', :action => 'info', :id => @page
    end
  end

  def delete
    return if redirect_if_page_not_exists
    @provider.page_delete @page, User.current
    redirect_to :controller => 'page', :action => 'info', :id => Raki.frontpage
  end

  def attachments
    @attachments = []
    @provider.page_attachment_all(@page).each do |attachment|
      @attachments << {
        :name => attachment,
        :revision => @provider.page_attachment_revisions(@page, attachment).last
      }
    end
    @attachments.sort { |a,b| a[:name] <=> b[:name] }
  end

  def attachment_upload
    @provider.page_attachment_save(
      @page,
      File.basename(params[:attachment_upload].original_filename),
      params[:attachment_upload].read,
      params[:message],
      User.current
    )
    redirect_to :controller => 'page', :action => 'attachments', :id => @page
  end

  def attachment
    # ugly fix for ruby1.9 and rails2.5
    revision = @provider.page_attachment_revisions(@page, @attachment).last.id if @revision.nil?
    unless File.exists? "#{Rails.root}/tmp/attachments/#{@page}/#{revision}/#{@attachment}"
      FileUtils.mkdir_p "#{Rails.root}/tmp/attachments/#{@page}/#{revision}"
      File.open "#{Rails.root}/tmp/attachments/#{@page}/#{revision}/#{@attachment}", 'w' do |f|
        f.write(@provider.page_attachment_contents(@page, @attachment, @revision))
      end
    end
    send_file "#{Rails.root}/tmp/attachments/#{@page}/#{revision}/#{@attachment}"
  end

  private

  def common_init
    @page = params[:id]
    @revision = params[:revision]
    @attachment = params[:attachment].join '' unless params[:attachment].nil?
    @provider = Raki.provider(:page)
    @title = @page
  end

  def redirect_if_page_not_exists
    unless @provider.page_exists?(@page)
      redirect_to :controller => 'page', :action => 'view', :id => @page
      true
    end
    false
  end

end
