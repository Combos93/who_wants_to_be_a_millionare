require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do
  let(:user) { FactoryBot.create(:user) }

  let(:admin) { FactoryBot.create(:user, is_admin: true) }

  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  context 'Anonim' do
    it 'ban from #show' do
      get :show, params: { id: game_w_questions.id }

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'ban form #create' do
      post :create

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'ban form #take_money' do
      put :take_money, params: { id: game_w_questions.id }

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'ban form #answer' do
      put :answer, params: { id: game_w_questions.id }

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end
  end

  context 'Usual user' do
    before(:each) do
      sign_in user
    end

    it 'creates game' do
      generate_questions(60)

      post :create

      game = assigns(:game)

      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)

      expect(response).to redirect_to game_path(game)
      expect(flash[:notice]).to be
    end

    it '#show game' do
      get :show, params: { id: game_w_questions.id }

      game = assigns(:game)

      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)

      expect(response.status).to eq 200
      expect(response).to render_template('show')
    end

    it 'answer correct' do
      put :answer,
          params: { id: game_w_questions.id,
                    letter: game_w_questions.current_game_question.correct_answer_key }

      game = assigns(:game)

      expect(game.finished?).to be_falsey
      expect(game.current_level).to be > 0
      expect(response).to redirect_to(game_path(game))
      expect(flash.empty?).to be_truthy
    end

    it 'does not #show game' do
      alien_game = FactoryBot.create(:game_with_questions)

      get :show, params: { id: alien_game.id }

      expect(response.status).not_to eq 200
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be
    end

    it 'take_money before end game' do
      game_w_questions.update_attribute(:current_level, 2)

      put :take_money, params: { id: game_w_questions.id }
      game = assigns(:game)

      expect(game.finished?).to be_truthy
      expect(game.prize).to eq(200)

      user.reload

      expect(user.balance).to eq(200)

      expect(response).to redirect_to(user_path(user))
      expect(flash[:warning]).to be
    end

    it 'do not play two games together' do
      expect(game_w_questions.finished?).to be_falsey
      expect { post :create }.to change(Game, :count).by(0)

      game = assigns(:game)
      expect(game).to be_nil

      expect(response).to redirect_to(game_path(game_w_questions))
      expect(flash[:alert]).to be
    end

    it 'answer was wrong' do
      method = game_w_questions.answer_current_question!(game_w_questions.current_game_question.correct_answer_key)
      method = false
      # expect(game_question.correct_answer_key).to eq 'b'
      put :answer, params: { id: game_w_questions.id, letter: method }

      game = assigns(:game)

      expect(game.finished?).to be_truthy
      expect(response).to redirect_to(user_path(user))
      expect(flash[:alert]).to be
    end

    it "uses audience_help" do
      expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
      expect(game_w_questions.audience_help_used).to be_falsey

      put :help, params: { id: game_w_questions.id, help_type: :audience_help }
      game = assigns(:game)

      expect(game.finished?).to be_falsey
      expect(game.audience_help_used).to be_truthy
      expect(game.current_game_question.help_hash[:audience_help]).to be
      expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')

      expect(response).to redirect_to(game_path(game))
    end

    it "uses fifty_fifty" do
      expect(game_w_questions.current_game_question.help_hash[:fifty_fifty]).not_to be
      expect(game_w_questions.friend_call_used).to be_falsey

      put :help, params: { id: game_w_questions.id, help_type: :fifty_fifty }
      game = assigns(:game)

      expect(game.finished?).to be_falsey
      expect(game.fifty_fifty_used).to be_truthy
      expect(game.current_game_question.help_hash[:fifty_fifty]).to be

      help_ff = game.current_game_question.help_hash[:fifty_fifty]
      expect(help_ff).to include('b')

      expect(response).to redirect_to(game_path(game))
    end
  end
end
