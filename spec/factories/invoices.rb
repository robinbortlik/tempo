FactoryBot.define do
  factory :invoice do
    association :client
    sequence(:number) { |n| "#{Date.current.year}-#{n.to_s.rjust(3, '0')}" }
    status { :draft }
    issue_date { Date.current }
    due_date { 30.days.from_now.to_date }
    period_start { Date.current.beginning_of_month }
    period_end { Date.current.end_of_month }
    total_hours { 0 }
    total_amount { 0 }
    currency { "EUR" }
    notes { nil }

    trait :draft do
      status { :draft }
    end

    trait :final do
      status { :final }
    end

    trait :with_notes do
      notes { "Thank you for your business!" }
    end

    trait :usd do
      currency { "USD" }
    end

    trait :gbp do
      currency { "GBP" }
    end

    trait :with_totals do
      total_hours { 40.0 }
      total_amount { 4800.00 }
    end

    trait :last_month do
      issue_date { 1.month.ago.to_date }
      due_date { 1.month.ago.to_date + 30.days }
      period_start { 1.month.ago.beginning_of_month.to_date }
      period_end { 1.month.ago.end_of_month.to_date }
    end

    trait :overdue do
      issue_date { 60.days.ago.to_date }
      due_date { 30.days.ago.to_date }
    end

    # Trait to create an invoice without auto-generated number
    # Useful when testing the InvoiceNumberGenerator callback
    trait :without_number do
      number { nil }
    end
  end
end
