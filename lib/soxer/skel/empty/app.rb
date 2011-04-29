# encoding: utf-8
require "rubygems"
require "sinatra/base"
require "soxer"

class SoxerApp < Sinatra::Base
  set :root, File.dirname(__FILE__)
  register Sinatra::Soxer
end
