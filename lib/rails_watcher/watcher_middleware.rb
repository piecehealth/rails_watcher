# frozen_string_literal: true
module RailsWatcher
  class WatcherMiddleware
    def initialize app
      @app = app
    end

    def call env
      CallStack.set_instance env["REQUEST_PATH"]
      status, headers, response = nil, nil, nil
      duration = Benchmark.ms { status, headers, response = @app.call env }
      CallStack.clear_instance_and_log duration
      return status, headers, response
    end
  end
end
