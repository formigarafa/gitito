Rails.configuration.instance_eval do 
	@gitito = HashWithIndifferentAccess.new YAML.load_file("#{Rails.root}/config/gitito.yml")
end

Rails.configuration.class_eval do 
	def gitito
		@gitito[:gitito]
	end
end

# Gitito::Application.config.after_initialize do
#   Gitito::Application.configure do
#     config.action_mailer.default_url_options = { :host => Rails.configuration.gitito[:web_host] }
#   end
# end
