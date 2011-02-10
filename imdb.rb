# uses the neography gem, see: https://github.com/maxdemarzi/neography
# see http://wiki.neo4j.org/content/Using_the_Neo4j_Server_with_Ruby

require 'rubygems'
require 'neography'
require 'sinatra/base'


class Imdb < Sinatra::Base
set :haml, :format => :html5 
set :app_file, __FILE__

include Neography


configure do
    env = ENV['NEO4J_ENV'] || "development"

    if env == "development"
      require 'net-http-spy'
      Net::HTTP.http_logger_options = {:verbose => true} 
    end

  Config.server = ENV['NEO4J_HOST']
  Config.authentication = {:basic_auth => {:username => ENV['NEO4J_LOGIN'], :password => ENV['NEO4J_PASSWORD']}}

end

before do
  @neo = Neography::Rest.new({
    :server => ENV['NEO4J_HOST'],
#    :directory => "/#{ENV['NEO4J_INSTANCE']}",
    :authentication => 'basic',
    :username => ENV['NEO4J_LOGIN'] , 
    :password => ENV['NEO4J_PASSWORD']
    })
end


helpers do
  def link_to(url, text=url, opts={})
    attributes = ""
    opts.each { |key,value| attributes << key.to_s << "=\"" << value << "\" "}
    "<a href=\"#{url}\" #{attributes}>#{text}</a>"
  end
end

get '/' do
   '<h2>Neo4j Imdb</h2>' + @neo.get_root.inspect + '<br\>' + '<h3>Indexes</h3>' + @neo.list_indexes.inspect 
     
end

get '/movie/:id' do
  @movie = @neo.get_node(params[:id])  
  @roles = @neo.get_node_relationships(@movie, "in", "ACTS_IN")
  @roles.each do |role| 
    node = @neo.get_node(role["start"])
    role["actor_name"] = node["data"]["name"]
    role["actor_link"] = "/actor/" + node["self"].split('/').last
  end

  haml :show_movie
end

get '/actor/:id' do
  @actor = @neo.get_node(params[:id])  
  @roles = @neo.get_node_relationships(@actor, "out", "ACTS_IN")
  @roles.each do |role| 
    node = @neo.get_node(role["end"])
    role["movie_title"] = node["data"]["title"]
    role["movie_link"] = "/movie/" + node["self"].split('/').last
  end

  haml :show_actor
end

get '/actor_v2/:id' do
  @actor = Node.load(params[:id])  
  @movies = @actor.outgoing("ACTS_IN")

  haml :show_actor_v2
end

get '/movie_v2/:id' do
  @movie = Node.load(params[:id])  
  @actors = @actor.outgoing("ACTS_IN")

  haml :show_actor_v2
end


  run! if app_file == $0
end
