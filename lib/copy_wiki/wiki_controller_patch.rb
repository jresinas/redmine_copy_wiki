require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

# Patches Redmine's Issue dynamically.
module CopyWiki
  module WikiControllerPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will be reloaded in development
        #skip_filter :authorize, :only => [:copy]
        before_filter :find_existing_page, :only => [:rename, :protect, :history, :diff, :annotate, :add_attachment, :destroy, :destroy_version, :copy]
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      # rename a page
      def copy
        return render_403 unless editable?
        #@projects = Project.all.map{|p| [p.id, p.name] if p.wiki.present? and p.id != @project.id}
        @projects = Project.all.select{|p| p.id != @project.id and p.wiki.present? and p.wiki.pages.length > 0}
      end
    end
  end
end

if Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    # use require_dependency if you plan to utilize development mode
    require_dependency 'projects_controller'
    WikiController.send(:include, CopyWiki::WikiControllerPatch)
  end
else
  Dispatcher.to_prepare do
    require_dependency 'projects_controller'
    WikiController.send(:include, CopyWiki::WikiControllerPatch)
  end
end
