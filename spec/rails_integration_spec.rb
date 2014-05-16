require 'spec_helper'

puts defined?(Rails)
puts Rails::VERSION::MAJOR
if defined?(Rails) && Rails::VERSION::MAJOR == 3
  include Rails3Generator

  describe "Rails 3 Integration", type: :feature do
    before :all do
      create_app
      add_middleware
      create_sleep_controller
      start_app
    end
    
    after :all do
      destroy_app
    end

    it "tests rails" do
      Capybara.visit "sleep/2"
      puts Capybara.page.status_code
      puts Capybara.page.html
    end
  end
end
