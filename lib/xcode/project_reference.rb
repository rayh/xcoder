module Xcode
  
  module ProjectReference
    
    #
    # Returns the group specified. If any part of the group does not exist along
    # the path the group is created. Also paths can be specified to make the 
    # traversing of the groups easier.
    # 
    # @note this will attempt to find the paths specified, if it fails to find them
    #   it will create one and then continue traversing.
    #
    # @example Traverse a path through the various sub-groups.
    # 
    #     project.group('Vendor/MyCode/Support Files')
    #     # is equivalent to ...
    #     project.group('Vendor').first.group('MyCode').first.group('Supporting Files')
    # 
    # @note this path functionality current is only exercised from the project level
    #   all groups will treat the path division `/` as simply a character.
    # 
    # @param [String] name the group name to find/create
    # 
    # @return [Group] the group with the specified name.
    # 
    def group(name,options = {},&block)
      # By default create missing groups along the way
      options = { :create => true }.merge(options)
      
      current_group = main_group
      
      # @todo consider this traversing and find/create as a normal procedure when
      #   traversing the project.
      
      name.split("/").each do |path_component|
        found_group = current_group.group(path_component).first
        
        if options[:create] and found_group.nil?
          found_group = current_group.create_group(path_component)
        end
        
        current_group = found_group
        
        break unless current_group
      end
      
      current_group.instance_eval(&block) if block_given? and current_group
      
      current_group
    end
    
    
    
  end
end