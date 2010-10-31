# encoding: utf-8
require "rubygems"
require "sinatra"
require "soxer"

class SoxerApp < Sinatra::Base
  register Sinatra::Soxer
  
  # Only for sending forms... not a part of Soxer per se...
  post '*/?' do
    content_type "text/html", :charset => "utf-8"
    page = get_page
    page['layout'] ||= 'layout'
    haml page['content'], :layout => page['layout'].to_sym, :locals => { :page => page }
  end

end
