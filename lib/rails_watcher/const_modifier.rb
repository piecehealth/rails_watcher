# frozen_string_literal: true
module RailsWatcher
  class ConstModifier

    def self.modify const_name, file_path
      @instance ||= self.new
      @instance.modify const_name, file_path
    end

    def modify const_name, file_path
      const = const_name.constantize rescue return
      configuration = RailsWatcher.configuration

      ignored_methods = configuration.ignored_methods.with_indifferent_access

      instance_methods_module = Module.new do
        %w[public private protected].each do |method_type|
          const.send(:"#{method_type}_instance_methods", false).each do |method_name|
            source_code_file_path, _line_no = const.instance_method(method_name).source_location
            next unless source_code_file_path == file_path
            next if ignored_methods.dig(const_name, method_type)&.include?(method_name)
            next if ignored_methods["WeirdMethods"]&.include?(method_name)

            define_method method_name do |*args, &blk|
              call_stack = RailsWatcher::CallStack.get_instance
              if call_stack
                ret = nil
                method_tag = "#{const_name}##{method_name}"
                call_stack.log_method_call method_tag do
                  ret = super(*args, &blk)
                end
                ret
              else
                super(*args, &blk)
              end
            end
            __send__(method_type, method_name)
          end
        end       # %w[public private protected].each do |method_type|
      end         # instance_methods_module = Module.new do

      const.prepend instance_methods_module

      # modifiy class methodes
      private_class_methods = []

      const.singleton_class.class_eval do
        %w[public private].each do |method_type|
          const.send(:"#{method_type}_methods", false).each do |method_name|
            source_code_file_path, _line_no = const.method(method_name).source_location
            next unless source_code_file_path == file_path
            next if ignored_methods.dig(const_name, :"class_#{method_type}")&.include?(method_name)
            next if ignored_methods["WeirdMethods"]&.include?(method_name)

            aliased_method_name = :"origin_#{method_name}__rails_watcher"
            alias_method aliased_method_name ,method_name

            define_method method_name do |*args, &blk|
              call_stack = RailsWatcher::CallStack.get_instance
              if call_stack
                ret = nil
                method_tag = "#{const_name}.#{method_name}"
                call_stack.log_method_call method_tag do
                  ret = __send__(aliased_method_name, *args, &blk)
                end
                return ret
              else
                __send__(aliased_method_name, *args, &blk)
              end
            end
            private_class_methods << method_name if method_type == :private

          end
        end
      end

      const.class_eval { private_class_method *private_class_methods } if private_class_methods.present?
    end
  end

end
