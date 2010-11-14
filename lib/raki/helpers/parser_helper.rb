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
    
    module ParserHelper
      
      include ProviderHelper
      
      def parser(namespace)
        Raki::Parser[namespace]
      end
      
      def parser_by_name(name)
        Raki::Parser.all[name]
      end

      def parse(namespace, content=nil, context=nil)
        if context.nil? && !@context.nil?
          context = @context
        end
        if content.nil?
          content = namespace
          namespace = :default
        end
        parser(namespace).parse(content, context)
      end
      
      def parse_with(parser, content, context=nil)
        if context.nil? && !@context.nil?
          context = @context
        end
        parser_by_name(parser).parse(content, context)
      end

      def parsed_page(namespace, page, revision=nil, context=nil)
        if context.nil? && !@context.nil?
          context = @context
        end
        parse(
          namespace,
          page_contents(namespace, page, revision),
          context
        )
      end

      def parsed_page!(namespace, page, revision=nil, context=nil, user=User.current)
        if context.nil? && !@context.nil?
          context = @context
        end
        parse(
          namespace,
          page_contents!(namespace, page, revision, user),
          context
        )
      end

    end
    
  end
end
