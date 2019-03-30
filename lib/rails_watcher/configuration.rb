# frozen_string_literal: true
module RailsWatcher

  class Configuration
    attr_accessor *%i[
      ignored_files
      ignored_constants
      ignored_paths
      ignored_methods
      ignored_request_path
      file_constant_mapping
      output_path
      request_duration_threshold
      rails_methods_i_want_to_watch
      instance_handler
    ]

    def initialize
      @ignored_files = []
      @ignored_constants = []
      @ignored_paths = []
      @ignored_methods = {}
      @file_constant_mapping = {}
      @output_path = File.join(Rails.root, "tmp/rails_watcher")
      @ignored_request_path = []
      @request_duration_threshold = 10 # ms
      @rails_methods_i_want_to_watch = {}
      @instance_handler = "RailsWatcher::DefaultInstanceHandler"
    end
  end

  def self.configuration
    @@configuration ||= RailsWatcher::Configuration.new
    if block_given?
      yield @@configuration
    else
      @@configuration
    end
  end

end
