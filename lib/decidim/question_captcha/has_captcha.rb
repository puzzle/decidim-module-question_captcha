# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module QuestionCaptcha
    module HasCaptcha
      extend ActiveSupport::Concern

      class_methods do
        def captcha_questions
          Decidim::QuestionCaptcha.config.questions
        end
      end

      included do
        attribute :textcaptcha_answer, String

        acts_as_textcaptcha raise_errors: Decidim::QuestionCaptcha.config.raise_error,
                            cache_expiry_minutes: Decidim::QuestionCaptcha.config.expiration_time,
                            questions: captcha_questions

        def perform_textcaptcha?
          return if Rails.application.config.cache_store == :null_store

          Decidim::QuestionCaptcha.config.perform_textcaptcha
        end

        def current_locale
          I18n.locale
        end

        def default_locale
          I18n.default_locale
        end

        private

        def questions
          return if textcaptcha_config[:questions].blank?

          textcaptcha_config[:questions][current_locale] || textcaptcha_config[:questions][default_locale]
        end

        def config_q_and_a
          return unless questions

          random_question = questions[rand(questions.size)].symbolize_keys!
          answers = (random_question[:answers] || "").split(",").map! { |answer| safe_md5(answer) }

          { "q" => random_question[:question], "a" => answers } if random_question && answers.present?
        end
      end
    end
  end
end
