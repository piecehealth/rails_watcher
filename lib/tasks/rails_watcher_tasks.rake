namespace :rails_watcher do
  desc "Initialize rails watcher configuration file"
  task :install do
    template = File.join(__dir__, 'configuration.rb.tmp')
    target_file = File.join(Rails.root, "config/initializers/rails_watcher_config.rb")
    FileUtils.cp template, target_file
    puts "Done: generated #{target_file}"
  end
end
