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

class FeedController < ApplicationController
  LIMIT = 15
  
  def global
    @revisions = Page.changes(:limit => LIMIT)
    @revisions += Attachment.changes(:limit => LIMIT)
    
    @revisions.delete_if{|r| !r.page.authorized?(User.current, :view)}
    
    @revisions = @revisions.sort {|a,b| b.date <=> a.date}
    @revisions = @revisions[0..LIMIT]
    
    respond_to do |format|
      format.atom
    end
  end
  
  def namespace
    @namespace = params[:namespace]
    
    @revisions = Page.changes(:namespace => @namespace, :limit => LIMIT)
    @revisions += Attachment.changes(:namespace => @namespace, :limit => LIMIT)
    
    @revisions.delete_if{|r| !r.page.authorized?(User.current, :view)}
    
    @revisions = @revisions.sort {|a,b| b.date <=> a.date}
    @revisions = @revisions[0..LIMIT]
    
    respond_to do |format|
      format.atom
    end
  end
  
  def page
    @page = Page.find(params[:namespace], params[:page])
    unless @page
      render :nothing => true, :status => :not_found
      return
    end
    render :nothing => true, :status => :forbidden unless @page.authorized?(User.current, :view)
    
    @revisions = @page.revisions
    @revisions += Attachment.changes(:namespace => @page.namespace, :page => @page.name, :limit => LIMIT)
    
    @revisions = @revisions.sort {|a,b| b.date <=> a.date}
    @revisions = @revisions[0..LIMIT]
    
    respond_to do |format|
      format.atom
    end
  end
  
end
