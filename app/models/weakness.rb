class Weakness < Finding
  include Findings::Approval
  include Weaknesses::Code
  include Weaknesses::Defaults
  include Weaknesses::GraphHelpers
  include Weaknesses::Priority
  include Weaknesses::Progress
  include Weaknesses::Risk
  include Weaknesses::Scopes
  include Weaknesses::Validations
  include Weaknesses::WorkPapers
end
