namespace :assets do
  desc "Génère les favicons PNG depuis le SVG (requiert ImageMagick)"
  task :favicon do
    svg_path = Rails.root.join("app/assets/images/favicon.svg")
    unless File.exist?(svg_path)
      puts "❌ favicon.svg introuvable dans app/assets/images/"
      exit 1
    end

    [ 16, 32, 48, 180 ].each do |size|
      output = Rails.root.join("public/favicon-#{size}.png")
      system("convert -background none #{svg_path} -resize #{size}x#{size} #{output}")
      puts "✓ favicon-#{size}.png généré"
    end

    puts "\nCopie du SVG dans public/"
    FileUtils.cp(svg_path, Rails.root.join("public/favicon.svg"))
    puts "✓ favicon.svg copié dans public/"
    puts "\nPense à convertir public/favicon-32.png en public/favicon.ico"
  end
end
