# Perb

Perb instruments your methods such that they show up when a ruby executable gets profiled with perf. it works by
wrapping all methods with:

```ruby
Perb::wrapper(<some_id>) do
    ... (your method code here)
end
```

For each method it JITs a small assembly function which just yields back to your ruby method. The assembly looks like
this:

```assembly
push rbp
mov rbp, rsp
xor rdi, rdi
call rb_sys::rb_yield
leave
ret
```

Then, we produce a perf map file (as described [here](https://github.com/torvalds/linux/blob/0513e464f9007b70b96740271a948ca5ab6e7dd7/tools/perf/Documentation/jit-interface.txt)) which maps the address of the JITed assembly to the ruby function we are wrapping. This way perf
can show ruby function names (and their location in the file system) in its output.

Inspired by the work done to do something similar for Python, which is explained [here](https://docs.python.org/zh-cn/dev/howto/perf_profiling.html)

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add perb

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install perb

## Usage

In order for this to work, you need ruby to be compiled with `CFLAGS="-fno-omit-frame-pointer -mno-omit-leaf-frame-pointer"`
and also all your native extensions to do so as well. For rust you want: `RUSTFLAGS="-C force-frame-pointers=yes"`

Without this you will see incorrect perf results, as perf won't be able to profile correctly your program.

Having done this, you can setup `perb` with `require "perb/setup"` which should be required before all the code that you
want to be able to profile. See `bin/perf_test` as an example. Then you can just:

```shell
perf record -g <your-ruby-executable>
```

and you should be able to profile native and ruby code with one profile.

## Caveats

I've noticed that perf drops stack frames when the stack gets really deep, which results in weird results. Given that
the call graphs that we are recording are fairly convoluted (they also include all the internals of the Ruby VM) this
can happen quite quickly. You should be able to increase such limit with:

```
sudo sysctl kernel.perf_event_max_stack=<stack-size>
```

This currently will break anything that patches `load_iseq` like `bootsnap`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/perb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/Maaarcocr/perb/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Perb project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/perb/blob/master/CODE_OF_CONDUCT.md).
