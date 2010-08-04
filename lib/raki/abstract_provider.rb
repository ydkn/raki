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

    class ProviderError < StandardError
    end
    
    include Raki::Helpers
    
    attr_reader :id

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

    def page_rename(old_type, old_name, new_type, new_name, user)
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
    
    def page_diff(type, page, revision_from=nil, revision_to=nil)
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

    def attachment_all(type, page)
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
      attr_reader :id, :version, :size, :user, :date, :message

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
      attr_reader :type, :page, :revision, :attachment

      def initialize(type, page, revision, attachment=nil)
        @type = type
        @page = page
        @revision = revision
        @attachment = attachment
      end
    end
    
    class Diff < Array
      attr_reader :lines
      
      def initialize(lines)
        @lines = []
        found_start = false
        lines.each do |line|
          if line =~ /^@@ (\+|\-)(\d+)(,\d+)? (\+|\-)(\d+)(,\d+)? @@/
            found_start = true
            @lines << line
            next
          end
          next unless found_start
          next if line =~ /^\\/
          @lines << line
          self << DiffLine.new(nil, nil, line)
        end
      end
      
      class DiffLine
        attr_reader :type, :line, :line_number1, :line_number2
        
        def initialize(line_num_1, line_num_2, line)
          @line_number1 = line_num_1
          @line_number2 = line_num_2
          if line =~ /^(\+|\-)(.*)/
            @type = $1 == '+' ? 'add' : 'remove'
            @line = $2
          else
            @type = 'same'
            @line = line
          end
        end
      end
    end

  end
end
