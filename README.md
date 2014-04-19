# fluent-plugin-tail-ex, a plugin for [Fluentd](http://fluentd.org)

[![Build Status](https://secure.travis-ci.org/yosisa/fluent-plugin-tail-ex.png)](http://travis-ci.org/yosisa/fluent-plugin-tail-ex)

**Deprecated: Fluentd has the features of this plugin since 0.10.45. So, the plugin no longer maintained.**

fluent-plugin-tail-ex provides `tail_ex` input plugin.
In addition to in_tail plugin features, this plugin support more feature for comfortable.

A main feature of the plugin is support path parameter expansions.
A path parameter can be configured using glob and/or date format (strftime).
Furthermore, the plugin append file path to the configured tag.

Note: In order to pass all tests, this plugin needs fluentd 0.10.26 or above.

## Installation

Install it using gem:

    $ gem install fluent-plugin-tail-ex

## Configuration

Below parameters are extended by this plugin:

- path: can be specified using glob and strftime format.
- tag: replace '*' with file path (using dot as a path separator).

And, below parameters are added by this plugin:

- expand_date: control whether expand strftime format or not.
- read_all: when new file is found, read from beginning of a file (default), instead of end of file (in_tail).
- refresh_interval: seconds for re-expand path to find new/old files.

Moreover, all configuration parameters support some placeholders which provided by [fluent-mixin-config-placeholders](https://github.com/tagomoris/fluent-mixin-config-placeholders).

Sample configuration:

    <source>
      type tail_ex
      path /var/log/**.log,/var/log/by-date/%Y/messages.%m/%Y%m%d
      tag tail_ex.*.${hostname}
      format /^(?<message>.*)$/
      pos_file /var/tmp/fluentd.pos
      refresh_interval 1800
    </source>

## License

Apache License, Version 2.0
