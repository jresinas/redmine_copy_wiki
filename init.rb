require 'copy_wiki/project_patch'
require 'copy_wiki/projects_controller_patch'
require 'copy_wiki/wiki_controller_patch'

Redmine::Plugin.register :redmine_copy_wiki do
  name 'Copy Wiki'
  author 'jresinas'
  description 'This plugin allows to copy wiki content to another projects.'
  version '0.0.1'

	permission :copy_wiki, { :wiki => [:copy], :projects => [:copy_wiki] }
  requires_redmine_plugin :redmine_base_deface, :version_or_higher => '0.0.1'
end
