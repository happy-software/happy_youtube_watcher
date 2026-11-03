RSpec.configure do |config|
  config.include Warden::Test::Helpers, type: :system
  config.include Devise::Test::IntegrationHelpers, type: :request

  config.before(:each, type: :system) do
    Warden.test_mode!
  end

  config.after(:each, type: :system) do
    Warden.test_reset!
  end
end
