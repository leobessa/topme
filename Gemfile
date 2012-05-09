source :rubygems

gem "sinatra-activerecord"
gem "activerecord", "~> 3.2.3"
gem "guillotine"
gem "thin"

group :development, :test do
  gem 'sqlite3'
end
 
group :production do
  gem 'pg' # this gem is required to use postgres on Heroku
end
