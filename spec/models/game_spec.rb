require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do

  let(:user) {FactoryBot.create(:user)}

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
      # current_level сейчас равен 0 ; поэтому 0 -1 = (-1)
      expect(game_w_questions.previous_level).to eq(-1)
    end
  end

  describe '#answer_current_question!' do
    context "when answer was wrong" do
      it 'game was finishing' do
        game_w_questions.current_level = 12

        expect(game_w_questions.answer_current_question!('c')).to be_falsey
        expect(game_w_questions.status).to be :fail
        expect(game_w_questions.finished?).to be_truthy
      end
    end

    context 'when question is last in game' do
      it 'won the game' do
        game_w_questions.current_level = 14

        expect(game_w_questions.answer_current_question!(
          game_w_questions.current_game_question.correct_answer_key
                                                        )).to be_truthy

        expect(game_w_questions.status).to be :won
        expect(game_w_questions.finished?).to be_truthy
        expect(game_w_questions.prize).to eq(1000000)
      end
    end

    context "time is finish" do
      it 'return false' do
        game_w_questions.created_at = 1.hour.ago

        expect(game_w_questions.answer_current_question!(
        game_w_questions.current_game_question.correct_answer_key)).to be_falsey

        expect(game_w_questions.finished?).to be_truthy

        expect(game_w_questions.status).to be :timeout
      end
    end

    context "when answer was right" do
      it 'the game continues' do
        game_w_questions.current_level = 2

        expect(game_w_questions.answer_current_question!('d')).to be_truthy
        expect(game_w_questions.status).to be :in_progress
        expect(game_w_questions.finished?).to be_falsey
      end
    end
  end
end