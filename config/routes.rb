# Raki - extensible rails-based wiki
# Copyright (C) 2011 Florian Schwab & Martin Sigloch
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

Raki::Application.routes.draw do
  
  # Authentication
  match 'login' => 'authentication#login', :as => :login
  match 'logout' => 'authentication#logout', :as => :logout
  match 'login_callback' => 'authentication#callback', :as => :login_callback
  
  # Route for atom feed
  get 'feed.atom' => 'feed#global', :as => :feed_global
    
  # Route for preview
  post 'preview' => 'page#live_preview'
    
  # Route for unlock
  post 'unlock' => 'page#unlock'
  
  # Routes for wiki pages and attachments
  scope ':namespace', :constraints => {:namespace => /[^\/\.]+/} do
    scope '/:page', :constraints => {:page => /[^\/\.]+|\d+\.\d+\.\d+\.\d+/} do
      get '/info' => 'page#info'
      get '/diff/:revision_from/:revision_to' => 'page#diff'
      get '/diff' => 'page#diff'
      get '/edit' => 'page#edit'
      post '/preview' => 'page#preview'
      post '/update' => 'page#update'
      post '/rename' => 'page#rename'
      post '/delete' => 'page#delete'
      
      scope '/attachment/:attachment', :constraints => {:attachment => /[^\/]+/} do
        get '/info' => 'page#attachment_info'
        post '/delete' => 'page#attachment_delete'
        get '/:revision' => 'page#attachment'
      end
      get '/attachment/:attachment' => 'page#attachment'
      
      get '/attachments' => 'page#attachments'
      post '/attachment_upload' => 'page#attachment_upload'
      get '/:revision' => 'page#view'
      get '.atom' => 'feed#page', :as => :feed_page
    end
    get '/:page' => 'page#view'
  end
  get ':namespace' => 'page#redirect_to_indexpage'
  get ':namespace.atom' => 'feed#namespace', :as => :feed_namespace
  
  # Root
  root :to => 'page#redirect_to_frontpage'
end
