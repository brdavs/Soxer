# encoding: utf-8
require "rubygems"
require "sinatra"
require "soxer"

class SoxerApp < Sinatra::Base
  register Sinatra::Soxer
end
