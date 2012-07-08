require 'open-uri'
require 'json'
require 'openssl'
require 'logger'
require 'aws/s3'

# Hack to skip ssl certificate validation error with github api
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

FILENAME = "output.json"
S3_BUCKET = 's3.alfajango.com'
S3_FILENAME = 'os-projects-downloads.json' # or simply, FILENAME
SLEEP = 1.0

PROJECTS = {
  :'jquery-ujs' => {
    services: {
      github: 'rails/jquery-ujs'
    }
  },
  :'jquery-rails' => {
    services: {
      rubygems: 'jquery-rails-1.0',
      github: 'rails/jquery-rails'
    }
  },
  :'remotipart' => {
    services: {
      rubygems: 'remotipart-1.0',
      github: 'JangoSteve/remotipart'
    }
  },
  easytabs: {
    services: {
      jspkg: 'easytabs',
      github: 'JangoSteve/jQuery-EasyTabs'
    }
  },
  dynatable: {
    services: {
      github: 'JangoSteve/jquery-dynatable',
      jspkg: 'dynatable'
    }
  },
  :'css-emoticons' => {
    services: {
      github: 'JangoSteve/jQuery-CSSEmoticons',
      jspkg: 'css-emoticons'
    }
  },
  :'sinatra-mvc' => {
    services: {
      github: 'JangoSteve/heroku-sinatra-app'
    }
  },
  :'rails-jquery-demo' => {
    services: {
      github: 'JangoSteve/Rails-jQuery-Demo'
    }
  }
}

LOGGER = Logger.new("#{FILENAME}.log", 'monthly')

LOGGER.info "Starting import..."

output = {}.tap do |out|
  PROJECTS.each do |project, project_hash|
    LOGGER.debug "for #{project}"
    out[project.to_s] = {}
    project_hash[:services].each do |service, value|
      LOGGER.debug"[#{service}]"
      uri = case
      when service == :rubygems
        "http://rubygems.org/api/v1/downloads/#{value}.json"
      when service == :jspkg
        "http://jspkg.com/packages/#{value}/downloads.json"
      when service == :github
        "https://api.github.com/repos/#{value}"
      end

      begin
        json = URI.parse(uri).open.read
        parsed_json = JSON.parse(json)

        out[project.to_s][service.to_s] = parsed_json.select { |k,v| %w(watchers forks total_downloads).include?(k) }
      rescue Exception => e
        LOGGER.error "Encountered exception, skipping #{project}[#{service}]: #{e}"
        next
      end
    end
    sleep SLEEP
  end
end

LOGGER.debug "Writing file"
File.open(FILENAME, 'w') { |f|
  f.write('setJSON(' + output.to_json + ');')
}

LOGGER.info "Uploading to S3..."
AWS::S3::Base.establish_connection!(
  :access_key_id     => ENV['AWS_ACCESS_KEY'],
  :secret_access_key => ENV['AWS_SECRET_KEY']
)
AWS::S3::S3Object.store(
  S3_FILENAME,
  open(FILENAME),
  S3_BUCKET,
  content_type: 'application/javascript',
  access: :public_read
)

LOGGER.info "Done!"
