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
    
    module FormatHelper
      
      FORMAT_KILOBYTE_SIZE = 1024.0
      FORMAT_MEGABYTE_SIZE = 1048576.0
      FORMAT_GIGABYTE_SIZE = 1073741824.0

      def format_filesize(size)
        size = size.to_i
        case
          when size == 1
            out = "1 Byte"
          when size < FORMAT_KILOBYTE_SIZE
            out = "#{size} Bytes"
          when size < FORMAT_MEGABYTE_SIZE
            out = "%.2f KB" % (size.to_f/FORMAT_KILOBYTE_SIZE)
          when size < FORMAT_GIGABYTE_SIZE
            out = "%.2f MB" % (size.to_f/FORMAT_MEGABYTE_SIZE)
          else
            out = "%.2f GB" % (size.to_f/FORMAT_GIGABYTE_SIZE)
        end
        out
      end
      
    end
    
  end
end
