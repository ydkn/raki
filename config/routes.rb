ActionController::Routing::Routes.draw do |map|
  
  # Routes for wiki pages
  map.connect 'wiki', :controller => 'page', :action => 'redirect_to_frontpage'
  map.connect 'wiki/:id/info', :controller => 'page', :action => 'info'
  map.connect 'wiki/:id/info.:format', :controller => 'page', :action => 'info'
  map.connect 'wiki/:id/edit', :controller => 'page', :action => 'edit'
  map.connect 'wiki/:id/update', :controller => 'page', :action => 'update', :conditions => { :method => :post }
  map.connect 'wiki/:id/rename', :controller => 'page', :action => 'rename', :conditions => { :method => :post }
  map.connect 'wiki/:id/delete', :controller => 'page', :action => 'delete'
  map.connect 'wiki/:id/attachment/*attachment', :controller => 'page', :action => 'attachment'
  map.connect 'wiki/:id/attachments', :controller => 'page', :action => 'attachments'
  map.connect 'wiki/:id/attachment_upload', :controller => 'page', :action => 'attachment_upload'
  map.connect 'wiki/:id/:revision', :controller => 'page', :action => 'view'
  map.connect 'wiki/:id/:revision.:format', :controller => 'page', :action => 'view'
  map.connect 'wiki/:id', :controller => 'page', :action => 'view'
  map.connect 'wiki/:id.:format', :controller => 'page', :action => 'view'

  # Routes for user pages
  map.connect 'user', :controller => 'user_page', :action => 'redirect_to_userpage'
  map.connect 'user/:id/info', :controller => 'user_page', :action => 'info'
  map.connect 'user/:id/info.:format', :controller => 'user_page', :action => 'info'
  map.connect 'user/:id/edit', :controller => 'user_page', :action => 'edit'
  map.connect 'user/:id/update', :controller => 'user_page', :action => 'update', :conditions => { :method => :post }
  map.connect 'user/:id/attachment/*attachment', :controller => 'user_page', :action => 'attachment'
  map.connect 'user/:id/attachments', :controller => 'user_page', :action => 'attachments'
  map.connect 'user/:id/attachment_upload', :controller => 'user_page', :action => 'attachment_upload'
  map.connect 'user/:id/:revision', :controller => 'user_page', :action => 'view'
  map.connect 'user/:id/:revision.:format', :controller => 'user_page', :action => 'view'
  map.connect 'user/:id', :controller => 'user_page', :action => 'view'
  map.connect 'user/:id.:format', :controller => 'user_page', :action => 'view'
  
  # Authentication
  map.signin 'login', :controller => 'authentication', :action => 'login'
  map.signout 'logout', :controller => 'authentication', :action => 'logout'
  map.connect 'login_callback', :controller => 'authentication', :action => 'callback'

  # Root
  map.root :controller => 'page', :action => 'view', :id => Raki.frontpage

end
