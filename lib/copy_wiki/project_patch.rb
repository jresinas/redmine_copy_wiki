require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

module CopyWiki
  unloadable
  module ProjectPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will be reloaded in development
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def copy_wiki_from(project)
        # Si la wiki actual tiene páginas, mergeamos las wikis
        # Si no, copiamos la wiki tal cual
        if wiki.present? and wiki.pages.present?
          actual_wiki_pages = wiki.pages.map{|p| {p.title => p.id}}.reduce(Hash.new, :merge)
          remote_wiki_pages = project.wiki.pages.map{|p| {p.title => p.id}}.reduce(Hash.new, :merge)

          # obtenemos raiz del proyecto actual y de project
          root = wiki.find_page(nil)
          remote_root = project.wiki.find_page(nil)

          # traemos wiki de project
          copy_wiki(project)

          # identificamos la copia creada de la página raiz de project
          copy_new_remote_root = wiki.pages.select{|p| p.id.blank? and p.title == remote_root.title}.first

          # Mantenemos página raíz original
          wiki.start_page = root.title
          wiki.save


          mapping_title = {}
          # por cada página nueva, la renombramos si es necesario y mapeamos su nombre final con el original
          wiki.pages.reject{|p| actual_wiki_pages.values.include?(p.id)}.each do |wp|
            original_title = wp.title
            i = 0
            while actual_wiki_pages.keys.include?(wp.title)
              i += 1
              wp.title = original_title+'_'+i.to_s
            end
            wp.save

            mapping_title[original_title] = wp.title
          end

          wiki.pages.reject{|p| actual_wiki_pages.values.include?(p.id)}.each do |wp|
            # guardamos para que se actualice su parent_id correctamente
            wp.save

            # Sustituimos los parent_id que apuntan a la copia de la raíz de project para que apunten a la raíz del proyecto actual
            if wp.parent_id.present? and copy_new_remote_root.present? and wp.parent_id == copy_new_remote_root.id
              wp.parent_id = root.id
            end
            wp.save

            # Actualizamos los enlaces en el contenido de las páginas nuevas
            wpc = wp.content
            wpc.text.scan(/\[\[([^[\||\]]]*)\|[^[\||\]]]*\]\]/).flatten.uniq.each do |var|
              if mapping_title.keys.include?(Wiki.titleize(var))
                wpc.text = wpc.text.gsub("[["+var+"|", "[["+mapping_title[Wiki.titleize(var)]+"|")
              end
            end

            wpc.text.scan(/\[\[([^[\||\]]]*)\]\]/).flatten.uniq.each do |var|
              if mapping_title.keys.include?(Wiki.titleize(var))
                wpc.text = wpc.text.gsub("[["+var+"]]", "[["+mapping_title[Wiki.titleize(var)]+"|"+var+"]]")
              end
            end          

            wpc.save
          end

          if root.content.present? and copy_new_remote_root.content.present?
            # mergeamos el contenido de la raiz del proyecto actual con el de la raiz de project
            root.content.text += "\r\n\r\n-- Project #{project.name} wiki content\r\n\r\n" + copy_new_remote_root.content.text
            root.content.save

            # eliminamos la copia de la página raíz de project
            copy_new_remote_root.destroy
          end
        else
          copy_wiki(project)
        end
      end
    end
  end
end

if Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    require_dependency 'project'
    Project.send(:include, CopyWiki::ProjectPatch)
  end
else
  Dispatcher.to_prepare do
    require_dependency 'project'
    Project.send(:include, CopyWiki::ProjectPatch)
  end
end
