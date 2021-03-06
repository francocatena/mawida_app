module Questions::Constants
  ANSWER_TYPES = { written: 0, multi_choice: 1, yes_no: 2 }

  ANSWER_OPTIONS = [
    :strongly_agree,
    :agree,
    :neither_agree_nor_disagree,
    :disagree,
    :strongly_disagree,
    (:not_apply unless SHOW_ALTERNATIVE_QUESTIONNAIRES)
  ].compact

  ANSWER_OPTION_VALUES = {
    strongly_agree: 100,
    agree: 75,
    neither_agree_nor_disagree: 50,
    disagree: 25,
    strongly_disagree: 0
  }

  ANSWER_OPTION_VALUES[:not_apply] = -1 unless SHOW_ALTERNATIVE_QUESTIONNAIRES

  ANSWER_YES_NO_OPTIONS = [
    :yes,
    :no,
    (:not_apply unless SHOW_ALTERNATIVE_QUESTIONNAIRES)
  ].compact

  ANSWER_YES_NO_OPTION_VALUES = {
    yes: 100,
    no: 0
  }

  ANSWER_YES_NO_OPTION_VALUES[:not_apply] = -1 unless SHOW_ALTERNATIVE_QUESTIONNAIRES

  ANSWER_TYPES.each do |answer_type, answer_value|
    define_method("answer_#{answer_type}?") { self.answer_type == answer_value }
  end
end
