FactoryBot.define do
  factory :money_transaction do
    source { "test_source" }
    amount { 100.00 }
    currency { "EUR" }
    transacted_on { Date.current }
    transaction_type { :income }
    description { nil }
    external_id { nil }

    trait :expense do
      transaction_type { :expense }
    end

    trait :income do
      transaction_type { :income }
    end

    trait :with_external_id do
      sequence(:external_id) { |n| "ext_#{n}" }
    end
  end
end
