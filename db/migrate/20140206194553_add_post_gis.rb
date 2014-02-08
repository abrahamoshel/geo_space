class AddPostGis < ActiveRecord::Migration
  def up
    execute "CREATE EXTENSION IF NOT EXISTS postgis;"
  end
end
