# Raki - extensible rails-based wiki
# Copyright (C) 2010 Florian Schwab
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

    class ProviderError < StandardError
    end

    def page_exists?(type, name, revision=nil)
      raise ProviderError.new 'not implemented'
    end

    def page_contents(type, name, revision=nil)
      raise ProviderError.new 'not implemented'
    end

    def page_revisions(type, name)
      raise ProviderError.new 'not implemented'
    end

    def page_save(type, name, contents, message, user)
      raise ProviderError.new 'not implemented'
    end

    def page_rename(type, old_name, new_name, user)
      raise ProviderError.new 'not implemented'
    end

    def page_delete(type, name, user)
      raise ProviderError.new 'not implemented'
    end

    def page_all(type)
      raise ProviderError.new 'not implemented'
    end

    def page_changes(type, amount=0)
      raise ProviderError.new 'not implemented'
    end

    def attachment_exists?(type, page, name, revision=nil)
      raise ProviderError.new 'not implemented'
    end

    def attachment_contents(type, page, name, revision=nil)
      raise ProviderError.new 'not implemented'
    end

    def attachment_revisions(type, page, name)
      raise ProviderError.new 'not implemented'
    end

    def attachment_save(type, page, name, contents, message, user)
      raise ProviderError.new 'not implemented'
    end

    def attachment_delete(type, page, name, user)
      raise ProviderError.new 'not implemented'
    end

    def attachment_all(type, page=nil)
      raise ProviderError.new 'not implemented'
    end

    def attachment_changes(type, page=nil, amount=nil)
      raise ProviderError.new 'not implemented'
    end
    
    def types
      raise ProviderError.new 'not implemented'
    end

    private

    class Revision
      attr_reader :id
      attr_reader :version
      attr_reader :size
      attr_reader :user
      attr_reader :date
      attr_reader :message

      def initialize(id, version, size, user, date, message)
        @id = id
        @version = version
        @size = size
        @user = user
        @date = date
        @message = message
      end
    end

    class Change
      attr_reader :type
      attr_reader :name
      attr_reader :revision
      attr_reader :attachment

      def initialize(type, name, revision, attachment=nil)
        @type = type
        @name = name
        @revision = revision
        @attachment = attachment
      end
    end

  end
end
