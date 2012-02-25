require "bundler/gem_tasks"
require "yard"
require "yard/rake/yardoc_task"

task :default => [:specs, :build]

task :specs do
  system "rspec --color --format d --tag ~integration"
end

task :integration do
  system "rspec --color --format d --tag integration"
end

namespace :doc do 
  desc "Generate YARD docs"
  YARD::Rake::YardocTask.new(:generate) do |t|
    t.files   = ['lib/**/*.rb',  '-', 'README.md']   # optional
    t.options = ["-o ../xcoder-doc"]
  end
end

task :reset => ['test_project:reset']

namespace :test_project do
  
  task :reset do
    puts "Reseting the TestProject Project File"
    system "git co -- spec/TestProject"
    puts "Removing any User schemes generated in the project"
    system "rm -rf spec/TestProject/TestProject.xcodeproj/xcuserdata"
    puts "Removing any installed files"
    system "git clean -df spec/TestProject"
  end
  
end


require './lib/xcoder/rake_task'

Xcode::RakeTask.new :xcode do |xcoder|
  xcoder.directory = 'spec'
end
