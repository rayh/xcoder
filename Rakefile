require "bundler/gem_tasks"

task :default => :specs

task :specs do
  system "rspec -c spec"
end


task :reset => ['test_project:reset']

namespace :test_project do
  
  task :reset do
    puts "Reseting the TestProject Project File"
    system "git co -- spec/TestProject"
    puts "Removing any User schemes in the project"
    system "rm -rf spec/TestProject/TestProject.xcodeproj/xcuserdata"
  end
  
end

