require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do

  let(:user) { FactoryBot.create(:user) }

  let(:game_w_questions) do
    FactoryBot.create(:game_with_questions, user: user)
  end
  context "Game Factory" do
    it 'Game.create_game_for_user! new correct game' do
      generate_questions(60)

      game = nil
      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(
        change(GameQuestion, :count).by(15)
      )

      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)

      expect(game.game_questions.size).to eq(15)

      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  context "game mechanics" do
    it 'answer correct continues' do
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      expect(game_w_questions.current_level).to eq(level + 1)

      expect(game_w_questions.current_game_question).not_to eq q

      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end
  end

  context "method take_money!" do
    it 'add to user current_money' do
      q = game_w_questions.current_game_question

      game_w_questions.answer_current_question!(q.correct_answer_key)
      game_w_questions.take_money!

      prize = game_w_questions.prize

      expect(prize).to be > 0

      expect(game_w_questions.status).to eq(:money)
      expect(game_w_questions.finished?).to be_truthy
      expect(user.balance).to be prize
    end
  end

  context "method status" do
    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be_truthy
    end

    it 'games status is_failed' do
      game_w_questions.is_failed = true

      expect(game_w_questions.status).to be :fail
    end

    it 'games status is won' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1

      expect(game_w_questions.status).to eq :won
    end

    it 'games status is timeout' do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.is_failed = true

      expect(game_w_questions.status).to be :timeout
    end

    it 'games status is money(takemoney)' do
      expect(game_w_questions.status).to eq :money
    end
  end

  context "method previous_level" do
    it 'return sub current_level' do
      game_w_questions.previous_level
      prev_level = game_w_questions.current_level -= 1

      expect(game_w_questions.current_level).to eq(prev_level)
    end
  end

  context "method current_game_question" do
    it 'return current_question' do
      # текущий game_questions level
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question

      # отвечаем на вопрос верно, сдвигая вопрос, на один уровень
      game_w_questions.answer_current_question!(q.correct_answer_key)

      next_level = game_w_questions.current_game_question
      expect(game_w_questions.current_game_question).to eq(next_level)
    end
  end
end
