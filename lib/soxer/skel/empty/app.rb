# encoding: utf-8
require "rubygems"
require "sinatra"
require "soxer"

not_found { 'The document does not exist' }

get("/sitemap.xml") { sitemap }

get "/css/:sheet.css" do
  content_type "text/css", :charset => "utf-8"
  sass params[:sheet].to_sym 
end

get '*.*' do
  file = File.join( settings.root, settings.origin, params[:splat].join('.') )
  case params[:splat][1]
    when /[jpg|png|pdf|doc|xls|pdf]/ then send_file(file, :disposition => nil)
  end
end

post '*/?' do
  content_type "text/html", :charset => "utf-8"
  page = get_page
  page['layout'] ||= 'layout'
  haml page['content'], :layout => page['layout'].to_sym, :locals => { :page => page }
end

get '*/?' do
  content_type "text/html", :charset => "utf-8"

  if params[:splat][0] =~ /-atom$/ then
    set :haml, { :format => :xhtml }
    content_type "application/atom+xml", :charset => "utf-8"
  end

  page = get_page
  page['layout'] ||= 'layout'
  haml page['content'], :layout => page['layout'].to_sym, :locals => { :page => page }
end
