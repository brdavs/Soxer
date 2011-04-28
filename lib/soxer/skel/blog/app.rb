# encoding: utf-8
require "rubygems"
require "sinatra"
require "soxer"

class SoxerApp < Sinatra::Application
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
