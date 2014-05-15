module Rails3Generator
  APP_NAME = "testapp"
  TEMP_DIR = File.join(File.expand_path(File.dirname(__FILE__)), "../../tmp")
  `mkdir -p #{TEMP_DIR}`

  def create_app
    puts "Creating test app..."
    Dir.chdir(TEMP_DIR) do
      `bundle exec rails new #{APP_NAME} --skip-bundle`
      Dir.chdir(File.join(TEMP_DIR, APP_NAME)) do
      end
    end
  end

  def destroy_app
    puts "Destroying test app."
    `rm -rf #{File.join(TEMP_DIR, APP_NAME)}`
  end
end
