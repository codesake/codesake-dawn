Given /^the generic project "(.*?)" doesn't exist$/ do |file|
  FileUtils.rm(file) if File.exists?(file)
end

Given /^the hello world rails project does exist$/ do
  system("rm -rf /tmp/hello_world_3.2.13")
  system("cp -a ./spec/support/hello_world_3.2.13 /tmp") 
end

Given /^a safe sinatra application exists$/ do
  system("rm -rf /tmp/sinatra-safe")
  system("cp -a ./spec/support/sinatra-safe /tmp") 

end

