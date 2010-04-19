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
  
  # Authentication
  map.signin 'login', :controller => 'authentication', :action => 'login'
  map.signout 'logout', :controller => 'authentication', :action => 'logout'

  # Root
  map.root :controller => 'page', :action => 'view', :page => Raki.frontpage

end
