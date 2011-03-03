
# Dependency

## Introduction

Because rest-graph is designed to be lightweight and modular, it should
depend on as little things as possible, and give people the power to choose
their preference. rest-graph is depending on at least a HTTP client, and
optionally depending on a JSON parser if you want to auto-decode the JSON
from servers. (and `auto_decode` is actually the default.) It might also be
depending on [Rack][] for some operation, for example,
`RestGraph#parse_rack_env!` and `RestGraph#parse_cookies!` is using
`Rack::Utils.parse_query`. For those operations, Rack is needed.

[Rack]: https://github.com/rack/rack

## HTTP client (must pick one)

At the beginning, rest-graph uses [rest-client][], and is a must install
runtime dependency. Later, the support of [em-http-request][] is added,
so now you can pick either of them or both of them.

Usually, rest-client is used for synchronized (blocking) operations;
Contrarily, em-http-request is used for asynchronized (evented) operations.

If you don't know what's the difference between them, just use rest-client.
It's a lot easier to use, and have been tested more. If you don't know how
to pick, then you might be already using rest-client.

This is an example of using rest-client:

    data = RestGraph.new.get('me')

This is an example of using em-http-request:

    RestGraph.new.aget('me'){ |data| }

This is using em-http-request, too:

    RestGraph.new.get('me', {}, {:async => true}){ |data| }

[rest-client]: https://github.com/archiloque/rest-client
[em-http-request]: https://github.com/igrigorik/em-http-request

## JSON parser (optional, but needed by default)

When `auto_decode` is set to true, rest-graph would use a JSON parser to
parse the JSON and return a Ruby object corresponding to that JSON. The most
widely used JSON parser is [json][], it has two distributions, one is `json`,
another one is `json_pure`. The former is written in Ruby and C, the latter
is purely written in Ruby. They are too widely used so you might want to
use it on your application, too. But [yajl-ruby][] is a lot more recommended,
it's... generally better, you can take a look on [yajl-ruby's README][]

rest-graph would first try to use Yajl, if it's not defined, then try JSON.
If it's not defined either, then it would try to `require 'yajl'`, rescue
`LoadError`, and `request 'json'`. The latter would either load json or
json_pure depending on the system.

So to force using yajl-ruby, you could require 'yajl-ruby' before rest-graph.
There's no way to force using json when yajl-ruby is already used though.
Anyone needs this? File a ticket on our [issue tracker][]

[json]: https://github.com/flori/json
[yajl-ruby]: https://github.com/brianmario/yajl-ruby
[yajl-ruby's README]: https://github.com/brianmario/yajl-ruby/blob/master/README.rdoc
[issue tracker]: https://github.com/cardinalblue/rest-graph/issues

## Rack (optional, needed when parsing cookie)

Actually I wonder if anyone would not use [Rack][]. But since it's really an
optional, so I'll just leave it as optional.
