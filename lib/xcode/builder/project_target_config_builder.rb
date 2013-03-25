module Xcode
  module Builder
    class ProjectTargetConfigBuilder < BaseBuilder
        
      def prepare_xcodebuild sdk=nil
        cmd = super sdk
        cmd << "-project \"#{@target.project.path}\""
        cmd << "-target \"#{@target.name}\""
        cmd << "-config \"#{@config.name}\""
        cmd
      end
    end
  end
end