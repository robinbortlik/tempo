FactoryBot.define do
  factory :project do
    association :client
    sequence(:name) { |n| "Project #{n}" }
    hourly_rate { 100.00 }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :without_rate do
      hourly_rate { nil }
    end

    trait :with_custom_rate do
      transient do
        rate { 150.00 }
      end

      hourly_rate { rate }
    end
  end
end
