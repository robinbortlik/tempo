FactoryBot.define do
  factory :exchange_rate do
    base_currency { "CZK" }
    quote_currency { "EUR" }
    rate { 25.125 }
    amount { 1 }
    date { Date.current }

    trait :usd do
      quote_currency { "USD" }
      rate { 23.456 }
    end

    trait :gbp do
      quote_currency { "GBP" }
      rate { 29.789 }
    end

    trait :high_amount do
      quote_currency { "JPY" }
      rate { 0.153 }
      amount { 100 }
    end
  end
end
