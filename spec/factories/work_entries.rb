FactoryBot.define do
  factory :work_entry do
    association :project
    date { Date.current }
    hours { 8.0 }
    description { "Working on project tasks" }
    entry_type { :time }
    status { :unbilled }
    invoice { nil }
    amount { nil }

    trait :time_entry do
      entry_type { :time }
      hours { 8.0 }
      amount { nil }
    end

    trait :fixed_entry do
      entry_type { :fixed }
      hours { nil }
      amount { 500.00 }
    end

    trait :custom_pricing do
      entry_type { :time }
      hours { 8.0 }
      amount { 1200.00 }  # Custom amount overrides calculated
    end

    trait :invoiced do
      status { :invoiced }
    end

    trait :unbilled do
      status { :unbilled }
    end

    trait :yesterday do
      date { Date.yesterday }
    end

    trait :last_week do
      date { 1.week.ago.to_date }
    end

    trait :with_custom_hours do
      transient do
        custom_hours { 4.0 }
      end

      hours { custom_hours }
    end

    trait :without_description do
      description { nil }
    end
  end
end
