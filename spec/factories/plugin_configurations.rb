FactoryBot.define do
  factory :plugin_configuration do
    sequence(:plugin_name) { |n| "test_plugin_#{n}" }
    enabled { true }
    credentials { { api_key: "test_api_key" }.to_json }
    settings { { sync_interval: 60 }.to_json }

    trait :disabled do
      enabled { false }
    end

    trait :without_credentials do
      credentials { nil }
    end

    trait :without_settings do
      settings { nil }
    end

    trait :with_invalid_json_credentials do
      credentials { "not valid json" }
    end

    trait :with_invalid_json_settings do
      settings { "not valid json" }
    end
  end
end
