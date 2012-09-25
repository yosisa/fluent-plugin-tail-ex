module Fluent
  require 'fluent/plugin/in_tail'

  class TailExInput < TailInput
    Plugin.register_input('tail_ex', self)

    def initialize
      super
    end

    def configure(conf)
      super
    end

    def start
      super
    end

    def shutdown
      super
    end
  end
end
