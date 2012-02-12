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
      @proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']
    end
    
    def upload(ipa_path, dsymzip_path=nil)
      puts "Uploading to Testflight..."
      
      # RestClient.proxy = @proxy || ENV['http_proxy'] || ENV['HTTP_PROXY']
      # RestClient.log = '/tmp/restclient.log'
      # 
      # response = RestClient.post('http://testflightapp.com/api/builds.json',
      #   :file => File.new(ipa_path),
      #   :dsym => File.new(dsymzip_path),
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
      
      cmd = []
      cmd << 'curl'
      cmd << "--proxy #{@proxy}" unless @proxy.nil? or @proxy=='' 
      cmd << "-X POST http://testflightapp.com/api/builds.json"
      cmd << "-F file=@\"#{ipa_path}\""
      cmd << "-F dsym=@\"#{dsymzip_path}\"" unless dsymzip_path.nil?
      cmd << "-F api_token='#{@api_token}'"
      cmd << "-F team_token='#{@team_token}'"
      cmd << "-F notes=\"#{@notes}\"" unless @notes.nil?
      cmd << "-F notify=#{@notify ? 'True' : 'False'}"
      cmd << "-F distribution_lists='#{@lists.join(',')}'" unless @lists.count==0
      
      response = Xcode::Shell.execute(cmd)
      
      json = JSON.parse(response.join(''))
      puts " + Done, got: #{json.inspect}"
      json
    end
  end
end