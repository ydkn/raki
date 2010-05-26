ActionController::Routing::Routes.draw do |map|

  # Authentication
  map.signin  'login', :controller => 'authentication', :action => 'login'
  map.signout 'logout', :controller => 'authentication', :action => 'logout'
  map.connect 'login_callback', :controller => 'authentication', :action => 'callback'

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

  # Root
  map.root :controller => 'page', :action => 'redirect_to_frontpage'

end
