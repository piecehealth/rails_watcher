# frozen_string_literal: true
module RailsWatcher
  module Patches
    module KernelLoad
      def load filename, wrap=false
        ret = super

        relative_path = begin
                          pn = Pathname.new filename
                          pn.relative_path_from(Rails.root).to_s
                        end

        if !RailsWatcher.configuration.ignored_files.include?(relative_path) &&
            !RailsWatcher.configuration.ignored_paths.any? { |ignored_path| relative_path.start_with?(ignored_path) }

          const_name = RailsWatcher.configuration.file_constant_mapping[relative_path] ||
                            RailsWatcher.guess_const_name(relative_path)

          if (Object.const_defined?(const_name) rescue return ret)
            ConstModifier.modify const_name, filename
          elsif Object.const_defined? const_name.upcase
            ConstModifier.modify const_name.upcase, filename
          else
            warn <<~WARNING
            ============== Rails Watcher Warning ==============
            Find constant failed:
            File path:            "#{relative_path}"
            Guessed const name:   "#{const_name}"
            ============== Rails Watcher Warning ==============
            WARNING
          end
        end

        ret
      end
    end # module KernelLoad

    module ActionControllerRender
      def render *args
        call_stack = RailsWatcher::CallStack.get_instance
        if call_stack
          ret = nil
          method_tag = "render"
          call_stack.log_method_call method_tag do
            ret = super
          end
          ret
        else
          super
        end
      end
    end

    module ActionViewRender
      def render options = {}, locals = {}, &block
        call_stack = RailsWatcher::CallStack.get_instance
        if call_stack
          ret = nil
          method_tag = "render_partial (#{options})"
          call_stack.log_method_call method_tag do
            ret = super
          end
          ret
        else
          super
        end
      end
    end
  end


  def self.guess_const_name file_path
    @@load_paths ||=  (
                        Rails.application.config.autoload_paths +
                        Rails.application.config.eager_load_paths
                      ).map do |autoload_path|
                        pn = Pathname.new autoload_path
                        pn.relative_path_from(Rails.root).to_s + "/"
                      end.to_set

    @@load_paths.reduce(file_path) do |truncated_file_path, load_path|
      truncated_file_path
        .sub(/^#{load_path}/, "")
        .sub(/^concerns/, "")
        .sub(/\.rb$/, "")
    end.camelize
  end
end
