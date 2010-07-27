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

Dir[File.join(Rails.root, 'vendor', 'plugins', '*')].each do |plugin|
  if File.directory?(plugin)
    template_dir = File.join(plugin, 'templates')
    if File.exists?(template_dir) && File.directory?(template_dir)
      Dir[File.join(template_dir, '*')].each do |template|
        if File.exists?(template) && !File.directory?(template) && /\.erb$/.match(template)
          Raki::Plugin.add_template(template)
        end
      end
    end
  end
end
