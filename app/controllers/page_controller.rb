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
  VISITED_LIMIT = 8
  
  include ERB::Util
  
  before_filter :common_init, :except => [:redirect_to_frontpage, :redirect_to_indexpage, :live_preview]

  def redirect_to_frontpage
    redirect_to :controller => 'page', :action => 'view', :namespace => h(Raki.frontpage[:namespace]), :page => h(Raki.frontpage[:name])
  end
  
  def redirect_to_indexpage
    redirect_to :controller => 'page', :action => 'view', :namespace => h(params[:namespace]), :page => h(Raki.index_page)
  end

  def view
    if @page.authorized?(User.current, :view)
      session[:visited_pages].unshift({:namespace => @page.namespace, :page => @page.name})
      session[:visited_pages].uniq!
      session[:visited_pages].slice! 0, VISITED_LIMIT if session[:visited_pages].length > VISITED_LIMIT
      respond_to do |format|
        format.html { render 'view', :status => (@page.exists? ? 200 : 404) }
        format.src { render :inline => (@page.content || ''), :content_type => 'text/plain', :status => (@page.exists? ? 200 : 404) }
      end
    else
      render_forbidden
    end
  end

  def info
    redirect_to @page.url unless @page.authorized?(User.current, :view) && @page.exists?
  end

  def edit
    unless @page.exists? && @page.authorized?(User.current, :edit) ||
        @page.exists? && @page.authorized?(User.current, :create) ||
        @page.authorized?(User.current, :rename) ||
        @page.authorized?(User.current, :delete)
      render_forbidden
      return
    end
    @page.content = params[:content] if params[:content]
    @page.lock(User.current)
  end

  def update
    if !@page.exists? && !@page.authorized?(User.current, :create) ||
        @page.exists? && !@page.authorized?(User.current, :edit)
        render_forbidden
        return
    end
    
    @page.content = params[:content]
    
    if @page.save(User.current, params[:message])
      @page.unlock(User.current)
      redirect_to @page.url
    else
      render 'page/edit'
    end
  end

  def rename
    unless @page.authorized?(User.current, :rename)
      render_forbidden
      return
    end
    unless @page.exists?
      redirect_to @page.url
      return
    end
    
    parts = params[:name].split '/', 2
    if parts.length == 2
      @page.namespace = parts[0]
      @page.name = parts[1]
    else
      @page.name = parts[0]
    end
    
    if @page.save(User.current)
      @page.unlock(User.current)
      redirect_to @page.url
    else
      render 'page/edit'
    end
  end

  def delete
    unless @page.authorized?(User.current, :delete)
      render_forbidden
      return
    end
    unless @page.exists?
      redirect_to @page.url
      return
    end
    
    if @page.delete(User.current)
      @page.unlock(User.current)
      
      if session[:visited_pages]
        last_page = session[:visited_pages].select do |p|
          p[:namespace] != @page.namespace || p[:page] != @page.name
        end.collect do |p|
          Page.find(p[:namespace], p[:page])
        end.compact.first
        if last_page
          redirect_to last_page.url
          return
        end
      end
      redirect_to_frontpage
    else
      render 'page/edit'
    end
  end

  def attachments
    redirect_to @page.url unless @page.authorized?(User.current, :view) && @page.exists?
  end

  def attachment_upload
    unless @page.authorized?(User.current, :upload)
      render_forbidden
      return
    end
    unless @page.exists?
      redirect_to @page.url
      return
    end
    
    @attachment = Attachment.new :namespace => params[:namespace], :page => params[:page], :name => File.basename(params[:attachment_upload].original_filename)
    @attachment.content = params[:attachment_upload].read
    
    if @attachment.save(User.current, params[:message])
      redirect_to @page.url(:attachments)
    else
      # show errors
    end
  end

  def attachment
    unless @page.authorized?(User.current, :view)
      redirect_to @page.url
      return
    end
    unless @attachment.exists?
      redirect_to @page.url(:attachments)
      return
    end
    
    send_data @attachment.content, :filename => @attachment.name, :type => @attachment.mime_type
  end
  
  def attachment_info
    unless @page.authorized?(User.current, :view)
      redirect_to @page.url
      return
    end
    unless @attachment.exists?
      redirect_to @page.url(:attachments)
      return
    end
  end
  
  def attachment_delete
    unless @page.authorized?(User.current, :delete)
      render_forbidden
      return
    end
    unless @attachment.exists?
      redirect_to @page.url(:attachments)
      return
    end
    @attachment.delete(User.current)
    redirect_to @page.url(:attachments)
  end
  
  def diff
    unless @page.authorized?(User.current, :view) && @page.exists?
      redirect_to @page.url
      return
    end
    
    from = Page.find @page.namespace, @page.name, params[:revision_from]
    to = Page.find @page.namespace, @page.name, params[:revision_to]
    
    @diff = from.diff to.revision
  end
  
  def preview
    @page.content = params[:content]
    
    @page.lock User.current
  end
  
  def live_preview
    @context[:page] = Page.new(:namespace => params[:namespace], :name => params[:page])
    @context[:real_page] = @context[:page]
    
    render :inline => Raki::Parser[params[:namespace]].parse(params[:content], @context), :content_type => 'text/html'
  rescue => e
    render :nothing => true, :status => 500
  end
  
  def unlock
    @page.unlock User.current
    
    if request.get?
      redirect_to @page.url :view
    else
      render :nothing => true
    end
  end

  private

  def common_init
    @page = Page.find(params[:namespace], params[:page], params[:revision]) || Page.new(:namespace => params[:namespace], :name => params[:page])
    @attachment = Attachment.find(params[:namespace], params[:page], params[:attachment], params[:revision]) if params[:attachment]
    
    @title = "#{@page.namespace}/#{@page.name}"
    
    @context[:page] = @page
    @context[:real_page] = @page
  end

end
