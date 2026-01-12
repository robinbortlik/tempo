FactoryBot.define do
  factory :sync_history do
    sequence(:plugin_name) { |n| "test_plugin_#{n}" }
    status { :pending }
    started_at { Time.current }
    completed_at { nil }
    records_processed { 0 }
    records_created { 0 }
    records_updated { 0 }
    records_failed { 0 }
    error_message { nil }

    trait :running do
      status { :running }
    end

    trait :completed do
      status { :completed }
      completed_at { Time.current }
      records_processed { 10 }
      records_created { 5 }
      records_updated { 3 }
    end

    trait :failed do
      status { :failed }
      completed_at { Time.current }
      error_message { "Connection timeout" }
    end
  end
end
