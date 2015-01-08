require 'rest-client'

module Xcode
  module Deploy
    class Hockeyapp
      attr_accessor :app_id, :hockeyapp_token, :status, :notify, :proxy, :notes, :notes_type, :builder, :tags, :teams, :users
      @@defaults = {}

      def self.defaults(defaults={})
        @@defaults = defaults
      end

      def initialize(builder, options={})
        @builder = builder
        @app_id = options[:app_id]||@@defaults[:app_id]
        @hockeyapp_token = options[:hockeyapp_token]||@@defaults[:hockeyapp_token]
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



        cmd = Xcode::Shell::Command.new 'curl'
        cmd << "--proxy #{@proxy}" unless @proxy.nil? or @proxy==''
        cmd << "-X POST https://rink.hockeyapp.net/api/2/apps/#{@app_id}/app_versions/upload"
        cmd << "-F ipa=@\"#{@builder.ipa_path}\""
        cmd << "-F dsym=@\"#{@builder.dsym_zip_path}\"" unless @builder.dsym_zip_path.nil?
        cmd << "-F notes=\"#{@notes}\"" unless @notes.nil?
        cmd << "-F notify=\"#{@notify}\"" unless @notify.nil?
        cmd << "-F status=\"#{@status}\"" unless @status.nil?
        cmd << "-F notes_type=\"#{@notes_type}\"" unless @notes_type.nil?
        cmd << "-F tags='#{@tags.join(',')}'" unless @tags.count==0
        cmd << "-F teams='#{@teams.join(',')}'" unless @teams.count==0
        cmd << "-F users='#{@users.join(',')}'" unless @users.count==0
        cmd << "-H \"X-HockeyAppToken: #{@hockeyapp_token}\""

        response = cmd.execute

        json = MultiJson.load(response.join(''))
        puts " + Done, got: #{json.inspect}"

        yield(json) if block_given?

        json
      end
    end
  end
end
