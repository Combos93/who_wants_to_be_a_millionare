require 'rails_helper'

RSpec.feature 'USER creates a game', type: :feature do
  let(:user) { FactoryBot.create :user, name: 'Vasya' }
  let(:user_2) { FactoryBot.create :user, name: 'Vanya' }

  let!(:games) {[
    FactoryBot.create(:game, id: 15, user: user, prize: 10000, current_level: 6, is_failed: true,
                      created_at: '2019-03-10 16:16:51', finished_at: '2019-03-10 16:21:51'),
    FactoryBot.create(:game, id: 16, user: user, prize: 50000, current_level: 11, is_failed: false ,
                      created_at: '2019-03-13 16:16:51', finished_at: '2019-03-13 16:21:51')
  ]}

  before(:each) do
    login_as user_2
  end

  scenario 'success' do
    visit '/'

    click_link 'Vasya'

    expect(page).not_to have_content 'Сменить имя и пароль'

    expect(page).to have_content '15'
    expect(page).to have_content 'проигрыш'
    expect(page).to have_content '10 марта, 16:16'
    expect(page).to have_content '10 000 ₽'
    expect(page).to have_content '6'


    expect(page).to have_content '16'
    expect(page).to have_content 'деньги'
    expect(page).to have_content '13 марта, 16:16'
    expect(page).to have_content '50 000 ₽'
    expect(page).to have_content '11'
  end
end
