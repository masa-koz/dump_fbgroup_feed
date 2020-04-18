require 'sinatra/base'
require 'sinatra/cookies'
require 'koala'

class App < Sinatra::Base
  helpers Sinatra::Cookies

  get '/' do
    if cookies.has_key?(:fb_access_token)
      graph = Koala::Facebook::API.new(cookies[:fb_access_token])
      @feed_first = graph.get_connections("146940180042907", "feed")
    end
    erb :index
  end
end