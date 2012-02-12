require "bundler/gem_tasks"

task :default => [:specs, :build]

task :specs do
  system "rspec --color --format d --tag ~integration"
end

task :integration do
  system "rspec --color --format d --tag integration"
end


task :reset => ['test_project:reset']

namespace :test_project do
  
  task :reset do
    puts "Reseting the TestProject Project File"
    system "git co -- spec/TestProject"
    puts "Removing any User schemes generated for in the project"
    system "rm -rf spec/TestProject/TestProject.xcodeproj/xcuserdata"
    puts "Removing any installed files"
    system "git clean -df spec/TestProject"
  end
  
end

