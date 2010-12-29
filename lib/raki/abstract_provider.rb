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
  class AbstractProvider

    class ProviderError < StandardError; end
    class PageNotExists < ProviderError; end
    class AttachmentNotExists < ProviderError; end
    class InvalidName < ProviderError; end
    
    attr_reader :id

    def page_exists?(namespace, name, revision=nil)
      raise ProviderError.new 'not implemented'
    end

    def page_contents(namespace, name, revision=nil)
      raise ProviderError.new 'not implemented'
    end

    def page_revisions(namespace, name, options={})
      raise ProviderError.new 'not implemented'
    end

    def page_save(namespace, name, contents, message, user)
      raise ProviderError.new 'not implemented'
    end

    def page_rename(old_namespace, old_name, new_namespace, new_name, user)
      raise ProviderError.new 'not implemented'
    end

    def page_delete(namespace, name, user)
      raise ProviderError.new 'not implemented'
    end

    def page_all(namespace)
      raise ProviderError.new 'not implemented'
    end

    def page_changes(namespace, options={})
      raise ProviderError.new 'not implemented'
    end

    def attachment_exists?(namespace, page, name, revision=nil)
      raise ProviderError.new 'not implemented'
    end

    def attachment_contents(namespace, page, name, revision=nil)
      raise ProviderError.new 'not implemented'
    end

    def attachment_revisions(namespace, page, name, options={})
      raise ProviderError.new 'not implemented'
    end

    def attachment_save(namespace, page, name, contents, message, user)
      raise ProviderError.new 'not implemented'
    end

    def attachment_delete(namespace, page, name, user)
      raise ProviderError.new 'not implemented'
    end

    def attachment_all(namespace, page)
      raise ProviderError.new 'not implemented'
    end

    def attachment_changes(namespace, page=nil, amount=nil)
      raise ProviderError.new 'not implemented'
    end
    
    def namespaces
      raise ProviderError.new 'not implemented'
    end

  end
end
