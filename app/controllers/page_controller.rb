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

class PageController < ApplicationController
  FEED_LIMIT = 15
  VISITED_LIMIT = 8
  
  include Raki::Helpers::PermissionHelper
  include Raki::Helpers::ProviderHelper
  include ERB::Util
  
  before_filter :common_init, :except => [:redirect_to_frontpage, :redirect_to_indexpage]

  def redirect_to_frontpage
    redirect_to :controller => 'page', :action => 'view', :type => h(Raki.frontpage[:type]), :id => h(Raki.frontpage[:page])
  end
  
  def redirect_to_indexpage
    redirect_to :controller => 'page', :action => 'view', :type => h(params[:type]), :id => h(Raki.index_page)
  end

  def view
    return if render_forbidden_if_not_authorized :view
    if page_exists? @type, @page, @revision
      session[:visited_pages].unshift({:type => @type, :page => @page})
      session[:visited_pages].uniq!
      session[:visited_pages].slice! 0, VISITED_LIMIT if session[:visited_pages].size > 10
      current_revision = page_revisions(@type, @page).first
      @page_info = {
        :date => current_revision.date,
        :user => current_revision.user,
        :version => current_revision.version,
        :type => @type,
        :id => @page
      } unless current_revision.nil?
      respond_to do |format|
        format.html
        format.atom { @revisions = page_revisions(@type, @page)[0..FEED_LIMIT] }
        format.src { render :inline => page_contents(@type, @page, @revision), :content_type => 'text/plain' }
      end
    end
  end

  def info
    return if redirect_if_not_authorized :view
    return if redirect_if_page_not_exists
    @revisions = page_revisions @type, @page
  end

  def edit
    unless (page_exists?(@type, @page) && authorized?(@type, @page, :edit) ||
        !page_exists?(@type, @page) && authorized?(@type, @page, :create) ||
        authorized?(@type, @page, :rename) ||
        authorized?(@type, @page, :delete))
      render 'common/forbidden'
      return
    end
    if params[:content].nil?
      begin
        @content = page_contents @type, @page, @revision
      rescue => e
        @content = ''
      end
    else
      @content = params[:content]
      @preview = @content
    end
  end

  def update
    if (!page_exists?(@type, @page) && !authorized?(@type, @page, :create) ||
        page_exists?(@type, @page) && !authorized?(@type, @page, :edit))
      render 'common/forbidden'
      return
    end
    page_save @type, @page, params[:content], params[:message]
    redirect_to :controller => 'page', :action => 'view', :type => h(@type), :id => h(@page)
  end

  def rename
    return if render_forbidden_if_not_authorized :rename
    return if redirect_if_page_not_exists
    parts = params[:name].split '/', 2
    if parts.length == 2
      new_type = parts[0]
      new_page = parts[1]
    else
      new_type = @type
      new_page = parts[0]
    end
    unless authorized? new_type, new_page, :create
      flash[:notice] = t 'page.edit.no_permission_to_create'
      redirect_to :controller => 'page', :action => 'edit', :type => h(@type), :id => h(@page)
      return
    end
    unless page_exists? new_type, new_page
      page_rename @type, @page, new_type, new_page
      redirect_to :controller => 'page', :action => 'view', :type => h(new_type), :id => h(new_page)
    else
      flash[:notice] = t 'page.edit.page_already_exists'
      redirect_to :controller => 'page', :action => 'edit', :type => h(@type), :id => h(@page)
    end
  end

  def delete
    if @attachment.nil?
      return if render_forbidden_if_not_authorized :delete
      return if redirect_if_page_not_exists
      page_delete @type, @page
      redirect_to :controller => 'page', :type => h(Raki.frontpage[:type]), :id => h(Raki.frontpage[:page])
    else
      return if render_forbidden_if_not_authorized :delete
      return if redirect_if_attachment_not_exists
      attachment_delete @type, @page, @attachment
      redirect_to :controller => 'page', :action => 'attachments', :type => h(@type), :id => h(@page)
    end
  end

  def attachments
    return if redirect_if_not_authorized :view
    return if redirect_if_page_not_exists
    @attachments = []
    attachment_all(@type, @page).each do |attachment|
      @attachments << {
        :name => attachment,
        :revision => attachment_revisions(@type, @page, attachment).first
      }
    end
    @attachments.sort { |a,b| a[:name] <=> b[:name] }
  end

  def attachment_upload
    return if render_forbidden_if_not_authorized :upload
    return if redirect_if_page_not_exists
    attachment_save(
      @type,
      @page,
      File.basename(params[:attachment_upload].original_filename),
      params[:attachment_upload].read,
      params[:message]
    )
    redirect_to :controller => 'page', :action => 'attachments', :type => h(@type), :id => h(@page)
  end

  def attachment
    return if redirect_if_not_authorized :view
    return if redirect_if_attachment_not_exists
    # ugly fix for ruby1.9 and rails2.5
    revision = @revision
    revision = attachment_revisions(@type, @page, @attachment).first.id if revision.nil?
    unless File.exists? "#{Rails.root}/tmp/attachments/#{@type}/#{@page}/#{revision}/#{@attachment}"
      FileUtils.mkdir_p "#{Rails.root}/tmp/attachments/#{@type}/#{@page}/#{revision}"
      File.open "#{Rails.root}/tmp/attachments/#{@type}/#{@page}/#{revision}/#{@attachment}", 'w' do |f|
        f.write(attachment_contents(@type, @page, @attachment, revision))
      end
    end
    send_file "#{Rails.root}/tmp/attachments/#{@type}/#{@page}/#{revision}/#{@attachment}"
  end
  
  def attachment_info
    return if redirect_if_not_authorized :view
    return if redirect_if_attachment_not_exists
    @revisions = attachment_revisions @type, @page, @attachment
  end
  
  def diff
    return if redirect_if_not_authorized :view
    return if redirect_if_page_not_exists
    @diff = page_diff @type, @page, @revision_from, @revision_to
  end

  private

  def common_init
    @type = params[:type].to_sym
    @page = params[:id]
    @revision = params[:revision]
    @revision_from = params[:revision_from]
    @revision_to = params[:revision_to]
    @attachment = params[:attachment]
    @title = "#{@type}/#{@page}"
    
    @context[:type] = @type
    @context[:page] = @page
    @context[:real_type] = @type
    @context[:real_page] = @page
  end
  
  def render_forbidden_if_not_authorized action
    unless authorized? @type, @page, action
      render 'common/forbidden'
      return true
    end
    false
  end

  def redirect_if_not_authorized action
    unless authorized? @type, @page, action
      redirect_to :controller => 'page', :action => 'view', :type => h(@type), :id => h(@page)
      return true
    end
    false
  end

  def redirect_if_page_not_exists
    unless page_exists? @type, @page, @revision
      redirect_to :controller => 'page', :action => 'view', :type => h(@type), :id => h(@page)
      return true
    end
    false
  end

  def redirect_if_attachment_not_exists
    unless attachment_exists? @type, @page, @attachment
      redirect_to :controller => 'page', :action => 'attachments', :type => h(@type), :id => h(@page)
      return true
    end
    false
  end

end
