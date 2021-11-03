require 'rails'
require 'active_record'
require 'git'

module Modulorails
  # Author: Matthieu 'ciappa_m' Ciappara
  # This holds the data gathered by the gem. Some come from the configuration by the gem's user.
  # Some are fetched dynamically.
  class Data
    # All the data handled by this class
    ATTRIBUTE_KEYS = %i[
      name main_developer project_manager repository type rails_name ruby_version rails_version
      bundler_version modulorails_version adapter db_version adapter_version
    ].freeze

    # Useful if the gem's user need to read one of the data
    attr_reader *ATTRIBUTE_KEYS

    def initialize
      # Get the gem's configuration to get the application's usual name, main dev and PM
      configuration = Modulorails.configuration
      # Get the database connection to identify the database used by the application
      # or return nil if the database does not exist
      db_connection = begin
                        ActiveRecord::Base.connection
                      rescue ActiveRecord::NoDatabaseError => e
                        $stderr.puts("[Modulorails] Error: #{e.message}")
                        nil
                      end
      # Get the gem's specifications to fetch the versions of critical gems
      loaded_specs = Gem.loaded_specs

      # The three data written by the user in the configuration
      # The name is the usual name of the project, the one used in conversations at Modulotech
      @name = configuration.name
      # The main developer, the lead developer, in short the developer to call when something's
      # wrong with the application ;)
      @main_developer = configuration.main_developer
      # The project manager of the application; the other person to call when something's wrong with
      # the application ;)
      @project_manager = configuration.project_manager

      # @author RICHARD Peter <richar_p@modulotech.fr>
      # The project_access configuration key must contain an hash with in keys
      # all productions url and in value all api_key for
      # this instance.
      # Example :
      ## {
      ##    "https://server01.com/"     => "API_KEY01",
      ##    "https://www.server02.fr"   => "API_KEY02",
      ##    "https://www.server03.net/" => "API_KEY03",
      ##    "https://server04.io"       => "API_KEY04"
      ## }
      @project_access = configuration.project_access

      # Theorically, origin is the main repository of the project and git is the sole VCS we use
      # at Modulotech
      @repository = Git.open(::Rails.root).config('remote.origin.url')

      # The API can handle more project types but this gem is (obviously) intended for Rails
      # projects only
      @type = 'rails'

      # The name defined for the Rails application; it can be completely different from the usual
      # name or can be the same
      @rails_name = ::Rails.application.class.name.split('::').first

      # The Ruby version used by the application
      @ruby_version = RUBY_VERSION

      # The Rails version used by the application
      @rails_version = loaded_specs['rails'].version.version

      # The bundler version used by the application (especially useful since Bundler 2 and
      # Bundler 1 are not compatible)
      @bundler_version = loaded_specs['bundler'].version.version

      # The version of the gem
      @modulorails_version = Modulorails::VERSION

      # The name of the ActiveRecord adapter; it gives the name of the database system too
      @adapter = db_connection&.adapter_name&.downcase

      # The version of the database engine; this request works only on MySQL and PostgreSQL
      # It should not be a problem since those are the sole database engines used at Modulotech
      @db_version = db_connection&.select_value('SELECT version()')

      # The version of the ActiveRecord adapter
      @adapter_version = loaded_specs[@adapter]&.version&.version
    end

    # @author Matthieu 'ciappa_m' Ciappara
    # @return [String] Text version of the data
    def to_s
      ATTRIBUTE_KEYS.map { |key| "#{key}: #{send(key)}" }.join(', ')
    end

    # @author Matthieu 'ciappa_m' Ciappara
    # @return [Hash] The payload for the request to the intranet
    def to_params
      {
        'name'            => @name,
        'main_developer'  => @main_developer,
        'project_manager' => @project_manager,
        'repository'      => @repository,
        'app_type'        => @type,
        'project_data'    => {
          'name'                => @rails_name,
          'ruby_version'        => @ruby_version,
          'rails_version'       => @rails_version,
          'bundler_version'     => @bundler_version,
          'modulorails_version' => @modulorails_version,
          'project_access'      => @project_access,
          'database'            => {
            'adapter'     => @adapter,
            'db_version'  => @db_version,
            'gem_version' => @adapter_version
          }
        }
      }
    end
  end
end
