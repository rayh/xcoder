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
    t.files   = ['lib/**/*.rb']   # optional
  end

  # desc "Upload docs to github"
  # task :release => [:generate] do 
  #   `git clone https://rayh@github.com/rayh/xcoder.git doc-deploy`
  #   `cd doc-deploy`
  #   `git checkout gh-pages`
  #   `cp -r ../doc/* .`
  # end
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

