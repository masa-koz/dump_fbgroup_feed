require 'sinatra/base'
require 'sinatra/cookies'
require 'koala'
require 'csv'
require "cgi/escape"

class App < Sinatra::Base
  helpers Sinatra::Cookies

  configure do
    mime_type :csv, 'text/csv'
  end

  get '/' do
    if cookies.has_key?(:fb_access_token)
      begin
        graph = Koala::Facebook::API.new(cookies[:fb_access_token])
        @group = graph.get_object("146940180042907", {
          fields: ['member_count', 'name']
        })
      rescue => e
        @error = CGI.escapeHTML(e.inspect)
      end
    end
    erb :index
  end

  get '/feed.csv' do
    content_type :csv

    if cookies.has_key?(:fb_access_token)
      graph = Koala::Facebook::API.new(cookies[:fb_access_token])
      feed_first = graph.get_connections("146940180042907", "feed", {
        limit: 1,
        fields: ['id', 'message', 'updated_time']
      })
      csv = []
      feed = feed_first
      while feed.size > 0
        csv << feed.collect {|f| f.values.to_csv }
        break if csv.size > 2
        feed = feed.next_page
      end
      csv.join("\n")
    else
      ""
    end
  end
end