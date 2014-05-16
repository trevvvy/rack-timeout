require_relative 'rails_generator'

module Rails4Generator
  include RailsGenerator
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
        content.sub "Rails.application.routes.draw do\n", "Rails.application.routes.draw do\nget 'sleep/:time' => 'sleep#time'"
      end
    end
  end
end
