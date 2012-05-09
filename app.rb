require 'guillotine'
require 'active_record'
require 'yaml'
require 'erb'

module Guillotine
  class Service
    # Public: Maps a URL to a shortened code.
    #
    # url  - A String or Addressable::URI URL to shorten.
    # code - Optional String code to use.  Defaults to a random String.
    #
    # Returns 201 with the Location pointing to the code, or 422.
    def create(url, code = nil)
      uri = Addressable::URI.parse(url)

      resp = check_uri(uri)
      return resp if resp
      code_resp = check_code(code)
      return code_resp if code_resp

      begin
        if code = @db.add(uri.to_s, code)
          [201, {"Location" => code}]
        else
          [422, {}, "Unable to shorten #{url}"]
        end
      rescue DuplicateCodeError => err
        [422, {}, err.to_s]
      end
    end

    def get(code)
      if url = @db.find(code)
        [302, {"Location" => URI.unescape(url)}]
      else
        [404, {}, "No url found for #{code}"]
      end
    end

    def check_code(code)
      if code && code.to_s !~ /^[a-zA-Z\d]*$/
        [422, {}, "Invalid code: #{code}"]
      end
    end
    # Checks to see if the input URL is using a valid host.  You can constrain
    # the hosts with the `required_host` argument of the Service constructor.
    #
    # url - An Addressible::URI instance to check.
    #
    # Returns a 422 Rack::Response if the host is invalid, or nil.
    def check_uri(uri)
      if uri.to_s !~ /^bikerace:\/\/newgame\?id=(.*)&name=(.*)$/
        [422, {}, "Invalid url: #{uri}"]
      end
    end

  end
  module Adapters
    class Adapter
      # Parses and sanitizes a URL.
      #
      # url - A String URL.
      #
      # Returns an Addressable::URI.
      def parse_url(url)
        url.gsub! /(\#).*/, ''
        Addressable::URI.parse url
      end
    end
  end
end

module Bikeraceme
  class App < Guillotine::App

    dbconfig = YAML::load(ERB.new(File.read('config/database.yml')).result)[ENV['RACK_ENV'] || 'development']
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
      erb :index
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