# frozen_string_literal: true
module RailsWatcher
  module DefaultInstanceHandler
    def self.log call_stack_instacne
      # save files in a new thread
      # so that won't slow down the main thread
      Thread.new do
        @output_path ||= File.join(Rails.root, "tmp/rails_watcher")
        now = Time.now
        folder_name = "#{now.strftime("%Y%m%d_%H%M%S")}|#{call_stack_instacne.request_path.gsub("/", "_")}"

        path = File.join(@output_path, folder_name)
        FileUtils.mkdir_p path

        %w[stack method_call_table db_query_table read_cache_table render_stack].each do |var|
          filename = File.join path, "#{var}.json"
          File.open(filename, 'w') do |f|
            f.puts call_stack_instacne.instance_variable_get(:"@#{var}").to_json
          end
        end

        summary_file = File.join path, "summary.json"
        File.open(summary_file, 'w') do |f|
          summary = {
            duration:     call_stack_instacne.duration,
            request_path: call_stack_instacne.request_path,
            logged_time:  now
          }
          f.puts summary.to_json
        end
      end
    end
  end
end
