FactoryBot.define do
  factory :question do
    answer1 {"#{rand(2001)}"}
    answer2 {"#{rand(2001)}"}
    answer3 {"#{rand(2001)}"}
    answer4 {"#{rand(2001)}"}

    sequence (:text) { |n| "В каком году была Космическая Одиссея #{n}?" }

    sequence (:level) { |n| n % 15 }
  end
end