FactoryBot.define do
  factory :bank_account do
    sequence(:name) { |n| "Bank Account #{n}" }
    bank_name { "Test Bank" }
    bank_account { "1234567890" }
    bank_swift { "TESTBICX" }
    iban { "DE89370400440532013000" }
    is_default { false }

    trait :default do
      is_default { true }
    end
  end
end
