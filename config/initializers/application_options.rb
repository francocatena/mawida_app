ALLOW_CONCLUSION_FINAL_REVIEW_DESTRUCTION = ENV['ALLOW_CONCLUSION_FINAL_REVIEW_DESTRUCTION'] == 'true'
ALLOW_FINDING_ASSUMED_RISK_TO_PENDING = ENV['ALLOW_FINDING_ASSUMED_RISK_TO_PENDING'] == 'true'
ALLOW_REVIEW_CONTROL_OBJECTIVE_DUPLICATION = ENV['ALLOW_REVIEW_CONTROL_OBJECTIVE_DUPLICATION'] == 'true'
DEFAULT_LDAP_ROLES = String(ENV['DEFAULT_LDAP_ROLES']).split /\s*,\s*/
DISABLE_COI_AUDIT_DATE_VALIDATION = ENV['DISABLE_COI_AUDIT_DATE_VALIDATION'] == 'true'
DISABLE_FINDING_FINAL_STATE_ROLE_VALIDATION = ENV['DISABLE_FINDING_FINAL_STATE_ROLE_VALIDATION'] == 'true'
DISABLE_REVIEW_AUDITED_VALIDATION = ENV['DISABLE_REVIEW_AUDITED_VALIDATION'] == 'true'
HIDE_BUSINESS_UNIT_SCORES = ENV['HIDE_BUSINESS_UNIT_SCORES'] == 'true'
HIDE_CONTROL_COMPLIANCE_TESTS = ENV['HIDE_CONTROL_COMPLIANCE_TESTS'] == 'true'
HIDE_CONTROL_EFFECTS = ENV['HIDE_CONTROL_EFFECTS'] == 'true'
HIDE_CONTROL_OBJECTIVE_ITEM_EFFECTIVENESS = ENV['HIDE_CONTROL_OBJECTIVE_ITEM_EFFECTIVENESS'] == 'true'
HIDE_CONTROL_OBJECTIVE_RISK = ENV['HIDE_CONTROL_OBJECTIVE_RISK'] == 'true'
HIDE_FINDING_CRITERIA_MISMATCH = ENV['HIDE_FINDING_CRITERIA_MISMATCH'] == 'true'
HIDE_OPORTUNITIES = ENV['HIDE_OPORTUNITIES'] == 'true'
HIDE_REVIEW_DESCRIPTION = ENV['HIDE_REVIEW_DESCRIPTION'] == 'true'
HIDE_WEAKNESS_EFFECT = ENV['HIDE_WEAKNESS_EFFECT'] == 'true'
HIDE_WEAKNESS_PRIORITY = ENV['HIDE_WEAKNESS_PRIORITY'] == 'true'
ORDER_REVIEWS_BY = ENV['ORDER_REVIEWS_BY'] || 'conclusion_final_review'
ORDER_WEAKNESSES_ON_CONCLUSION_REVIEWS_BY = ENV['ORDER_WEAKNESSES_ON_CONCLUSION_REVIEWS_BY'] || 'control_objective_items'
ORGANIZATIONS_WITH_BEST_PRACTICE_COMMENTS = String(ENV['ORGANIZATIONS_WITH_BEST_PRACTICE_COMMENTS']).split
ORGANIZATIONS_WITH_CONTROL_OBJECTIVE_COUNTS = String(ENV['ORGANIZATIONS_WITH_CONTROL_OBJECTIVE_COUNTS']).split
ORGANIZATIONS_WITH_REVIEW_SCORE_BY_WEAKNESS = String(ENV['ORGANIZATIONS_WITH_REVIEW_SCORE_BY_WEAKNESS']).split
PLAN_ITEM_REVIEW_CONCLUDED_ON = ENV['PLAN_ITEM_REVIEW_CONCLUDED_ON'] || 'created_at'
SHOW_ALTERNATIVE_QUESTIONNAIRES = ENV['SHOW_ALTERNATIVE_QUESTIONNAIRES'] == 'true'
SHOW_ASSUMED_RISK_AS_REVIEW_PENDING = ENV['SHOW_ASSUMED_RISK_AS_REVIEW_PENDING'] == 'true'
SHOW_CONCLUSION_ALTERNATIVE_PDF = JSON.parse ENV['SHOW_CONCLUSION_ALTERNATIVE_PDF'].presence || '{}'
SHOW_CONCLUSION_AS_OPTIONS = ENV['SHOW_CONCLUSION_AS_OPTIONS'] == 'true'
SHOW_EXTENDED_RISKS = ENV['SHOW_EXTENDED_RISKS'] == 'true'
SHOW_FINDING_CURRENT_SITUATION = ENV['SHOW_FINDING_CURRENT_SITUATION'] == 'true'
SHOW_ORGANIZATION_PREFIX_ON_REVIEW_NOTIFICATION = String(ENV['SHOW_ORGANIZATION_PREFIX_ON_REVIEW_NOTIFICATION']).split
SHOW_REVIEW_AUTOMATIC_IDENTIFICATION = ENV['SHOW_REVIEW_AUTOMATIC_IDENTIFICATION'] == 'true'
SHOW_REVIEW_EXTRA_ATTRIBUTES = ENV['SHOW_REVIEW_EXTRA_ATTRIBUTES'] == 'true'
SHOW_REVIEW_BEST_PRACTICE_COMMENTS = ENV['SHOW_REVIEW_BEST_PRACTICE_COMMENTS'] == 'true'
SHOW_SHORT_QUALIFICATIONS = ENV['SHOW_SHORT_QUALIFICATIONS'] == 'true'
SHOW_WEAKNESS_EXTRA_ATTRIBUTES = ENV['SHOW_WEAKNESS_EXTRA_ATTRIBUTES'] == 'true'
SHOW_WEAKNESS_PROGRESS = ENV['SHOW_WEAKNESS_PROGRESS'] == 'true'
USE_SHORT_RELEVANCE = ENV['USE_SHORT_RELEVANCE'] == 'true'
WEAKNESS_TAG_VALIDATION_START = Timeliness.parse(ENV['WEAKNESS_TAG_VALIDATION_START'], zone: :local)
