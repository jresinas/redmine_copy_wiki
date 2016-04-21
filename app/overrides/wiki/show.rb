Deface::Override.new :virtual_path  => 'wiki/show',
                     :name          => 'copy-wiki',
                     :original		=> '90a37f7f1b8305a8ebcc1bf55bf8ca96d91beec8',
                     :insert_before	=> "erb[loud]:contains('watcher_link(@page, User.current)')",
                     :text			=> "<%= link_to(l(:button_copy), {:action => 'copy', :id => @page.title}, :class => 'icon icon-copy', :accesskey => accesskey(:copy)) if User.current.allowed_to?(:copy_wiki, @project) %>"
