# frozen_string_literal: true
module RailsWatcher
  class CallStack
    class << self
      def get_instance
        Thread.current[:rails_watcher_call_stack_instance]
      end

      def set_instance request_path
        Thread.current[:rails_watcher_call_stack_instance] = self.new request_path
      end

      def clear_instance_and_log duration
        instance = self.get_instance
        if duration > RailsWatcher.configuration.request_duration_threshold &&
            RailsWatcher.configuration.ignored_request_path.all? { |path| path !~ instance.request_path }

          if instance.stack.present?
            instance.duration = duration
            handler = RailsWatcher.configuration.instance_handler
            handler = handler.constantize if handler.is_a? String

            handler.log instance
          end
        end
        Thread.current[:rails_watcher_call_stack_instance] = nil
      end
    end

    attr_reader :request_path, :stack, :method_call_table
    attr_reader :db_query_table, :read_cache_table, :render_stack
    attr_accessor :duration

    def initialize request_path
      @request_path = request_path
      @stack = []
      @current_stack = []
      @method_call_table = {}
      @db_query_table = {}
      @read_cache_table = {}
      @render_stack = []
    end

    # def save
    #   folder_name = "#{Time.now.strftime("%Y%m%d_%H%M%S")}|#{@duration}|#{@request_path.gsub("/", "\\")}"
    #   path = File.join(RailsWatcher.configuration.output_path, folder_name)
    #   FileUtils.mkdir_p path
    #   %w[stack method_call_table db_query_table read_cache_table render_stack].each do |var|
    #     filename = File.join path, "#{var}.json"
    #     File.open(filename, 'w') { |f| f.puts instance_variable_get(:"@#{var}").to_json }
    #   end
    # end

    def log_method_call tag, &blk
      id = SecureRandom.hex(10)

      @method_call_table[id] = { tag: tag, children: [] }
      parent_method_call = @current_stack.last
      if parent_method_call
        @method_call_table[parent_method_call][:children] << id
      else
        @stack << id
      end

      @current_stack.push id
      duration = Benchmark.ms &blk
      @method_call_table[id][:duration] = duration
      @current_stack.delete id
    end

    def log_render_stack event_type, duration, payload
      @render_stack << [event_type, duration, payload]
    end

    def log_db_query duration, payload
      current_method_call = @current_stack.last
      @db_query_table[current_method_call] ||= []
      payload[:duration] = duration
      @db_query_table[current_method_call] << payload
    end

    def log_catche_read duration, payload
      current_method_call = @current_stack.last
      @read_cache_table[current_method_call] ||= []
      payload[:duration] = duration
      @read_cache_table[current_method_call] << payload
    end
  end
end
