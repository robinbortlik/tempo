FactoryBot.define do
  factory :invoice_line_item_work_entry do
    association :invoice_line_item
    association :work_entry
  end
end
