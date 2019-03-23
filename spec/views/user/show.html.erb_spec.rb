require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  before(:each) do
    assign(:users, [
      @user = FactoryBot.build_stubbed(:user, name: 'Вадик', balance: 5000)
    ])
    sign_in @user

    stub_template 'users/_game.html.erb' => 'User game goes here'

    render
  end

  it 'renders current_user name' do
    expect(rendered).to match(@user.name)
  end

  # пока не делал; но нашёл инфу/прочитал делается через assert и assert_select
  it 'renders button for change password' do
    expect(rendered).to match '3 000 ₽'
  end

  it 'renders partial _game' do
    expect(rendered).to match('User game goes here')
  end
end
