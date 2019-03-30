# frozen_string_literal: true
module RailsWatcher
  class Engine < ::Rails::Engine
    isolate_namespace RailsWatcher

    if ENV["RAILS_WATCHER"] == 'true'

      initializer "rails_watcher.middleware" do |app|
        app.config.app_middleware.use RailsWatcher::WatcherMiddleware
      end

      initializer "rails_watcher.modify_rails_methods" do
        ActiveSupport.on_load(:action_controller) do
          prepend Patches::ActionControllerRender
        end

        ActiveSupport.on_load(:action_view) do
          prepend Patches::ActionViewRender
        end
      end

      config.after_initialize do
        RailsWatcher.my_watch_begins

        %w[render_template.action_view render_partial.action_view render_collection.action_view].each do |event_type|
          ActiveSupport::Notifications.subscribe(event_type) do |*args|
            call_stack = RailsWatcher::CallStack.get_instance
            next unless call_stack
            event = ActiveSupport::Notifications::Event.new *args
            payload = event.payload
            payload[:identifier] = payload[:identifier].sub(Rails.root.to_s, "")
            call_stack.log_render_stack event_type, event.duration, payload
          end
        end

        ActiveSupport::Notifications.subscribe('cache_read.active_support') do |*args|
          call_stack = RailsWatcher::CallStack.get_instance
          next unless call_stack
          event = ActiveSupport::Notifications::Event.new *args

          call_stack.log_catche_read event.duration, event.payload
        end

        ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
          call_stack = RailsWatcher::CallStack.get_instance
          next unless call_stack
          event = ActiveSupport::Notifications::Event.new *args

          call_stack.log_db_query event.duration, event.payload
        end

        RailsWatcher.configuration.rails_methods_i_want_to_watch.each do |component, instance_methods|
          ActiveSupport.on_load(component) do
            patch = Module.new do
              instance_methods.each do |method_name|
                define_method(method_name) do |*args, &blk|
                  call_stack = RailsWatcher::CallStack.get_instance
                  return super(*args, &blk) unless call_stack

                  ret = nil
                  call_stack.log_method_call("#{component}##{method_name}") do
                    ret = super(*args, &blk)
                  end
                  ret
                end
              end
            end
            prepend patch
          end
        end
      end
    end
  end
end
