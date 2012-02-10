require "bundler/gem_tasks"

task :default => :specs

task :specs do
  system "rspec -c spec"
end

namespace :test_project do
  
  task :reset do
    system "git co -- spec/TestProject"
  end
  
end

