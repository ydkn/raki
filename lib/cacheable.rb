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

module Cacheable
  
  def cache(name, options={})
    ttl = options.key?(:ttl) ? options[:ttl].to_i : 600
    uncached = "__uncached_#{name}"
    class_eval %Q{
      alias :#{uncached} :#{name}
      private :#{uncached}
      def #{name}(*args)
        @class_cache = Hash.new{|h,k| h[k] = Hash.new{|h,k| h[k] = {}}} unless defined?(@class_cache)
        cache = @class_cache[#{name.inspect}]
        if !cache.key?(args) || cache[args][:time] < (Time.new - #{ttl})
          cache[args] = {:cached => send(:#{uncached}, *args), :time => Time.new}
        end
        cache[args][:cached]
      end
    }
  end
  
  def flush_cache(name=nil, *args)
    if name.nil?
      @class_cache.clear
    elsif args.empty?
      @class_cache[name].clear
    else
      @class_cache[name][args].clear
    end
  end
  
end