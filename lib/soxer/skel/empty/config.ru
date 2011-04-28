require "rubygems"
require "sinatra/base"
require "./app"

disable :run
set :server, %w[thin mongrel webrick]
set :haml, {:format => :html5, 
            :attr_wrapper => '"'}
set :haml, {:encoding => 'utf-8'} if RUBY_VERSION=~/1\.9/

set :origin, settings.root+'/content'

configure :development do
  require 'sinatra/reloader'
  set :port, 9394
end

configure :production do
  set :haml, {:ugly => true}
  set :port, 55500
end

set :environment, :production

map '/' do
  run SoxerApp
end
