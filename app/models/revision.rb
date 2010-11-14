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
      @page = @attachment.page
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
  
  def <=> b
    if date == b.date
      if type == :page && b.type == :page
        compare_page page, b.page
      elsif type == :attachment && b.type == :attachment
        attachment_compare attachment, b.attachment
      elsif type == :page && b.type == :attachment
        -1
      else
        1
      end
    else
      date <=> b.date
    end
  end
  
  private
  
  def compare_page(a, b)
    if a.namespace == b.namespace
      a.name <=> b.name
    else
      a.namespace <=> b.namespace
    end
  end
  
  def attachment_compare(a, b)
    pc = compare_page a.page, b.page
    (pc == 0) ? (a.name <=> b.name) : pc
  end
  
end