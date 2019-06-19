Rails.logger.info 'Starting weekly runner'

Finding.remember_users_about_expiration
Finding.notify_expired_and_stale_follow_up
Finding.remember_users_about_unanswered

Task.remember_users_about_expiration

Rails.logger.info 'Weekly runner finished'
