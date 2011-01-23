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
  
  # Refresh enqueued values.
  Thread.new do
    while true do
      op = nil
      begin
        op = @queue.pop
        $stdout.flush
        cache = @cache[op[:object]][op[:method]][op[:args]]
        cache[:data] = op[:object].send("__uncached_#{op[:method].to_s}", *op[:args])
        cache[:time] = Time.new
        cache[:enqueued] = false
        op = nil
      rescue => e
        @queue << op unless op.nil?
      end
    end
  end
  
  # Remove unused values from cache and reduce cache size.
  Thread.new do
    while true do
      begin
        @cache.each do |clazz, methods|
          methods.each do |method, method_args|
            method_args.delete_if do |args, params|
              params[:last_access] < (Time.new - params[:ttl]*10)
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
    
    # Cache method with options.
    # 
    # Available options:
    # * :ttl => TTL for cached value in seconds.
    # * :force => Don't return cached value if value has exceed TTL.
    # 
    #    def foobar(p1,p2); end
    #    cache :foobar, :ttl => 10, :force => true
    # 
    def cache(name, options={})
      return if Rails.env == 'development'
      
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
            cache[args] = {:data => send(name_uncached.to_sym, *args), :time => Time.new, :ttl => ttl, :force => force}
          else
            if cache[args][:time] < (Time.new - ttl)
              if force
                cache[args] = {:data => send(name_uncached.to_sym, *args), :time => Time.new, :ttl => ttl, :force => force}
              elsif !cache[args][:enqueued]
                Cacheable.queue << {:object => self, :method => name.to_sym, :args => args}
                cache[args][:enqueued] = true
              end
            end
          end
          cache[args][:last_access] = Time.new
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
  
  # Mark all values as expired.
  def self.expire
    return if Rails.env == 'development'
    
    time = Time.parse('1900-01-01')
    @cache.values.each do |clazz|
      clazz.values.each do |cached|
        cached.values.each do |params|
          params[:time] = time
        end
      end
    end
  end
  
  # Remove all values from cache.
  def self.flush
    return if Rails.env == 'development'
    
    @cache.values.each do |clazz|
      clazz.values.each do |cached|
        cached.clear
      end
      clazz.clear
    end
  end
  
  # Mark value(s) as expired.
  def expire(name=nil, *args)
    return if Rails.env == 'development'
    
    name = name.to_sym
    cache = Cacheable.cache[self]
    time = Time.parse('1900-01-01')
    if name.nil?
      cache.values.each do |method_args|
        method_args.values.each do |params|
          params[:time] = time
        end
      end
    elsif args.nil? || args.empty?
      cache[name].values.each do |params|
        params[:time] = time
      end
    else
      cache[name][args][:time] = time
    end
  end
  
  # Removes value(s) from the cache.
  def flush(name=nil, *args)
    return if Rails.env == 'development'
    
    name = name.to_sym
    cache = Cacheable.cache[self]
    if name.nil?
      cache.each do |method, params|
        params.clear
      end
    elsif args.nil? || args.empty?
      cache[name].clear
    else
      cache[name].delete(args)
    end
  end
  
  # Check if value is cached.
  def cached?(name, *args)
    return false if Rails.env == 'development'
    cache = Cacheable.cache[self][name.to_sym]
    return false unless cache.key?(args)
    params = cache[args]
    !(params[:force] && (params[:time] < (Time.new - params[:ttl])))
  end
  
end