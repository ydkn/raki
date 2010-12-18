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

class RakiPluginGenerator < Rails::Generator::NamedBase
  
  attr_reader :plugin_path, :plugin_name, :plugin_class, :plugin_dir, :plugin_pretty_name
  
  def initialize runtime_args, runtime_options = {}
    super
    @plugin_dir = "raki_#{file_name.underscore}"
    @plugin_name = file_name.underscore
    @plugin_class = file_name.classify
    @plugin_pretty_name = file_name.underscore.titleize
    @plugin_path = "vendor/plugins/#{plugin_dir}"
  end
  
  def manifest
    record do |m|
      m.directory "#{plugin_path}/app"
      m.directory "#{plugin_path}/assets"
      m.directory "#{plugin_path}/assets/images"
      m.directory "#{plugin_path}/assets/stylesheets"
      m.directory "#{plugin_path}/config/locales"
      m.directory "#{plugin_path}/templates"
      m.directory "#{plugin_path}/templates/#{@plugin_name}"
      m.directory "#{plugin_path}/test"
      
      m.template 'README.rdoc.erb', "#{plugin_path}/README.rdoc"
      m.template 'init.rb.erb', "#{plugin_path}/init.rb"
      m.template 'en.yml.erb', "#{plugin_path}/config/locales/en.yml"
      m.template 'plugin_test.rb.erb', "#{plugin_path}/test/#{@plugin_name}_test.rb"
      m.template 'template.erb', "#{plugin_path}/templates/#{@plugin_name}/#{@plugin_name}.erb"
      m.template 'gitkeep', "#{plugin_path}/app/.gitkeep"
    end
  end
  
end
