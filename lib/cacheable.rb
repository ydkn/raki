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
  
  def self.included(base)
    base.extend(Cacheable)
  end
  
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
            while true do
              op = @class_cache_queue.pop
              @class_cache[op[:method]][args] = {
                :cached => send(op[:method], *op[:args]),
                :time => Time.new,
                :enqueued => false
              }
            end
          end
          Thread.new do
            while true do
              @class_cache.each do |method, params|
                params.delete_if do |args, cache|
                  cache[:time] < (Time.new - #{ttl}*10)
                end
              end
              sleep 10
            end
          end
        end
        cache = @class_cache[#{name.inspect}]
        unless cache.key?(args)
          cache[args] = {:cached => send(:#{uncached}, *args), :time => Time.new}
        else
          if !cache[args][:enqueued] && cache[args][:time] < (Time.new - #{ttl})
            @class_cache_queue << {:method => #{uncached.inspect}, :args => args}
            cache[args][:enqueued] = true
            Rails.logger.debug "Enqueued refresh: \#{cache[args].inspect}"
          end
        end
        cache[args][:cached]
      end
    }
  end
  
  def flush_cache(name=nil, *args)
    if name.nil?
      @class_cache.each do |key, value|
        value.clear
      end
    elsif args.empty?
      @class_cache[name].clear
    else
      @class_cache[name].delete(args)
    end
  end
  
end