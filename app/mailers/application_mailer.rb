class ApplicationMailer < ActionMailer::Base
  default from: -> { Rails.configuration.gitito[:mailer_sender] }
  layout "mailer"
end
