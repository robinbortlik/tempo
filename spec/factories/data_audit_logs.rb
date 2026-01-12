FactoryBot.define do
  factory :data_audit_log do
    auditable_type { "MoneyTransaction" }
    sequence(:auditable_id) { |n| n }
    action { :create_action }
    changes_made { nil }
    source { "test_plugin" }
    sync_history { nil }

    trait :create_action do
      action { :create_action }
      changes_made { nil }
    end

    trait :update_action do
      action { :update_action }
      changes_made { { "amount" => { "from" => 100, "to" => 200 } } }
    end

    trait :destroy_action do
      action { :destroy_action }
      changes_made { { "final_state" => { "amount" => 100, "source" => "test" } } }
    end

    trait :from_user do
      source { "user" }
    end

    trait :with_sync_history do
      association :sync_history
    end
  end
end
