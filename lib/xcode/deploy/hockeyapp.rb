require 'rest-client'

module Xcode
  module Deploy
    class Hockeyapp
      attr_accessor :app_id, :hockeyapp_token, :status, :notify, :proxy, :notes, :notes_type, :lists, :builder, :tags, :teams, :users
      @@defaults = {}

      def self.defaults(defaults={})
        @@defaults = defaults
      end

      def initialize(builder, options={})
        @builder = builder
        @api_token = options[:app_id]||@@defaults[:app_id]
        @team_token = options[:hockeyapp_token]||@@defaults[:hockeyapp_token]
        @status = options[:status]
        @notify = options[:notify]
        @notes = options[:notes]
        @notes_type = options[:notes_type]
        @tags = options[:tags]||[]
        @teams = options[:teams]||[]
        @users = options[:users]||[]
        @proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']
      end

      def deploy
        puts "Uploading to HockeyApp..."

        # RestClient.proxy = @proxy || ENV['http_proxy'] || ENV['HTTP_PROXY']
        # RestClient.log = '/tmp/restclient.log'
        #
        # response = RestClient.post('http://testflightapp.com/api/builds.json',
        #   :file => File.new(builder.ipa_path),
        #   :dsym => File.new(builder.dsym_zip_path),
        #   :api_token => @api_token,
        #   :team_token => @team_token,
        #   :notes => @notes,
        #   :notify => @notify ? 'True' : 'False',
        #   :distribution_lists => @lists.join(',')
        # )
        #
        # json = JSON.parse(response)
        # puts " + Done, got: #{json.inspect}"
        # json


        curl \
  -F "status=2" \
  -F "notify=1" \
  -F "notes=Some new features and fixed bugs." \
  -F "notes_type=0" \
  -F "ipa=@hockeyapp.ipa" \
  -F "dsym=@hockeyapp.dSYM.zip" \
  -H "X-HockeyAppToken: 4567abcd8901ef234567abcd8901ef23" \


        cmd = Xcode::Shell::Command.new 'curl'
        cmd << "--proxy #{@proxy}" unless @proxy.nil? or @proxy==''
        cmd << "-X POST https://rink.hockeyapp.net/api/2/apps/#{@app_id}/app_versions/upload"
        cmd << "-F ipa=@\"#{@builder.ipa_path}\""
        cmd << "-F dsym=@\"#{@builder.dsym_zip_path}\"" unless @builder.dsym_zip_path.nil?
        cmd << "-F notes=\"#{@notes}\"" unless @notes.nil?
        cmd << "-F distribution_lists='#{@lists.join(',')}'" unless @lists.count==0

        response = cmd.execute

        json = MultiJson.load(response.join(''))
        puts " + Done, got: #{json.inspect}"

        yield(json) if block_given?

        json
      end
    end
  end
end
