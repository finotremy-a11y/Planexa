class EnableExtensions < ActiveRecord::Migration[8.0]
  def change
    enable_extension "uuid-ossp"
    enable_extension "unaccent"   # Pour la recherche insensible aux accents
  end
end
