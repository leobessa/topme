# config.ru
require 'newrelic_rpm'
require File.expand_path("../app.rb", __FILE__)
run Bikeraceme::App