# config.ru
require File.expand_path("../app.rb", __FILE__)

require 'rack/rewrite'
use Rack::Rewrite do
   r301 %r{/(bikerace://newgame.*)}, '$1'
end

run Bikeraceme::App