# encoding: utf-8
require "rubygems"
require "sinatra"
require "soxer"

class SoxerApp < Sinatra::Application
  register Sinatra::Soxer
end
