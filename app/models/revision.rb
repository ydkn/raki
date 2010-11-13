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

class Revision
  
  attr_reader :page, :attachment, :id, :version, :size, :user, :date, :message, :mode

  def initialize(obj, id, version, size, user, date, message, mode=nil)
    if obj.is_a?(Page)
      @page = obj
    elsif obj.is_a?(Attachment)
      @attachment = obj
    end
    @id = id
    @version = version
    @size = size
    @user = user
    @date = date
    @message = message
    @mode = mode ? mode.to_sym : :none
  end
  
  def type
    @page ? :page : :attachment
  end
  
  def deleted?
    @mode == :deleted
  end
  
  def renamed?
    @mode == :renamed
  end
  
end