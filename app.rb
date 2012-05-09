require 'guillotine'
require 'active_record'
require 'yaml'

module Guillotine
  class Service
    def check_host(url)
      if url.scheme !~ /^bikerace$/
        [422, {}, "Invalid url: #{url}"]
      else
        @host_check.call url
      end
    end
  end
end

module Bikeraceme
  class App < Guillotine::App

    dbconfig = YAML::load_file('config/database.yml')[ENV['RACK_ENV'] || 'development']
    ActiveRecord::Base.establish_connection(dbconfig)  
    set :dbconfig, dbconfig


    adapter = Guillotine::Adapters::ActiveRecordAdapter.new dbconfig
    set :service => Guillotine::Service.new(adapter)

    # authenticate everything except GETs
    before do
      unless request.request_method == "GET"
        protected!
      end
    end

    get '/' do
      "Shorten all the URLs"
    end

    if ENV['TWEETBOT_API']
      # experimental (unauthenticated) API endpoint for tweetbot
      get '/api/create/?' do
        status, head, body = settings.service.create(params[:url], params[:code])

        if loc = head['Location']
          "#{File.join("http://", request.host, loc)}"
        else
          500
        end
      end
    end

    # helper methods
    helpers do

      # Private: helper method to protect URLs with Rack Basic Auth
      #
      # Throws 401 if authorization fails
      def protected!
        return unless ENV["HTTP_USER"]
        unless authorized?
          response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
          throw(:halt, [401, "Not authorized\n"])
        end
      end

      # Private: helper method to check if authorization parameters match the
      # set environment variables
      #
      # Returns true or false
      def authorized?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        user = ENV["HTTP_USER"]
        pass = ENV["HTTP_PASS"]
        @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [user, pass]
      end
    end

  end
end