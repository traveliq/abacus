source :rubygems
source :rubyforge
source :gemcutter
source 'http://gems.github.com'

gem 'rails',            '2.3.5'
gem 'json',             '1.4.6'
gem 'json_pure',        '1.4.6', :require => false
gem 'redis-namespace',  '0.8.0', :require => 'redis/namespace'
gem 'redis',            '2.0.1'
gem 'hoptoad_notifier', '2.3.7'
gem 'rack',             '1.0.1'
gem 'mysql'
gem 'resque',            '1.9.9'

group :development do
  gem 'ruby-debug'
end

group :require_first do
  gem 'SyslogLogger', '1.4.0', :require => 'syslog_logger'
end

group :test do
  gem 'rspec',        '1.2.9', :require => false
  gem 'rspec-rails',  '1.2.9', :require => false
end
