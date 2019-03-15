FactoryBot.define do
  factory :user do
    name { "Жора_#{rand(777)}" }

    sequence (:email) { |n| "someguy_#{n}@example.com" }

    is_admin {false}

    balance {0}

    after(:build) { |user| user.password_confirmation = user.password = "123123" }
  end
end
