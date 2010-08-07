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

module Cacheable
  
  @cache = Hash.new{|h,k| h[k] = Hash.new{|h,k| h[k] = Hash.new{|h,k| h[k] = {}}}}
  @queue = Queue.new
  
  Thread.new do
    while true do
      op = nil
      begin
        op = @queue.pop
        $stdout.flush
        @cache[op[:object]][op[:method]][op[:args]] = {
          :data => op[:object].send("__uncached_#{op[:method].to_s}", *op[:args]),
          :time => Time.new,
          :enqueued => false
        }
        op = nil
      rescue => e
        @queue << op unless op.nil?
      end
    end
  end
  
  Thread.new do
    while true do
      begin
        @cache.each do |clazz, methods|
          methods.each do |method, method_args|
            method_args.delete_if do |args, params|
              params[:time] < (Time.new - params[:ttl]*10)
            end
          end
          methods.delete_if do |method, method_args|
            method_args.length == 0
          end
        end
        @cache.delete_if do |clazz, methods|
          methods.length == 0
        end
      rescue => e
      end
      sleep 60
    end
  end
  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    
    def cache(name, options={})
      name = name.to_s
      name_uncached = "__uncached_#{name.to_s}"
      
      ttl = options.key?(:ttl) ? options[:ttl].to_i : 10
      force = options.key?(:force) ? options[:ttl] : false
      
      class_eval("alias :#{name_uncached} :#{name}")
      class_eval("private :#{name_uncached}")
      
      class_eval do
        define_method name do |*args|
          cache = Cacheable.cache[self][name.to_sym]
          unless cache.key?(args)
            cache[args] = {:data => send(name_uncached.to_sym, *args), :time => Time.new, :ttl => ttl}
          else
            if cache[args][:time] < (Time.new - ttl)
              if force
                cache[args] = {:data => send(name_uncached.to_sym, *args), :time => Time.new, :ttl => ttl}
              elsif !cache[args][:enqueued]
                Cacheable.queue << {:object => self, :method => name.to_sym, :args => args}
                cache[args][:enqueued] = true
              end
            end
          end
          cache[args][:data]
        end
      end
      
      nil
    end
    
  end
  
  def self.cache
    @cache
  end
  
  def self.queue
    @queue
  end
  
  def self.expire
    time = Time.parse('1900-01-01')
    @cache.values.each do |clazz|
      clazz.values.each do |cached|
        cached.values.each do |params|
          params[:time] = time
        end
      end
    end
  end
  
  def self.flush
    @cache.values.each do |clazz|
      clazz.values.each do |cached|
        cached.clear
      end
      clazz.clear
    end
  end
  
  def expire(name=nil, *args)
    name = name.to_sym
    cache = Cacheable.cache[self]
    time = Time.parse('1900-01-01')
    if name.nil?
      cache.values.each do |method_args|
        method_args.values.each do |params|
          params[:time] = time
        end
      end
    elsif args.empty?
      cache[name].values do |params|
        params[:time] = time
      end
    else
      cache[name][args][:time] = time
    end
  end
  
  def flush(name=nil, *args)
    name = name.to_sym
    cache = Cacheable.cache[self]
    if name.nil?
      cache.each do |method, params|
        params.clear
      end
    elsif args.empty?
      cache[name].clear
    else
      cache[name].delete(args)
    end
  end
  
end