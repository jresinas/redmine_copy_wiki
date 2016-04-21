require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

# Patches Redmine's Issue dynamically.
module CopyWiki
  module ProjectsControllerPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will be reloaded in development
        #skip_filter :authorize, :only => [:copy_wiki]
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def copy_wiki
        remote_project = Project.find(params[:project])
        if remote_project.present?
          @project.copy_wiki_from(remote_project)
        end

        redirect_to project_wiki_page_path(@project, @project.wiki.start_page)
      end
    end
  end
end

if Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    # use require_dependency if you plan to utilize development mode
    require_dependency 'projects_controller'
    ProjectsController.send(:include, CopyWiki::ProjectsControllerPatch)
  end
else
  Dispatcher.to_prepare do
    require_dependency 'projects_controller'
    ProjectsController.send(:include, CopyWiki::ProjectsControllerPatch)
  end
end
