ActionController::Routing::Routes.draw do |map|
  
  # Routes for wiki pages
  map.connect 'wiki/:page/info', :controller => 'page', :action => 'info'
  map.connect 'wiki/:page/edit', :controller => 'page', :action => 'edit'
  map.connect 'wiki/:page/update', :controller => 'page', :action => 'update', :conditions => { :method => :post }
  map.connect 'wiki/:page/rename', :controller => 'page', :action => 'rename', :conditions => { :method => :post }
  map.connect 'wiki/:page/delete', :controller => 'page', :action => 'delete'
  map.connect 'wiki/:page/:revision', :controller => 'page', :action => 'view'
  map.connect 'wiki/:page', :controller => 'page', :action => 'view'
  map.connect 'wiki' , :controller => 'page', :action => 'redirect_to_frontpage'

  # Routes for user pages
  map.connect 'user/:user/info', :controller => 'user_page', :action => 'info'
  map.connect 'user/:user/edit', :controller => 'user_page', :action => 'edit'
  map.connect 'user/:user/update', :controller => 'user_page', :action => 'update', :conditions => { :method => :post }
  map.connect 'user/:user/:revision', :controller => 'user_page', :action => 'view'
  map.connect 'user/:user', :controller => 'user_page', :action => 'view'
  map.connect 'user', :controller => 'user_page', :action => 'redirect_to_userpage'
  
  # Authentication
  map.signin 'login', :controller => 'authentication', :action => 'login'
  map.signout 'logout', :controller => 'authentication', :action => 'logout'
  map.connect 'login_callback', :controller => 'authentication', :action => 'callback'

  # Root
  map.root :controller => 'page', :action => 'view', :page => Raki.frontpage

end
