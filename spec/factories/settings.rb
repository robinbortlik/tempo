FactoryBot.define do
  factory :setting do
    company_name { "Acme Corporation" }
    address { "123 Business Street\nPrague, 10000\nCzech Republic" }
    email { "info@acme.com" }
    phone { "+420 123 456 789" }
    vat_id { "CZ12345678" }
    company_registration { "12345678" }

    trait :with_logo do
      after(:build) do |setting|
        setting.logo.attach(
          io: StringIO.new("fake logo content"),
          filename: "logo.png",
          content_type: "image/png"
        )
      end
    end

    trait :minimal do
      company_name { nil }
      address { nil }
      email { nil }
      phone { nil }
      vat_id { nil }
      company_registration { nil }
    end
  end
end
