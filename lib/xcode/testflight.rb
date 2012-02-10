require 'rest-client'
require 'json'

module Xcode
  class Testflight
    attr_accessor :api_token, :team_token, :notify, :proxy, :notes, :lists
    
    def initialize(api_token, team_token)
      @api_token = api_token
      @team_token = team_token
      @notify = true
      @notes = nil
      @lists = []
    end
    
    def upload(ipa_path, dsymzip_path=nil)
      # cmd = []
      RestClient.proxy = @proxy || ENV['http_proxy'] || ENV['HTTP_PROXY']
      RestClient.log = '/tmp/restclient.log'
      
      puts "Uploading to Testflight..."
      response = RestClient.post('http://testflightapp.com/api/builds.json',
        :file => File.new(ipa_path),
        :dsym => File.new(dsymzip_path),
        :api_token => @api_token,
        :team_token => @team_token,
        :notes => @notes,
        :notify => @notify ? 'True' : 'False',
        :distribution_lists => @lists.join(',')
      )
      
      json = JSON.parse(response)
      puts " + Done, got: #{json.inspect}"
      json
    end
  end
end