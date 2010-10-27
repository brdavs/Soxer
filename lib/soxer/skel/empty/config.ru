require "rubygems"
require "sinatra/base"
require "app"

disable :run
set :server, %w[thin mongrel webrick]
set :origin, "content"
set :haml, {:encoding => 'utf-8',
            :format => :html5, 
            :attr_wrapper => '"' }

configure :development do
  require 'sinatra/reloader'
  set :port, 9394
end

configure :production do
  set :port, 55500
end

set :environment, :production
run Sinatra::Application