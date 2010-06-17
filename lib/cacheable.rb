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
        unless defined?(@class_cache)
          @class_cache = Hash.new{|h,k| h[k] = Hash.new{|h,k| h[k] = {}}}
          @class_cache_queue = Queue.new
          Thread.new do
            op = @class_cache_queue.pop
            @class_cache[op[:method]][args] = {:cached => send(op[:method], *op[:args]), :time => Time.new}
          end
        end
        cache = @class_cache[#{name.inspect}]
        unless cache.key?(args)
          cache[args] = {:cached => send(:#{uncached}, *args), :time => Time.new}
        end
        if cache[args][:time] < (Time.new - #{ttl})
          @class_cache_queue << {:method => #{name.inspect}, :args => args}
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