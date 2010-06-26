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
  map.connect ':type', :controller => 'page', :action => 'redirect_to_frontpage'
  map.connect ':type/:id/info', :controller => 'page', :action => 'info'
  map.connect ':type/:id/edit', :controller => 'page', :action => 'edit'
  map.connect ':type/:id/update', :controller => 'page', :action => 'update', :conditions => { :method => :post }
  map.connect ':type/:id/rename', :controller => 'page', :action => 'rename', :conditions => { :method => :post }
  map.connect ':type/:id/delete', :controller => 'page', :action => 'delete'
  map.connect ':type/:id/attachment/:attachment', :controller => 'page', :action => 'attachment', :requirements => { :attachment => /[^\/]+/ }
  map.connect ':type/:id/attachment/:attachment/info', :controller => 'page', :action => 'attachment_info', :requirements => { :attachment => /[^\/]+/ }
  map.connect ':type/:id/attachment/:attachment/:revision', :controller => 'page', :action => 'attachment', :requirements => { :attachment => /[^\/]+/ }
  map.connect ':type/:id/attachments', :controller => 'page', :action => 'attachments'
  map.connect ':type/:id/attachment_upload', :controller => 'page', :action => 'attachment_upload'
  map.connect ':type/:id/:revision', :controller => 'page', :action => 'view'
  map.connect ':type/:id.:format', :controller => 'page', :action => 'view'
  map.connect ':type/:id', :controller => 'page', :action => 'view'

end
