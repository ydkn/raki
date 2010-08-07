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
  
  before_filter :common_init, :except => :redirect_to_frontpage

  def redirect_to_frontpage
    redirect_to :controller => 'page', :action => 'view', :type => :page, :id => Raki.frontpage
  end

  def view
    return if render_forbidden_if_not_authorized :view
    if @provider.page_exists?(@type, @page, @revision)
      current_revision = @provider.page_revisions(@type, @page).first
      @page_info = {
        :date => current_revision.date,
        :user => current_revision.user,
        :version => current_revision.version,
        :type => @type,
        :id => @page
      } unless current_revision.nil?
      respond_to do |format|
        format.html
        format.atom { @revisions = @provider.page_revisions(@type, @page) }
        format.src { render :inline => @provider.page_contents(@type, @page, @revision), :content_type => 'text/plain' }
      end
    end
  end

  def info
    return if redirect_if_not_authorized :view
    return if redirect_if_page_not_exists
    @revisions = @provider.page_revisions @type, @page
  end

  def edit
    unless (@provider.page_exists?(@type, @page) && Raki::Permission.to?(@type, @page, :edit, User.current) ||
        !@provider.page_exists?(@type, @page) && Raki::Permission.to?(@type, @page, :create, User.current) ||
        Raki::Permission.to?(@type, @page, :rename, User.current) ||
        Raki::Permission.to?(@type, @page, :delete, User.current))
      render 'common/forbidden'
      return
    end
    if params[:content].nil?
      begin
        @content = @provider.page_contents(@type, @page, @revision)
      rescue => e
        @content = ''
      end
    else
      @content = params[:content]
      @preview = @content
    end
  end

  def update
    if (!@provider.page_exists?(@type, @page) && !Raki::Permission.to?(@type, @page, :create, User.current) ||
        @provider.page_exists?(@type, @page) && !Raki::Permission.to?(@type, @page, :edit, User.current))
      render 'common/forbidden'
      return
    end
    @provider.page_save @type, @page, params[:content], params[:message], User.current
    redirect_to :controller => 'page', :action => 'view', :id => @page
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
    unless Raki::Permission.to?(new_type, new_page, :create, User.current)
      flash[:notice] = t 'page.edit.no_permission_to_create'
      redirect_to :controller => 'page', :action => 'edit', :type => @type, :id => @page
      return
    end
    unless @provider.page_exists? new_type, new_page
      @provider.page_rename @type, @page, new_type, new_page, User.current
      redirect_to :controller => 'page', :action => 'view', :type => new_type, :id => new_page
    else
      flash[:notice] = t 'page.edit.page_already_exists'
      redirect_to :controller => 'page', :action => 'edit', :type => @type, :id => @page
    end
  end

  def delete
    return if render_forbidden_if_not_authorized :delete
    return if redirect_if_page_not_exists
    @provider.page_delete @type, @page, User.current
    redirect_to :controller => 'page', :action => 'info', :id => Raki.frontpage
  end

  def attachments
    return if redirect_if_not_authorized :view
    return if redirect_if_page_not_exists
    @attachments = []
    @provider.attachment_all(@type, @page).each do |attachment|
      @attachments << {
        :name => attachment,
        :revision => @provider.attachment_revisions(@type, @page, attachment).first
      }
    end
    @attachments.sort { |a,b| a[:name] <=> b[:name] }
  end

  def attachment_upload
    return if render_forbidden_if_not_authorized :upload
    return if redirect_if_page_not_exists
    @provider.attachment_save(
      @type,
      @page,
      File.basename(params[:attachment_upload].original_filename),
      params[:attachment_upload].read,
      params[:message],
      User.current
    )
    redirect_to :controller => 'page', :action => 'attachments', :type => @type, :id => @page
  end

  def attachment
    return if redirect_if_not_authorized :view
    return if redirect_if_attachment_not_exists
    # ugly fix for ruby1.9 and rails2.5
    revision = @revision
    revision = @provider.attachment_revisions(@type, @page, @attachment).first.id if revision.nil?
    unless File.exists? "#{Rails.root}/tmp/attachments/#{@type}/#{@page}/#{revision}/#{@attachment}"
      FileUtils.mkdir_p "#{Rails.root}/tmp/attachments/#{@type}/#{@page}/#{revision}"
      File.open "#{Rails.root}/tmp/attachments/#{@type}/#{@page}/#{revision}/#{@attachment}", 'w' do |f|
        f.write(@provider.attachment_contents(@type, @page, @attachment, revision))
      end
    end
    send_file "#{Rails.root}/tmp/attachments/#{@type}/#{@page}/#{revision}/#{@attachment}"
  end
  
  def attachment_info
    return if redirect_if_not_authorized :view
    return if redirect_if_attachment_not_exists
    @revisions = @provider.attachment_revisions @type, @page, @attachment
  end
  
  def diff
    return if redirect_if_not_authorized :view
    return if redirect_if_page_not_exists
    @diff = @provider.page_diff(@type, @page, @revision_from, @revision_to)
  end

  private

  def common_init
    @type = params[:type].to_sym
    @page = params[:id]
    @revision = params[:revision]
    @revision_from = params[:revision_from]
    @revision_to = params[:revision_to]
    @attachment = params[:attachment]
    @provider = Raki::Provider[@type]
    @title = @page
    
    @context[:type] = @type
    @context[:page] = @page
    @context[:real_type] = @type
    @context[:real_page] = @page
  end
  
  def render_forbidden_if_not_authorized(action)
    unless Raki::Permission.to?(@type, @page, action, User.current)
      render 'common/forbidden'
      return true
    end
    false
  end

  def redirect_if_not_authorized(action)
    unless Raki::Permission.to?(@type, @page, action, User.current)
      redirect_to :controller => 'page', :action => 'view', :type => @type, :id => @page
      return true
    end
    false
  end

  def redirect_if_page_not_exists
    unless @provider.page_exists?(@type, @page, @revision)
      redirect_to :controller => 'page', :action => 'view', :type => @type, :id => @page
      return true
    end
    false
  end

  def redirect_if_attachment_not_exists
    unless @provider.attachment_exists?(@type, @page, @attachment)
      redirect_to :controller => 'page', :action => 'attachments', :type => @type, :id => @page
      return true
    end
    false
  end

end
