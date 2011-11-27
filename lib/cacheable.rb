# Raki - extensible rails-based wiki
# Copyright (C) 2011 Florian Schwab & Martin Sigloch
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

require 'thread'
require 'rails'

module Cacheable
  
  class CacheError < StandardError; end
  class UncacheableArgumentsError < CacheError; end
  
  
  def self.caching_enabled?
    Rails.application.config.cache_classes && Rails.cache
  end
  
  def self.cache_key obj, method, args
    args_keys = args.collect do |a|
      if a.respond_to? :cache_key
        a.cache_key
      elsif a.respond_to? :to_param
        a.to_param
      else
        raise UncacheableArgumentsError
      end
    end

    {:object_class => obj.class.to_s.to_sym, :object_id => obj.object_id, :method => method.to_sym, :args => args_keys}
  end
  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    
    # Cache method with options.
    # 
    # Available options:
    # * :ttl => TTL for cached value in seconds.
    # 
    #    def foobar(p1,p2); end
    #    cache :foobar, :ttl => 10
    # 
    def cache method, options={}
      return unless Cacheable.caching_enabled?
      
      method = method.to_s
      method_uncached = "__uncached_#{method.to_s}"
      
      ttl = options.key?(:ttl) ? options[:ttl].to_i : nil
      
      class_eval("alias :#{method_uncached} :#{method}")
      class_eval("private :#{method_uncached}")
      
      class_eval do
        define_method method do |*args|
          begin
            cache_key = Cacheable.cache_key self, method, args
            
            options = {}
            options[:expires_in] = ttl if ttl
            
            return_value = Rails.cache.fetch cache_key, options do
              cache_value = nil
              begin
                v = send method_uncached.to_sym, *args
                cache_value = {:type => :value, :data => v}
              rescue => e
                cache_value = {:type => :error, :data => e}
              end
              
              cache_value
            end
            
            @cache_keys ||= []
            @cache_keys << cache_key unless @cache_keys.include? cache_key
            
            if @cache_cleanup_time && @cache_cleanup_time <= Time.now
              @cache_keys.delete_if do |ck|
                !Rails.cache.exist? ck
              end
              
              @cache_cleanup_time = Time.now + 20
            end
            
            if return_value[:type] == :error
              raise return_value[:data]
            else
              return return_value[:data]
            end
          rescue => e
            p e.to_s
            print e.backtrace.join("\n")
            raise e
            Rails.logger "Caching for #{self.class.to_s}(#{self.object_id})##{method.to_s} with args #{args.inspect} not possible: #{e.to_s}"
            
            raise CacheError
          end
        end
      end
      
      nil
    end
    
  end
  
  # Removes value(s) from the cache.
  def cache_delete method=nil, *args
    return nil unless Cacheable.caching_enabled?
    
    if method && args.count > 0
      cache_key = Cacheable.cache_key self, method, args
      Rails.cache.delete cache_key
    elsif method
      @cache_keys.delete_if do |ck|
        if ck[:method] == method.to_sym
          Rails.cache.delete ck
          true
        else
          false
        end
      end
    else
      @cache_keys.delete_if do |ck|
        Rails.cache.delete ck
        true
      end
    end
  end
  
  # Check if value is cached.
  def cached? method, *args
    return nil unless Cacheable.caching_enabled?
    
    cache_key = Cacheable.cache_key self, method, args
    
    Rails.cache.exist? cache_key
  end
  
end