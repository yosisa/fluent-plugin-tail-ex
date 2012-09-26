require 'helper'

class TailExInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
tag tail_ex
path test/plugin/*/%Y/%m/%Y%m%d-%H%M%S.log,test/plugin/data/log/**/*.log
format /^(?<message>.*)$/
pos_file /var/tmp/fluentd.pos
refresh_interval 30
  ]
  PATHS = [
    'test/plugin/data/2010/01/20100102-030405.log',
    'test/plugin/data/log/foo/bar.log',
    'test/plugin/data/log/test.log'
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::TailExInput).configure(conf)
  end

  def test_configure
    assert_nothing_raised { create_driver }
  end

  def test_expand_paths
    plugin = create_driver.instance
    flexstub(Time) do |timeclass|
      timeclass.should_receive(:now).with_no_args.and_return(
        Time.new(2010, 1, 2, 3, 4, 5))
      assert_equal PATHS, plugin.expand_paths
    end
  end

  def test_refresh_watchers
    plugin = create_driver.instance
    sio = StringIO.new
    plugin.instance_eval do
      @pf = Fluent::TailInput::PositionFile.parse(sio)
    end

    flexstub(Time) do |timeclass|
      timeclass.should_receive(:now).with_no_args.and_return(
        Time.new(2010, 1, 2, 3, 4, 5), Time.new(2010, 1, 2, 3, 4, 6),
        Time.new(2010, 1, 2, 3, 4, 7))

      flexstub(Fluent::TailExInput::TailExWatcher) do |watcherclass|
        PATHS.each do |path|
          watcherclass.should_receive(:new).with(path, 5, Fluent::TailInput::PositionEntry, any).once.and_return do
            flexmock('TailExWatcher') {|watcher| watcher.should_receive(:attach).once}
          end
        end
        plugin.refresh_watchers
      end

      plugin.instance_eval do
        @watchers['test/plugin/data/2010/01/20100102-030405.log'].should_receive(:close).once
      end

      flexstub(Fluent::TailExInput::TailExWatcher) do |watcherclass|
        watcherclass.should_receive(:new).with('test/plugin/data/2010/01/20100102-030406.log', 5, Fluent::TailInput::PositionEntry, any).once.and_return do
          flexmock('TailExWatcher') do |watcher|
            watcher.should_receive(:attach).once
            watcher.should_receive(:close).once
          end
        end
        plugin.refresh_watchers
      end

      flexstub(Fluent::TailExInput::TailExWatcher) do |watcherclass|
        watcherclass.should_receive(:new).never
        plugin.refresh_watchers
      end
    end
  end
end


class TailExWatcherTest < Test::Unit::TestCase
  def setup
    @tag = nil
    @lines = nil
    @watcher = Fluent::TailExInput::TailExWatcher.new('/var/tmp//foo.log', 5, nil, &method(:callback))
  end

  def callback(lines, tag)
    @tag = tag
    @lines = lines
  end

  def test_receive_lines
    @watcher.instance_eval { @receive_lines.call(['l1', 'l2']) }
    assert_equal 'var.tmp.foo.log', @tag
    assert_equal ['l1', 'l2'], @lines
  end
end
