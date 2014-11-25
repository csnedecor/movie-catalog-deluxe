require 'sinatra'
require 'sinatra/reloader'
require 'pry'
require 'pg'

def db_connection
  begin
    connection = PG.connect(dbname: 'movies')

    yield(connection)

  ensure
    connection.close
  end
end

def get_data
  query = @query
  result = []
  db_connection do |conn|
    result = conn.exec(query)
  end
  result.to_a
end

def sanitize_data
  query = @query
  result = []
  db_connection do |conn|
    result = conn.exec_params(query)
  end
  result.to_a
end

def increment_page
  if @page > 1
    @back = @page-1
  else
    @back = 1
  end
  if @page < 1
    @next = 2
  else
    @next = @page + 1
  end
end

get '/actors' do
  @page = params[:page].to_i || 1
  increment_page
  @query = "SELECT name, id FROM actors ORDER BY name LIMIT 20 OFFSET #{@page * 10}"
  @actors = get_data
  erb :'/actors/show'
end

get '/' do
  erb :'home'
end

get '/actors/:id' do
  id = params[:id]
  @query = "SELECT movies.title, movies.id, cast_members.character FROM movies
  LEFT OUTER JOIN cast_members ON cast_members.movie_id = movies.id
  LEFT OUTER JOIN actors ON actors.id = cast_members.actor_id
  WHERE actors.id = #{id}"
  @movie_characters = sanitize_data
  erb :'/actors/details'
end

get '/movies/:id' do
  id = params[:id]
  @query = "SELECT movies.title, movies.synopsis, movies.rating, genres.name AS
  genre, studios.name AS studio, actors.id AS actor_id, actors.name AS actor,
  cast_members.character FROM movies
  JOIN genres ON genres.id = movies.genre_id
  JOIN studios ON studios.id = movies.studio_id
  JOIN cast_members ON cast_members.movie_id = movies.id
  JOIN actors ON actors.id = cast_members.actor_id
  WHERE movies.id = #{id}"
  @movie_details = sanitize_data
  @title = @movie_details[1]["title"]
  @synopsis = @movie_details[1]["synopsis"]
  @rating = @movie_details[1]["rating"]
  @genre = @movie_details[1]["genre"]
  @studio = @movie_details[1]["studio"]
  erb :'/movies/details'
end

def sort_movies
  if params.value?('year')
    @query = "SELECT movies.title, movies.year, movies.rating, movies.id,
    genres.name AS genre, studios.name AS studio FROM movies
    LEFT OUTER JOIN genres ON genres.id = movies.genre_id
    LEFT OUTER JOIN studios ON studios.id = movies.studio_id
    ORDER BY movies.year DESC"
  elsif params.value?('rating')
    @query = "SELECT movies.title, movies.year, movies.rating, movies.id,
    genres.name AS genre, studios.name AS studio FROM movies
    LEFT OUTER JOIN genres ON genres.id = movies.genre_id
    LEFT OUTER JOIN studios ON studios.id = movies.studio_id
    ORDER BY movies.rating DESC NULLS LAST"
  else
    @query = "SELECT movies.title, movies.year, movies.rating, movies.id,
    genres.name AS genre, studios.name AS studio FROM movies
    LEFT OUTER JOIN genres ON genres.id = movies.genre_id
    LEFT OUTER JOIN studios ON studios.id = movies.studio_id
    ORDER BY movies.title"
  end
end

get '/movies' do
  sort_movies
  @movie_data = get_data
  erb :'/movies/show'
end
