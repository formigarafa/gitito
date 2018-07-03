Rails.configuration.instance_eval do
  @gitito = HashWithIndifferentAccess.new YAML.load_file("#{Rails.root}/config/gitito.yml")
end

Rails.configuration.class_eval do
  def gitito
    @gitito[:gitito]
  end
end
