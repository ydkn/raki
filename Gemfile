source 'http://rubygems.org'

gem 'rails', '3.1.3'
gem 'sqlite3'
gem 'mime-types'

# Deploy with Capistrano
# gem 'capistrano'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.1.4'
  gem 'coffee-rails', '~> 3.1.1'
  gem 'uglifier',     '>= 1.0.3'
end

group :production, :test do
  gem 'execjs'
  gem 'therubyracer'
end

group :test do
  gem 'minitest'
  
  # Pretty printed test output
  gem 'turn', :require => false
end


# Plugins
gem 'raki_git_provider', :path => 'vendor/plugins/git_provider'
gem 'raki_openid_authenticator', :path => 'vendor/plugins/openid_authenticator'
