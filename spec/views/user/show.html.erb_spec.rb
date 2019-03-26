require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  context "when user look own profile" do
    before(:each) do
      @user = FactoryBot.create(:user, name: "Vasiliy")
      @games = [FactoryBot.build_stubbed(:game, id: 1, created_at: Time.now, current_level: 6)]

      sign_in @user

      assign(:user, @user)
      assign(:games, @games)

      render
    end

    it 'renders current_user name' do
      expect(rendered).to match "Vasiliy"
    end

    it 'renders button for change password' do
      expect(rendered).to match 'Сменить имя и пароль'
    end
  end

  context "when other user look alien profile" do
    before(:each) do
      @user = FactoryBot.create(:user, name: "Vasiliy")
      @games = [FactoryBot.build_stubbed(:game, id: 1, created_at: Time.now, current_level: 6)]

      assign(:user, @user)
      assign(:games, @games)

      render
    end

    it 'renders user name' do
      expect(rendered).to match "Vasiliy"
    end

    it 'does not render button for change password' do
      expect(rendered).not_to match "Сменить имя и пароль"
    end

    it 'renders partial _game' do
      assert_template partial: "users/_game", count: @games.count
    end
  end
end
