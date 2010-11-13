# Raki - extensible rails-based wiki
# Copyright (C) 2010 Florian Schwab & Martin Sigloch
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

module Raki
  module Helpers
    
    module ProviderHelper
      
      include AuthorizationHelper
      
      def provider(namespace)
        Raki::Provider[namespace]
      end

      def page_exists?(namespace, name, revision=nil)
        provider(namespace).page_exists?(namespace, name, revision)
      end

      def page_exists!(namespace, name, revision, user=User.current)
        authorized!(namespace, name, :view, user)
        page_exists?(namespace, name, revision)
      end

      def page_contents(namespace, name, revision=nil)
        provider(namespace).page_contents(namespace, name, revision)
      end

      def page_contents!(namespace, name, revision=nil, user=User.current)
        authorized!(namespace, name, :view, user)
        page_contents(namespace, name, revision)
      end

      def page_revisions(namespace, name)
        provider(namespace).page_revisions(namespace, name)
      end

      def page_revisions!(namespace, name, user=User.current)
        authorized!(namespace, name, :view, user)
        page_revisions(namespace, name)
      end

      def page_save(namespace, name, contents, message, user=User.current)
        provider(namespace).page_save(namespace, name, contents, message, user)
        nil
      end

      def page_save!(namespace, name, contents, message, user=User.current)
        if page_exists?(namespace, name)
          authorized!(namespace, name, :edit, user)
        else
          authorized!(namespace, name, :create, user)
        end
        page_save(namespace, name, contents, message, user)
        nil
      end

      def page_rename(old_namespace, old_name, new_namespace, new_name, user=User.current)
        if provider(old_namespace) == provider(new_namespace)
          provider(old_namespace).page_rename(old_namespace, old_name, new_namespace, new_name, user)
        else
          contents = page_contents(old_namespace, old_name)
          page_delete(old_namespace, old_name, user)
          page_save(new_namespace, new_name, contents, "#{old_namespace.to_s}/#{old_name.to_s} ==> #{new_namespace.to_s}/#{new_name.to_s}", user)
        end
        nil
      end

      def page_rename!(old_namespace, old_name, new_namespace, new_name, user=User.current)
        authorized!(old_namespace, old_name, :rename, user)
        authorized!(new_namespace, new_name, :create, user)
        page_rename(old_namespace, old_name, new_namespace, new_name, user)
        nil
      end

      def page_delete(namespace, name, user=User.current)
        provider(namespace).page_delete(namespace, name, user)
        nil
      end

      def page_delete!(namespace, name, user=User.current)
        authorized!(namespace, name, :delete, user)
        page_delete(namespace, name, user)
        nil
      end

      def page_all(namespace)
        provider(namespace).page_all(namespace)
      end

      def page_all!(namespace, user=User.current)
        page_all(namespace).select do |page|
          authorized?(namespace, page, :view, user)
        end
      end

      def page_changes(namespace, options={})
        if options.is_a?(Fixnum)
          options = {:limit => options}
        elsif options.is_a?(Date)
          options = {:since => options}
        end
        provider(namespace).page_changes(namespace, options)
      end

      def page_changes!(namespace, options={}, user=User.current)
        page_changes(namespace, options).select do |change|
          authorized?(change.namespace, change.page, :view, user)
        end
      end

      def page_diff(namespace, page, revision_from=nil, revision_to=nil)
        provider(namespace).page_diff(namespace, page, revision_from, revision_to)
      end

      def page_diff!(namespace, page, revision_from=nil, revision_to=nil, user=User.current)
        authorized!(namespace, page, :view, user)
        page_diff(namespace, page, revision_from, revision_to)
      end

      def attachment_exists?(namespace, page, name, revision=nil)
        provider(namespace).attachment_exists?(namespace, page, name, revision)
      end

      def attachment_exists!(namespace, page, name, revision=nil, user=User.current)
        authorized!(namespace, page, :view, user)
        attachment_exists?(namespace, page, name, revision)
      end

      def attachment_contents(namespace, page, name, revision=nil)
        provider(namespace).attachment_contents(namespace, page, name, revision)
      end

      def attachment_contents!(namespace, page, name, revision=nil, user=User.current)
        authorized!(namespace, page, :view, user)
        attachment_contents(namespace, page, name, revision)
      end

      def attachment_revisions(namespace, page, name)
        provider(namespace).attachment_revisions(namespace, page, name)
      end

      def attachment_revisions!(namespace, page, name, user=User.current)
        authorized!(namespace, page, :view, user)
        attachment_revisions(namespace, page, name)
      end

      def attachment_save(namespace, page, name, contents, message, user=User.current)
        provider(namespace).attachment_save(namespace, page, name, contents, message, user)
        nil
      end

      def attachment_save!(namespace, page, name, contents, message, user=User.current)
        if attachment_exists?(namespace, page, name)
          authorized!(namespace, page, :edit, user)
        else
          authorized!(namespace, page, :create, user)
        end
        attachment_save(namespace, page, name, contents, message, user)
        nil
      end

      def attachment_delete(namespace, page, name, user=User.current)
        provider(namespace).attachment_delete(namespace, page, name, user)
        nil
      end

      def attachment_delete!(namespace, page, name, user=User.current)
        authorized!(namespace, page, :delete, user)
        attachment_delete(namespace, page, name, user)
        nil
      end

      def attachment_all(namespace, page)
        provider(namespace).attachment_all(namespace, page)
      end

      def attachment_all!(namespace, page, user=User.current)
        authorized!(namespace, page, :view, user)
        attachment_all(namespace, page)
      end

      def attachment_changes(namespace, page=nil, options={})
        if options.is_a?(Fixnum)
          options = {:limit => options}
        elsif options.is_a?(Date)
          options = {:since => options}
        end
        provider(namespace).attachment_changes(namespace, page, options)
      end

      def attachment_changes!(namespace, page=nil, options={}, user=User.current)
        attachment_changes(namespace, page, options).select do |change|
          authorized?(change.namespace, change.page, :view, user)
        end
      end

      def namespaces
        namespaces = []
        Raki::Provider.used.values.each do |provider|
          provider.namespaces.each do |namespace|
            namespaces << namespace if provider(namespace) == provider
          end
        end
        namespaces
      end

    end
    
  end
end
