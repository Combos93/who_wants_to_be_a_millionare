#  (c) goodprogrammer.ru
#
# Модельи игры — создается когда пользователь начинает новую игру. Хранит и
# обновляет состояние игры и отвечает за игровой процесс.
class Game < ActiveRecord::Base
  PRIZES = [100, 200, 300, 500, 1_000, 2_000, 4_000, 8_000, 16_000,
            32_000, 64_000, 125_000, 250_000, 500_000, 1_000_000].freeze
  FIREPROOF_LEVELS = [4, 9, 14].freeze
  TIME_LIMIT = 35.minutes

  belongs_to :user
  has_many :game_questions, dependent: :destroy

  scope :in_progress, -> {where(finished_at: nil)}

  validates :user, presence: true
  validates :current_level, numericality: {only_integer: true}, allow_nil: false
  validates :prize, presence: true, numericality: {
    greater_than_or_equal_to: 0, less_than_or_equal_to: PRIZES.last
  }

  def self.create_game_for_user!(user)
    transaction do
      game = create!(user: user)

      Question::QUESTION_LEVELS.each do |level|
        question = Question.where(level: level).order('RANDOM()').first

        answers = [1, 2, 3, 4].shuffle

        game.game_questions.create!(
          question: question,
          a: answers.pop, b: answers.pop,
          c: answers.pop, d: answers.pop
        )
      end

      game
    end
  end

  def current_game_question
    game_questions.detect {|q| q.question.level == current_level}
  end

  def previous_level
    current_level - 1
  end

  def finished?
    finished_at.present?
  end

  def time_out!
    if (Time.now - created_at) > TIME_LIMIT
      finish_game!(fire_proof_prize(previous_level), true)
      true
    end
  end

  def answer_current_question!(letter)
    return false if time_out! || finished?

    if current_game_question.answer_correct?(letter)
      self.current_level += 1

      if current_level == Question::QUESTION_LEVELS.max
        finish_game!(PRIZES[Question::QUESTION_LEVELS.max], false)
      else
        save!
      end

      true
    else
      finish_game!(fire_proof_prize(previous_level), true)
      false
    end
  end

  def take_money!
    return if time_out! || finished?

    finish_game!(previous_level > -1 ? PRIZES[previous_level] : 0, false)
  end

  # TODO: Дорогой ученик!
  #
  # Код метода ниже можно сократиь в 3 раза с помощью возможностей Ruby и Rails,
  # подумайте как и реализуйте. Помните о безопасности и входных данных!
  #
  # Вариант решения вы найдете в комментарии в конце файла, отвечающего за настройки
  # хранения сессий вашего приложения. Вот такой вот вам ребус :)
  #
  # Создает варианты подсказок для текущего игрового вопроса.
  # Возвращает true, если подсказка применилась успешно,
  # false если подсказка уже заюзана.
  #
  # help_type = :fifty_fifty | :audience_help | :friend_call

  def use_help(help_type)
    help_types = %i(fifty_fifty audience_help friend_call)
    help_type = help_type.to_sym
    raise ArgumentError.new('wrong help_type') unless help_types.include?(help_type)

    unless self["#{help_type}_used"]
      self["#{help_type}_used"] = true
      current_game_question.apply_help!(help_type)
      save
    end
    # false не нужен — unless вернёт nil, если не будет исполнен
  end

  def status
    return :in_progress unless finished?

    if is_failed
      (finished_at - created_at) > TIME_LIMIT ? :timeout : :fail
    elsif current_level > Question::QUESTION_LEVELS.max
      :won
    else
      :money
    end
  end

  private

  def finish_game!(amount = 0, failed = true)
    transaction do
      self.prize = amount
      self.finished_at = Time.now
      self.is_failed = failed
      user.balance += amount
      save!
      user.save!
    end
  end

  def fire_proof_prize(answered_level)
    level = FIREPROOF_LEVELS.select {|x| x <= answered_level}.last
    level.present? ? PRIZES[level] : 0
  end
end
