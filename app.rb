require 'sinatra/base'
require 'sinatra/cookies'
require "cgi/escape"
require 'koala'
require 'csv'
require 'json'

class App < Sinatra::Base
  helpers Sinatra::Cookies

  configure do
    mime_type :csv, 'text/csv'
    mime_type :json, 'text/json'
    mime_type :json, 'text/text'
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

  get '/feed.json' do
    content_type :json
    #content_type :text

    json_txt = ""
    if cookies.has_key?(:fb_access_token)
      feed_fields = {
        'comments' => ['created_time','id','message','permalink_url'],
        'created_time' => [],
        'id' => [],
        'message' => [],
        'permalink_url' => [],
        'updated_time' => []
      }

      reactions = ['like', 'love', 'wow', 'haha', 'sad', 'angry', 'thankful']
      reactions_fields = {
        'id' => [],
        'summary' => ['total_count', 'viewer_reaction'],
      }

      graph = Koala::Facebook::API.new(cookies[:fb_access_token])
      feed_fields_query =
      feed_fields.keys.collect { |v|
        if feed_fields[v].size > 0
          "#{v}{#{ feed_fields[v].join(',') }}"
        else
          "#{v}"
        end
      }.join(',')
      raw_json = graph.get_object("146940180042907", {
        fields: [
          "feed{#{ feed_fields_query }}",
          reactions.collect {|v| "feed.as(#{v}){reactions.type(#{v.upcase}).summary(true)}"}
        ].flatten
      })

      posts = {}
      raw_json['feed']['data'].each do |v|
        vals =
        feed_fields.keys.collect {|k1|
          if v.key?(k1)
            if feed_fields[k1].size > 0
              Hash[ feed_fields[k1].zip(v[k1].fetch_values(*feed_fields[k1]){ |k2| "" }) ]
            else
              v[k1]
            end
          else
            ""
          end
        }
        id = v.fetch('id') {|k1| "" }
        posts[id] = Hash[feed_fields.keys.zip(vals)]
      end
=begin
      feed = feed_first
      while feed.size > 0
        csv << feed.collect {|f|
          f.values.to_csv
        }
        break if csv.size > 1
        feed = feed.next_page
      end
=end
      #json_txt << json.to_json
      json_txt << posts.to_json
    end
    json_txt
  end
end