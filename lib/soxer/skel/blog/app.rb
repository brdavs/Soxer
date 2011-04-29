# encoding: utf-8
require "rubygems"
require "sinatra/base"
require "soxer"

class SoxerApp < Sinatra::Base
  set :root, File.dirname(__FILE__)
  set :haml, {:format => :html5, 
              :attr_wrapper => '"'}
  enable :sessions
  before do
    session[:theme] ||= %w[dna blossom][rand 1]
    session[:theme] = params[:theme] if params[:theme]
  end
  get '/blog' do
    redirect '/categories'
  end
  
  register Sinatra::Soxer
end
