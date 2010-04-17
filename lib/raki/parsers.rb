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
  class Parsers
    class << self
      def register(id, clazz)
        @parsers = {} if @parsers.nil?
        @parsers[id] = clazz
      end

      def all
        @parsers
      end

      def wiki
        if @current.nil?
          config = YAML.load(File.read("#{Rails.root}/config/raki.yml"))
          id = config['wiki']['parser']
          config['wiki'].delete('parser')
          @current = @parsers[id.to_sym].new(config['wiki'])
        end
        @current
      end
    end
  end
end
