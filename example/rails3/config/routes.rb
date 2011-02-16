
Rails3::Application.routes.draw do
  root :controller => 'application', :action => 'index'
  match ':action', :controller => 'application'
end
