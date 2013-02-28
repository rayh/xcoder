module Xcode  
  
  class Workspace
    def to_xcodebuild_option
      "-workspace \"#{self.path}\""
    end
  end
  
  class Project
    def to_xcodebuild_option
      "-project \"#{self.path}\""
    end
  end
  
  module Builder
    class SchemeBuilder < BaseBuilder
  
      def initialize(scheme)
        @scheme     = scheme
        target = @scheme.build_targets.last
        super target, target.config(@scheme.build_config)
      end
        
      def xcodebuild
        cmd = super
        cmd << @scheme.parent.to_xcodebuild_option        
        cmd << "-scheme \"#{@scheme.name}\""
        cmd
      end
      
    end
  end
end