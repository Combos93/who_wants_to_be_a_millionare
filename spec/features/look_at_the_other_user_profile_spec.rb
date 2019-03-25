require 'rails_helper'
require 'capybara/rails'


RSpec.feature 'USER creates a game', type: :feature do
  let(:user) { FactoryBot.create :user }
  let(:user2) { FactoryBot.create :user }

  let!(:questions) do
    (0..14).to_a.map do |i|
      FactoryBot.create(
        :question, level: i,
        text: "Когда была куликовская битва номер #{i}?",
        answer1: '1380', answer2: '1381', answer3: '1382', answer4: '1383'
      )
    end
  end

  let!(:questions2) do
    (0..14).to_a.map do |i|
      FactoryBot.create(
        :question, level: i,
        text: "Когда была снята Касабаланка #{i}?",
        answer1: '1940', answer2: '1941', answer3: '1942', answer4: '1943'
      )
    end
  end

  before(:each) do
    login_as user
  end

  scenario 'success' do
    visit '/'

    click_link 'Новая игра'

    expect(page).to have_content 'Когда была куликовская битва номер 0?'

    expect(page).to have_content '1380'
    expect(page).to have_content '1381'
    expect(page).to have_content '1382'
    expect(page).to have_content '1383'
  end
end
