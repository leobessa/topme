# config.ru
require File.expand_path("../app.rb", __FILE__)
use Rack::Static, :urls => ["/crossdomain.xml"], :root => "public"
run Bikeraceme::App