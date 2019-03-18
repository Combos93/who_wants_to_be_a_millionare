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

  describe 'answer_current_question!' do
    context "current_game_question" do
      it 'return current_game_question' do
        # вытаскиваем конкретный обьект - текущий вопрос; то есть первый. Потому что игра только началась.
        expect(game_w_questions.current_game_question).to eq(GameQuestion.find(1))
      end
    end

    context "if answer is right" do
      it 'return true' do
        level = game_w_questions.current_level
        # текущий уровень вопроса; проверим что он его и вернёт
        expect(game_w_questions.current_level).to eq(level)

        q = game_w_questions.current_game_question
        method = game_w_questions.answer_current_question!(q.correct_answer_key)
        # повышаем текущий уровень вопроса, если ответ верен
        level += 1

        expect(game_w_questions.current_level).to eq(level)
        expect(method).to be true
      end

      context "if answer is wrong" do
        it 'return false & add users balance' do
          q = game_w_questions.current_game_question

          method = game_w_questions.answer_current_question!(q.correct_answer_key)
          method = false

          expect(game_w_questions.current_game_question).not_to eq q
          expect(method).to eq false

          game_w_questions.send(:finish_game!)
          game_w_questions.is_failed = true

          game_w_questions.current_level = 5
          game_w_questions.send(:fire_proof_prize, (game_w_questions.previous_level))

          # наталкиваемся на FIREPROOF_LEVELS
          if game_w_questions.previous_level == 4
            prize = 1_000
            expect(prize).to be > 0

            user.balance += prize
            expect(user.balance).to be prize
          end
        end
      end

      context 'when question is last in game' do
        it 'finish the game' do
          level = game_w_questions.current_level
          # текущий уровень вопроса; проверим что он его и вернёт
          expect(game_w_questions.current_level).to eq(level)

          q = game_w_questions.current_game_question
          method = game_w_questions.answer_current_question!(q.correct_answer_key)
          # повышаем текущий уровень вопроса, если ответ верен
          level += 1

          expect(game_w_questions.current_level).to eq(level)

          game_w_questions.current_level = 14
          last_q = game_w_questions.current_level

          if last_q == Question::QUESTION_LEVELS.max + 1
            game_w_questions.send(:finish_game!)
            game_w_questions.is_failed = false

            prize = PRIZES[Question::QUESTION_LEVELS.max]

            expect(prize).to be > 0

            user.balance += prize
            expect(user.balance).to be prize
          end
        end
      end

      context "time is finish" do
        it 'return false' do
          game_w_questions.finished_at = Time.now
          expect(game_w_questions.finished?).to be_truthy

          game_w_questions.created_at = 1.hour.ago
          game_w_questions.is_failed = true

          expect(game_w_questions.is_failed).to be_truthy
          expect(game_w_questions.status).to be :timeout
        end
      end
    end
  end
end