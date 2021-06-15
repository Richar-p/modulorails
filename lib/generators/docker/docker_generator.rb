# frozen_string_literal: true

require 'rails/generators'

class DockerGenerator < Rails::Generators::Base
  source_root File.expand_path('templates', __dir__)
  desc 'This generator creates Dockerfiles for an app'

  def create_config_file
    template 'Dockerfile'
    template 'Dockerfile.prod'
    template 'docker-compose.yml'
    template 'docker-compose.prod.yml'
    template 'entrypoints/docker-entrypoint.sh'
    template 'config/database.yml'
    insert_into_file "config/environments/developmebnt.rb", after: "Rails.application.configure do\n" do
      "config.action_mailer.delivery_method = :smtp
config.action_mailer.perform_deliveries = true
config.action_mailer.smtp_settings = { address: 'mailcatcher' }"
    end

  rescue StandardError => e
    $stderr.puts("[Modulorails] Error: cannot generate Docker configuration: #{e.message}")
  end
end
