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
  module PluginHelpers
    
    class NotAuthorizedError < StandardError
    end
    
    def url?(url)
      !(url.match "^[a-zA-Z]+:\/\/(.+(:.+)?@)?[a-zA-Z0-9_-](\.[a-zA-Z0-9_-])*(:[0-9]+)?/").nil?
    end
    
    def page_exists?(type, name, revision=nil)
      Raki.provider(type).page_exists?(type, name, revision)
    end
    
    def page_exists!(type, name, revision, user=User.current)
      authorized!(type, name, :view, user)
      page_exists?(type, name, revision)
    end

    def page_contents(type, name, revision=nil)
      Raki.provider(type).page_contents(type, name, revision)
    end
    
    def page_contents!(type, name, revision=nil, user=User.current)
      authorized!(type, name, :view, user)
      page_contents(type, name, revision)
    end

    def page_revisions(type, name)
      Raki.provider(type).page_revisions(type, name)
    end
    
    def page_revisions!(type, name, user=User.current)
      authorized!(type, name, :view, user)
      page_revisions(type, name)
    end

    def page_save(type, name, contents, message, user=User.current)
      Raki.provider(type).page_save(type, name, contents, message, user)
    end
    
    def page_save!(type, name, contents, message, user=User.current)
      if page_exists?(type, name)
        authorized!(type, name, :edit, user)
      else
        authorized!(type, name, :create, user)
      end
      page_save(type, name, contents, message, user)
    end

    def page_rename(old_type, old_name, new_type, new_name, user=User.current)
      Raki.provider(type).page_rename(old_type, old_name, new_type, new_name, user)
    end
    
    def page_rename!(old_type, old_name, new_type, new_name, user=User.current)
      authorized!(old_type, old_name, :rename, user)
      authorized!(new_type, new_name, :create, user)
      page_rename(old_type, old_name, new_type, new_name, user)
    end

    def page_delete(type, name, user=User.current)
      Raki.provider(type).page_delete(type, name, user)
    end
    
    def page_delete!(type, name, user=User.current)
      authorized!(type, name, :delete, user)
      page_delete(type, name, user)
    end

    def page_all(type)
      Raki.provider(type).page_all(type)
    end
    
    def page_all!(type, user=User.current)
      page_all(type).select do |page|
        authorized?(type, page, :view, user)
      end
    end

    def page_changes(type, amount=0)
      Raki.provider(type).page_changes(type, amount)
    end
    
    def page_changes!(type, amount=0, user=User.current)
      changes = page_changes(type).select do |change|
        authorized?(change.type, change.page, :view, user)
      end
      changes = changes[0, amount] if amount > 0
      changes
    end
    
    def page_diff(type, page, revision_from=nil, revision_to=nil)
      Raki.provider(type).page_diff(type, page, revision_from, revision_to)
    end
    
    def page_diff!(type, page, revision_from=nil, revision_to=nil, user=User.current)
      authorized!(type, page, :view, user)
      page_diff(type, page, revision_from, revision_to)
    end

    def attachment_exists?(type, page, name, revision=nil)
      Raki.provider(type).attachment_exists?(type, page, name, revision)
    end
    
    def attachment_exists!(type, page, name, revision=nil, user=User.current)
      authorized!(type, page, :view, user)
      attachment_exists?(type, page, name, revision)
    end

    def attachment_contents(type, page, name, revision=nil)
      Raki.provider(type).attachment_contents(type, page, name, revision)
    end
    
    def attachment_contents!(type, page, name, revision=nil, user=User.current)
      authorized!(type, page, :view, user)
      attachment_contents(type, page, name, revision)
    end

    def attachment_revisions(type, page, name)
      Raki.provider(type).attachment_revisions(type, page, name)
    end
    
    def attachment_revisions!(type, page, name, user=User.current)
      authorized!(type, page, :view, user)
      attachment_revisions(type, page, name)
    end

    def attachment_save(type, page, name, contents, message, user=User.current)
      Raki.provider(type).attachment_save(type, page, name, contents, message, user)
    end
    
    def attachment_save!(type, page, name, contents, message, user=User.current)
      authorized!(type, page, :edit, user)
      attachment_save(type, page, name, contents, message, user)
    end

    def attachment_delete(type, page, name, user=User.current)
      Raki.provider(type).attachment_delete(type, page, name, user)
    end
    
    def attachment_delete!(type, page, name, user=User.current)
      authorized!(type, page, :edit, user)
      attachment_delete(type, page, name, user)
    end

    def attachment_all(type, page)
      Raki.provider(type).attachment_all(type, page)
    end
    
    def attachment_all!(type, page, user=User.current)
      authorized!(type, page, :view, user)
      attachment_all(type, page)
    end

    def attachment_changes(type, page=nil, amount=nil)
      Raki.provider(type).attachment_changes(type, page, amount)
    end
    
    def attachment_changes!(type, page=nil, amount=nil, user=User.current)
      changes = attachment_changes(type, page).select do |change|
        authorized?(change.type, change.page, :view, user)
      end
      changes = changes[0, amount] if amount > 0
      changes
    end
    
    def types
      types = []
      Raki.initialized_providers.values.each do |provider|
        provider.types.each do |type|
          types << type if Raki.provider(type) == provider
        end
      end
      types
    end
    
    def authorized?(type, name, action, user=User.current)
      Raki.permission?(type, name, action, user)
    end
    
    def authorized!(type, name, action, user=User.current)
      unless authorized?(type, name, action, user)
        raise NotAuthorizedError.new "#{user.id.to_s} has no permission to #{action.to_s} #{type.to_s}/#{name.to_s}"
      end
      true
    end
    
  end
end
