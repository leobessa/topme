require 'aws-sdk'

unless ENV["AWS_ACCESS_KEY_ID"] && ENV["AWS_SECRET_ACCESS_KEY"]
  abort("missing env vars: please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY with your app credentials")
end
unless ENV["APP_NAME"]
  abort("missing env vars: please set APP_NAME")
end
AWS.config(:access_key_id => ENV["AWS_ACCESS_KEY_ID"],:secret_access_key => ENV["AWS_SECRET_ACCESS_KEY"])
AWS::Record.domain_prefix = "#{ENV['APP_NAME']}_#{ENV['RACK_ENV'] || 'development'}_"

class Url < AWS::Record::Model
  string_attr :code
  string_attr :url
end

module Guillotine
  module Adapters
    class SimpleDbAdapter < Adapter

      # Public: Stores the shortened version of a URL.
      # 
      # url  - The String URL to shorten and store.
      # code - Optional String code for the URL.
      #
      # Returns the unique String code for the URL.  If the URL is added
      # multiple times, this should return the same code.
      def add(url, code = nil)
        code_for(url) || insert(url, code || shorten(url))
      end


      # Public: Retrieves a URL from the code.
      #
      # code - The String code to lookup the URL.
      #
      # Returns the String URL, or nil if none is found.
      def find(code)
        record = Url.first(:where => {:code => code})
        record.url if record
      end

      # Public: Retrieves the code for a given URL.
      #
      # url - The String URL to lookup.
      #
      # Returns the String code, or nil if none is found.
      def code_for(url)
        record = Url.first(:where => {:url => url})
        record.code if record
      end

      # Public: Removes the assigned short code for a URL.
      #
      # url - The String URL to remove.
      #
      # Returns nothing.
      def clear(url)
        record = Url.first(:url => url)
        record.delete
      end

      private
      def insert(url, code)
        if existing_url = find(code)
          raise DuplicateCodeError.new(existing_url, url, code) if url != existing_url
        end
        Url.new(:code => code, :url => url).save
        code
      end
    end
  end
end