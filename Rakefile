# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

task :test => 'db:migrate:plugins'
namespace :test do
  task :benchmark => 'db:migrate:plugins'
  task :functionals => 'db:migrate:plugins'
  task :integration => 'db:migrate:plugins'
  task :plugins => 'db:migrate:plugins'
  task :profile => 'db:migrate:plugins'
  task :recent => 'db:migrate:plugins'
  task :uncommitted => 'db:migrate:plugins'
  task :units => 'db:migrate:plugins'
end
