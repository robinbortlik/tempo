FactoryBot.define do
  factory :time_entry do
    association :project
    date { Date.current }
    hours { 8.0 }
    description { "Working on project tasks" }
    status { :unbilled }
    invoice { nil }

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
