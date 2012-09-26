module Fluent
  require 'fluent/plugin/in_tail'

  class TailExInput < TailInput
    Plugin.register_input('tail_ex', self)

    config_param :expand_date, :bool, :default => true
    config_param :read_all, :bool, :default => true
    config_param :refresh_interval, :integer, :default => 3600

    def initialize
      super
    end

    def configure(conf)
      super
      @tag_prefix = @tag
      @watchers = {}
      @refresh_trigger = TailWatcher::TimerWatcher.new(@refresh_interval, true, &method(:refresh_watchers))
    end

    def expand_paths
      paths = []
      for path in @paths
        if @expand_date
          path = Time.now.strftime(path)
        end
        paths += Dir.glob(path)
      end
      paths
    end

    def refresh_watchers
      paths = expand_paths
      missing = @watchers.keys - paths
      added = paths - @watchers.keys

      stop_watch(missing) unless missing.empty?
      start_watch(added) unless added.empty?
    end

    def start_watch(paths)
      paths.each do |path|
        pe = @pf ? @pf[path] : NullPositionEntry.instance
        if @read_all
          inode = File::Stat.new(path).ino
          if pe.read_inode == 0
            pe.update(inode, 0)
          end
        end

        watcher = TailExWatcher.new(path, @rotate_wait, pe, &method(:receive_lines))
        watcher.attach(@loop)
        @watchers[path] = watcher
      end
    end

    def stop_watch(paths)
      paths.each do |path|
        watcher = @watchers.delete(path)
        if watcher
          watcher.close(@loop)
        end
      end
    end

    def receive_lines(lines, tag)
      @tag = @tag_prefix + '.' + tag
      super(lines)
    end

    def start
      @loop = Coolio::Loop.new
      refresh_watchers
      @refresh_trigger.attach(@loop)
      @thread = Thread.new(&method(:run))
    end

    def shutdown
      @refresh_trigger.detach
      stop_watch(@watchers.keys)
      @loop.stop
      @thread.join
      @pf_file.close if @pf_file
    end

    class TailExWatcher < TailWatcher
      def initialize(path, rotate_wait, pe, &receive_lines)
        @parent_receive_lines = receive_lines
        super(path, rotate_wait, pe, &method(:_receive_lines))
        @close_trigger = TimerWatcher.new(rotate_wait * 2, false, &method(:_close))
      end

      def _receive_lines(lines)
        tag = @path.tr('/', '.').gsub(/\.+/, '.').gsub(/^\./, '')
        @parent_receive_lines.call(lines, tag)
      end

      def close(loop)
        @close_trigger.attach(loop)
      end

      def _close
        @rotate_queue.reject! do |req|
          req.io.close if req.io
          true
        end
        detach

        @io_handler.on_notify
        @io_handler.close
        $log.info "stop following of #{@path}"
        @close_trigger.detach
      end
    end
  end
end
