# Register firefox driver; all others are included by default
# https://github.com/teamcapybara/capybara/blob/master/README.md#selenium
Capybara.register_driver :selenium_firefox do |app|
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile['browser.download.dir'] = Rails.root.join("tmp/downloads").to_s
  profile['browser.download.folderList'] = 2
  # Suppress "open with" dialog
  profile['browser.helperApps.neverAsk.saveToDisk'] = 'text/csv'
  Capybara::Selenium::Driver.new(app, :browser => :firefox, :profile => profile)
end

Capybara.disable_animation = true # disables CSS animations in test suite

RSpec.configure do |config|
  config.before(:each, type: :system) do
    if ENV['BROWSER']
      case ENV['BROWSER'].to_sym.downcase
      when :chrome
        driven_by :selenium_chrome
      when :firefox
        driven_by :selenium_firefox
      else
        msg = "\n[WARNING] Invalid browser specified: '#{ENV['BROWSER']}'\n"
        msg += "\tAvailable browsers are 'chrome' or 'firefox'\n"
        msg += "\tDefaulting to headless Selenium driver\n\n"

        puts msg
        driven_by :selenium_headless
      end
    else
      driven_by :selenium_headless
    end
  end
end
