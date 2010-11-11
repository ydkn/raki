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

ActionController::Routing::Routes.draw do |map|
  
  # Root
  map.root :controller => 'page', :action => 'redirect_to_frontpage'

  # Authentication
  map.signin  'login', :controller => 'authentication', :action => 'login'
  map.signout 'logout', :controller => 'authentication', :action => 'logout'
  map.connect 'login_callback', :controller => 'authentication', :action => 'callback'
  
  # Route for atom feed
  map.connect 'feed.atom', :controller => 'feed', :action => 'feed'

  # Routes for wiki pages
  map.connect ':type', :controller => 'page', :action => 'redirect_to_indexpage'
  map.with_options :controller => 'page', :requirements => {:id => /[^\/\.]+|\d+\.\d+\.\d+\.\d+/} do |page|
    page.connect ':type/:id/info', :action => 'info'
    page.connect ':type/:id/diff/:revision_from/:revision_to', :action => 'diff'
    page.connect ':type/:id/diff', :action => 'diff'
    page.connect ':type/:id/edit', :action => 'edit'
    page.connect ':type/:id/update', :action => 'update', :conditions => { :method => :post }
    page.connect ':type/:id/rename', :action => 'rename', :conditions => { :method => :post }
    page.connect ':type/:id/delete', :action => 'delete'
    page.with_options :requirements => {:attachment => /[^\/]+/} do |attachment|
      attachment.connect ':type/:id/attachment/:attachment', :action => 'attachment'
      attachment.connect ':type/:id/attachment/:attachment/info', :action => 'attachment_info'
      attachment.connect ':type/:id/attachment/:attachment/delete', :action => 'delete'
      attachment.connect ':type/:id/attachment/:attachment/:revision', :action => 'attachment'
    end
    page.connect ':type/:id/attachments', :action => 'attachments'
    page.connect ':type/:id/attachment_upload', :action => 'attachment_upload', :conditions => { :method => :post }
    page.connect ':type/:id/:revision', :action => 'view'
    page.connect ':type/:id.:format', :action => 'view'
    page.connect ':type/:id', :action => 'view'
  end

end
