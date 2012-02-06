# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'rspec', :version => 2, :cli => "--color --format d --fail-fast" do
  watch(%r{^spec/.+_spec\.rb$})
  # As the registry and resource file affect most every file, the entire
  # suite should be run when they are changed
  watch(%r{^lib/xcode/(?:registry|resource)\.rb$}) { "spec" }
  watch(%r{^lib/xcode/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }

end

