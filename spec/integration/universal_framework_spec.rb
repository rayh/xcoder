require_relative '../spec_helper'

describe "Universal Framework", :integration => true do
  
  let(:project) { Xcode.project 'TestProject' }
  
  it "should install without error" do
    
    project.create_target 'Library' do |target|
      
      target.name = 'Library'
      
      target.create_build_phase :sources do |source|
        source.add_build_file project.file('TestProject/AppDelegate.m')
      end
      
      target.create_build_phase :copy_headers do |headers|
        headers.add_build_file_with_public_privacy project.file('TestProject/AppDelegate.h')
        headers.add_build_file project.file('TestProject/Supporting Files/TestProject-Prefix.pch')
      end
      
      target.create_configurations :release do |config|
        config.always_search_user_paths = false
        config.architectures = [ "$(ARCHS_STANDARD_32_BIT)", 'armv6' ]
        config.copy_phase_strip = true
        config.dead_code_stripping = false
        config.debug_information_format = "dwarf-with-dsym"
        config.c_language_standard = 'gnu99'
        config.enable_objc_exceptions = true
        config.generate_debugging_symbols = false
        config.precompile_prefix_headers = false
        config.gcc_version = 'com.apple.compilers.llvm.clang.1_0'
        config.warn_64_to_32_bit_conversion = true
        config.warn_about_missing_prototypes = true
        config.install_path = "$(LOCAL_LIBRARY_DIR)/Bundles"
        config.link_with_standard_libraries = false
        config.mach_o_type = 'mh_object'
        config.macosx_deployment_target = '10.7'
        config.product_name = '$(TARGET_NAME)'
        config.sdkroot = 'iphoneos'
        config.valid_architectures = '$(ARCHS_STANDARD_32_BIT)'
        config.wrapper_extension = 'framework'
        config.save!
      end
      
    end

    # Release
    # buildSettings = {
    # ALWAYS_SEARCH_USER_PATHS = NO;
    # ARCHS = (
    #   "$(ARCHS_STANDARD_32_BIT)",
    #   armv6,
    # );
    # COPY_PHASE_STRIP = YES;
    # DEAD_CODE_STRIPPING = NO;
    # DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
    # GCC_C_LANGUAGE_STANDARD = gnu99;
    # GCC_ENABLE_OBJC_EXCEPTIONS = YES;
    # GCC_GENERATE_DEBUGGING_SYMBOLS = NO;
    # GCC_PRECOMPILE_PREFIX_HEADER = YES;
    # GCC_PREFIX_HEADER = "Facebook/Facebook-Prefix.pch";
    # GCC_VERSION = com.apple.compilers.llvm.clang.1_0;
    # GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
    # GCC_WARN_ABOUT_MISSING_PROTOTYPES = YES;
    # INFOPLIST_FILE = "Facebook/Facebook-Info.plist";
    # INSTALL_PATH = "$(LOCAL_LIBRARY_DIR)/Bundles";
    # LINK_WITH_STANDARD_LIBRARIES = NO;
    # MACH_O_TYPE = mh_object;
    # MACOSX_DEPLOYMENT_TARGET = 10.7;
    # PRODUCT_NAME = "$(TARGET_NAME)";
    # SDKROOT = iphoneos;
    # VALID_ARCHS = "$(ARCHS_STANDARD_32_BIT)";
    # WRAPPER_EXTENSION = framework;
    # };

  
    # project.create_target('Universal Library',:aggregate) do |target|
    #   
    #   target.name = 'Universal Library'
    #   
    #   target.add_dependency project.target('Library')
    # 
    #   target.create_build_phase :run_script do |script|
    #     script.shell_script = "# Sets the target folders and the final framework product.\nFMK_NAME=Facebook\nFMK_VERSION=A\n\n# Install dir will be the final output to the framework.\n# The following line create it in the root folder of the current project.\nINSTALL_DIR=${SRCROOT}/Products/${FMK_NAME}.framework\n\n# Working dir will be deleted after the framework creation.\nWRK_DIR=build\nDEVICE_DIR=${WRK_DIR}/Release-iphoneos/${FMK_NAME}.framework\nSIMULATOR_DIR=${WRK_DIR}/Release-iphonesimulator/${FMK_NAME}.framework\n\n# Building both architectures.\nxcodebuild -configuration \"Release\" -target \"${FMK_NAME}\" -sdk iphoneos\nxcodebuild -configuration \"Release\" -target \"${FMK_NAME}\" -sdk iphonesimulator\n\n# Cleaning the oldest.\nif [ -d \"${INSTALL_DIR}\" ]\nthen\nrm -rf \"${INSTALL_DIR}\"\nfi\n\n# Creates and renews the final product folder.\nmkdir -p \"${INSTALL_DIR}\"\nmkdir -p \"${INSTALL_DIR}/Versions\"\nmkdir -p \"${INSTALL_DIR}/Versions/${FMK_VERSION}\"\nmkdir -p \"${INSTALL_DIR}/Versions/${FMK_VERSION}/Resources\"\nmkdir -p \"${INSTALL_DIR}/Versions/${FMK_VERSION}/Headers\"\n\n# Creates the internal links.\n# It MUST uses relative path, otherwise will not work when the folder is copied/moved.\nln -s \"${FMK_VERSION}\" \"${INSTALL_DIR}/Versions/Current\"\nln -s \"Versions/Current/Headers\" \"${INSTALL_DIR}/Headers\"\nln -s \"Versions/Current/Resources\" \"${INSTALL_DIR}/Resources\"\nln -s \"Versions/Current/${FMK_NAME}\" \"${INSTALL_DIR}/${FMK_NAME}\"\n\n# Copies the headers and resources files to the final product folder.\ncp -R \"${DEVICE_DIR}/Headers/\" \"${INSTALL_DIR}/Versions/${FMK_VERSION}/Headers/\"\ncp -R \"${DEVICE_DIR}/\" \"${INSTALL_DIR}/Versions/${FMK_VERSION}/Resources/\"\n\n# Removes the binary and header from the resources folder.\nrm -r \"${INSTALL_DIR}/Versions/${FMK_VERSION}/Resources/Headers\" \"${INSTALL_DIR}/Versions/${FMK_VERSION}/Resources/${FMK_NAME}\"\n\n# Uses the Lipo Tool to merge both binary files (i386 + armv6/armv7) into one Universal final product.\nlipo -create \"${DEVICE_DIR}/${FMK_NAME}\" \"${SIMULATOR_DIR}/${FMK_NAME}\" -output \"${INSTALL_DIR}/Versions/${FMK_VERSION}/${FMK_NAME}\"\n\nrm -r \"${WRK_DIR}\""
    #   end
    # 
    # end
  
    project.save!
  end

end