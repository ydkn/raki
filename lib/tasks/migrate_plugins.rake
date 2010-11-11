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

namespace :db do
  namespace :migrate do

    desc 'Migrate plugins to current status.'
    task :plugins => :environment do
      Dir["#{Rails.root}/vendor/plugins/*"].each do |dir|
        if File.directory?(dir) && File.exists?("#{dir}/db/migrate")
          ActiveRecord::Migrator.migrate(
            "#{dir}/db/migrate/",
            ENV["VERSION"] ? ENV["VERSION"].to_i : nil
          )
        end
      end
    end

  end

end
