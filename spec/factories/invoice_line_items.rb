FactoryBot.define do
  factory :invoice_line_item do
    association :invoice
    line_type { :time_aggregate }
    description { "Development work" }
    quantity { 8.0 }
    unit_price { 100.00 }
    amount { 800.00 }
    sequence(:position) { |n| n }

    trait :time_aggregate do
      line_type { :time_aggregate }
      quantity { 8.0 }
      unit_price { 100.00 }
      amount { 800.00 }
    end

    trait :fixed do
      line_type { :fixed }
      quantity { nil }
      unit_price { nil }
      amount { 500.00 }
      description { "Fixed-price deliverable" }
    end
  end
end
