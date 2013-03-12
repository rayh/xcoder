require 'rest-client'

module Xcode
  module Deploy
    class Testflight
      attr_accessor :api_token, :team_token, :notify, :proxy, :notes, :lists
      @@defaults = {}

      def self.defaults(defaults={})
        @@defaults = defaults
      end

      def initialize(builder, options={})
        @builder = builder
        @api_token = options[:api_token]||@@defaults[:api_token]
        @team_token = options[:team_token]||@@defaults[:team_token]
        @notify = options[:notify]||true
        @notes = options[:notes]
        @lists = options[:lists]||[]
        @proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']
      end

      def deploy
        puts "Uploading to Testflight..."

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
        cmd << "-X POST http://testflightapp.com/api/builds.json"
        cmd << "-F file=@\"#{@builder.ipa_path}\""
        cmd << "-F dsym=@\"#{@builder.dsym_zip_path}\"" unless @builder.dsym_zip_path.nil?
        cmd << "-F api_token='#{@api_token}'"
        cmd << "-F team_token='#{@team_token}'"
        cmd << "-F notes=\"#{@notes}\"" unless @notes.nil?
        cmd << "-F notify=#{@notify ? 'True' : 'False'}"
        cmd << "-F distribution_lists='#{@lists.join(',')}'" unless @lists.count==0

        response = Xcode::Shell.execute(cmd)

        json = MultiJson.load(response.join(''))
        puts " + Done, got: #{json.inspect}"

        yield(json) if block_given?

        json
      end
    end
  end
end
