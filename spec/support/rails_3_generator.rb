module Rails3Generator
  PROJECT_ROOT = File.join(File.expand_path(File.dirname(__FILE__)), "..", "..")

  APP_NAME = "testapp"
  TEMP_DIR = File.join(File.expand_path(File.dirname(__FILE__)), "..", "..", "tmp")
  `mkdir -p #{TEMP_DIR}`
  APP_DIR = File.join(TEMP_DIR, APP_NAME)

  def create_app
    puts "Creating test app..."
    Dir.chdir(TEMP_DIR) do
      `bundle exec rails new #{APP_NAME} --skip-bundle`
    end
  end

  def add_rack_timeout(time = 1)
    Dir.chdir(APP_DIR) do
      transform_file("Gemfile") do |content|
        content << "gem 'rack-timeout', path: '#{PROJECT_ROOT}'\n"
        content << "gem 'rails_12factor'\n"
      end

      File.open("config/initializers/rack-timeout.rb", "w") do |file|
        file.write "Rack::Timeout.timeout = #{time}"
      end

      transform_file("config/application.rb") do |content|
        content = content.sub("  end\nend\n", "  config.middleware.insert 0, Rack::Timeout\n  end\nend\n")
        content
      end
    end
  end

  def set_log_level(level)
    Dir.chdir(APP_DIR) do
      transform_file("config/environments/#{Rails.env}.rb") do |contents|
        contents = contents.sub("Testapp::Application.configure do\n", "Testapp::Application.configure do\nconfig.log_level = :#{level}")
        contents
      end
    end
  end

  def start_app
    Dir.chdir(APP_DIR) do
      require './config/environment'
      require 'capybara/rails'
      require 'capybara/rspec'
    end
  end

  def create_sleep_controller
    Dir.chdir(APP_DIR) do
      File.open("app/controllers/sleep_controller.rb", "w") do |file|
        file.write <<FILE
class SleepController < ApplicationController
  def time
    sleep params[:time].to_f
    render text: params[:time]
  end
end
FILE
      end

      transform_file("config/routes.rb") do |content|
        content = content.sub "Testapp::Application.routes.draw do\n", "Testapp::Application.routes.draw do\nget 'sleep/:time' => 'sleep#time'"
        content
      end
    end
  end

  def destroy_app
    puts "Destroying test app."
    `rm -rf #{File.join(TEMP_DIR, APP_NAME)}`
  end

  # shamelessly ripped from thoughtbot/paperclip
  def transform_file(filename)
    content = File.read(filename) if File.exists?(filename)
    content ||= nil

    File.open(filename, "w") do |f|
      content = yield(content)
      f.write(content)
    end
  end
end
