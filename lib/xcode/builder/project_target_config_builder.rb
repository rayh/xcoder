module Xcode
  module Builder
    class ProjectTargetConfigBuilder < BaseBuilder
        
      def xcodebuild
        cmd = super
        cmd << "-project \"#{@target.project.path}\""
        cmd << "-target \"#{@target.name}\""
        cmd << "-config \"#{@config.name}\""
        cmd
      end
    end
  end
end