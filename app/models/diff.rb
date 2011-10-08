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

class Diff
  
  attr_reader :from, :to, :lines
  
  def initialize(from, to, lines)
    @from = from
    @to = to
    @lines = lines
  end
  private :initialize
  
  def self.create(a, b)
    a_file = File.join(Rails.root, 'tmp', rand(1000000).to_s)
    b_file = File.join(Rails.root, 'tmp', rand(1000000).to_s)
    
    File.open(a_file, 'w') {|f| f.write(a.content) }
    File.open(b_file, 'w') {|f| f.write(b.content) }
    
    lines = `diff --unified=5 #{a_file} #{b_file}`
    
    create_from_unified_diff(a, b, lines)
  ensure
    File.delete(a_file) rescue nil
    File.delete(b_file) rescue nil
  end
  
  def self.create_from_unified_diff(a, b, udiff)
    lines = []
    found_start = false
    
    udiff.split("\n").each do |line|
      
      if line =~ /^@@ (\+|\-)(\d+)(,\d+)? (\+|\-)(\d+)(,\d+)? @@/
        found_start = true
        next
      end
      
      next unless found_start
      next if line =~ /^\\ /
      
      if line =~ /^(\+|\-)(.*)/
        type = $1 == '+' ? 'add' : 'remove'
        line = $2
      else
        type = 'same'
        line = line
      end
      
      lines << DiffLine.new(nil, nil, type, line)
    end
    
    Diff.new(a, b, lines)
  end
  
  class DiffLine
    
    attr_reader :type, :line
    
    def initialize(lna, lnb, type, line)
      @type = type.to_sym
      @line = line
    end
    
  end
  
end
