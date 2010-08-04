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
    
    def url?(url)
      !(url.match "^[a-zA-Z]+:\/\/(.+(:.+)?@)?[a-zA-Z0-9_-](\.[a-zA-Z0-9_-])*(:[0-9]+)?/").nil?
    end
    
    def provider(type)
      Raki.provider(type)
    end
    
    def page_exists?(type, name, revision=nil)
      provider(type).page_exists?(type, name, revision)
    end

    def page_contents(type, name, revision=nil)
      provider(type).page_contents(type, name, revision)
    end

    def page_revisions(type, name)
      provider(type).page_revisions(type, name)
    end

    def page_save(type, name, contents, message, user=User.current)
      provider(type).page_save(type, name, contents, message, user)
    end

    def page_rename(old_type, old_name, new_type, new_name, user=User.current)
      provider(type).page_rename(old_type, old_name, new_type, new_name, user)
    end

    def page_delete(type, name, user=User.current)
      provider(type).page_delete(type, name, user)
    end

    def page_all(type)
      provider(type).page_all(type)
    end

    def page_changes(type, amount=0)
      provider(type).page_changes(type, amount)
    end
    
    def page_diff(type, page, revision_from=nil, revision_to=nil)
      provider(type).page_diff(type, page, revision_from, revision_to)
    end

    def attachment_exists?(type, page, name, revision=nil)
      provider(type).attachment_exists?(type, page, name, revision)
    end

    def attachment_contents(type, page, name, revision=nil)
      provider(type).attachment_contents(type, page, name, revision)
    end

    def attachment_revisions(type, page, name)
      provider(type).attachment_revisions(type, page, name)
    end

    def attachment_save(type, page, name, contents, message, user=User.current)
      provider(type).attachment_save(type, page, name, contents, message, user)
    end

    def attachment_delete(type, page, name, user=User.current)
      provider(type).attachment_delete(type, page, name, user)
    end

    def attachment_all(type, page)
      provider(type).attachment_all(type, page)
    end

    def attachment_changes(type, page=nil, amount=nil)
      provider(type).attachment_changes(type, page, amount)
    end
    
    def types
      types = []
      Raki.initialized_providers.values.each do |provider|
        provider.types.each do |type|
          types << type if provider(type) == provider
        end
      end
      types
    end
    
    def parser(type)
      Raki.parser(type)
    end
    
    def parse(type, content, context=context)
      parser(type).parse(content, context)
    end
    
    def parsed_page(type, page, revision=nil, context=context)
      parse(
        type,
        page_contents(type, page, revision),
        context
      )
    end
    
  end
end
