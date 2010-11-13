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
  map.connect 'feed.atom', :controller => 'feed', :action => 'global'

  # Routes for wiki pages
  map.connect ':namespace', :controller => 'page', :action => 'redirect_to_indexpage'
  map.connect ':namespace.atom', :controller => 'feed', :action => 'namespace'
  map.with_options :controller => 'page', :requirements => {:page => /[^\/\.]+|\d+\.\d+\.\d+\.\d+/} do |page|
    page.connect ':namespace/:page/info', :action => 'info'
    page.connect ':namespace/:page/diff/:revision_from/:revision_to', :action => 'diff'
    page.connect ':namespace/:page/diff', :action => 'diff'
    page.connect ':namespace/:page/edit', :action => 'edit'
    page.connect ':namespace/:page/update', :action => 'update', :conditions => { :method => :post }
    page.connect ':namespace/:page/rename', :action => 'rename', :conditions => { :method => :post }
    page.connect ':namespace/:page/delete', :action => 'delete'
    page.with_options :requirements => {:attachment => /[^\/]+/} do |attachment|
      attachment.connect ':namespace/:page/attachment/:attachment/info', :action => 'attachment_info'
      attachment.connect ':namespace/:page/attachment/:attachment/delete', :action => 'attachment_delete'
      attachment.connect ':namespace/:page/attachment/:attachment/:revision', :action => 'attachment'
      attachment.connect ':namespace/:page/attachment/:attachment', :action => 'attachment'
    end
    page.connect ':namespace/:page/attachments', :action => 'attachments'
    page.connect ':namespace/:page/attachment_upload', :action => 'attachment_upload', :conditions => { :method => :post }
    page.connect ':namespace/:page/:revision.:format', :action => 'view', :requirements => {:format => /src/}
    page.connect ':namespace/:page/:revision', :action => 'view'
    page.connect ':namespace/:page.atom', :controller => 'feed', :action => 'page'
    page.connect ':namespace/:page.:format', :action => 'view', :requirements => {:format => /src/}
    page.connect ':namespace/:page', :action => 'view'
  end

end
