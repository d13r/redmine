Redmine::Plugin.register :customisations do

  name "Dave's Customisations"
  author 'Dave James Miller'

  delete_menu_item :top_menu, :my_page

end
