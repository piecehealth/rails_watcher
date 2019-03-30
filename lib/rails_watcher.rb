# frozen_string_literal: true
require 'rails_watcher/engine'
require 'rails_watcher/configuration'
require 'rails_watcher/const_modifier'
require 'rails_watcher/call_stack'
require 'rails_watcher/patches'
require 'rails_watcher/watcher_middleware'

module RailsWatcher

  autoload :DefaultInstanceHandler, 'rails_watcher/default_instance_handler'

  def self.my_watch_begins
    Kernel.singleton_class.prepend Patches::KernelLoad
  end
end
