
# Design

## Introduction

rest-graph is a lightweight Facebook Graph API client.  By lightweight, it
means it's modular and compact, and only provides essential functionality.
It's designed to be transparent to Facebook Graph API, so it doesn't try to
fix Facebook's bugs nor inconsistency problems.  People should be able to
read Facebook's documentation (though sometimes it's not quite helpful) in
order to use rest-graph, instead of learning how rest-graph would work.
(of course, Ruby experience is required.)

In other words, before starts, you might need to know how Facebook's Graph
API works, for example, how to fetch data, how to do authentication, etc.
Here's the links:

* Graph API: <http://developers.facebook.com/docs/reference/api>
* Authentication: <http://developers.facebook.com/docs/authentication>

For advanced usage, you might want to read the followings, too:

* FQL: <http://developers.facebook.com/docs/reference/fql>
* Old REST API: <http://developers.facebook.com/docs/reference/rest>

Since rest-graph is trying to be transparent to Facebook Graph API, some
might find it's not so useful because of Facebook's bugs or inconsistency
problems.  This might be a disadvantage comparing to others client libraries
which mimic the issues for you, but the advantage would be for people who
have already known how Facebook Graph API works, say, people who used to
develop Facebook Apps with PHP or any other tools, could easily know how to
use rest-graph with their old knowledges.  On the other hand, if Facebook
fixed their bugs or inconsistency problems, you don't need to wait for
rest-graph fixing the problems.  You will directly depend on Facebook,
but not depend on rest-graph which depends on Facebook.  More layers,
more problems.  rest-graph is a client library, but not Facebook framework.

Still, if the inconsistency problems are very obvious and would not change
in the near future, for example, `oauth/access_token` API would not return
a JSON as typical Graph APIs do, instead, it returns a query string as in
URL.  In this case, rest-graph uses `Rack::Utils.parse_query` to parse the
query for you.  If you feel there are more cases rest-graph should handle
like this, please feel free to file a ticket on our issue tracker on Github.

* <https://github.com/cardinalblue/rest-graph/issues>

Or you could start a topic on our mailing list:

* <http://groups.google.com/group/rest-graph/topics>

Either one is welcomed.

## Name

[rest-graph][] is named after its first dependency [rest-client][].

[rest-graph]: https://github.com/cardinalblue/rest-graph
[rest-client]: https://github.com/archiloque/rest-client

## License

rest-graph is licensed under Apache License 2.0.

## Target Usage

rest-graph is split into many parts to better target different users coming
from different areas.  Essentially, the core functionality is all in one file
which is `lib/rest-graph/core.rb`.  You can copy that file and put into your
projects' load path, or use gem to install rest-graph, and then just require
the file with `require 'rest-graph/core'`.  If you don't care about memory
footprint or code bloats, want something that "Just Work&trade;" it's ok to
just `require 'rest-graph'`.  It would try to load up anything you *might*
or *might not* need.  It should Just Work&trade; out of the box, otherwise,
please file a ticket on our [issue tracker][].

[issue tracker]: https://github.com/cardinalblue/rest-graph/issues

Target usages are as following:

* No matter where rest-graph whould be used, for convenience and laziness,
  just `require 'rest-graph'`.  Then you're good to go.

* Used in backend engine or non-web application.  You might only want the
  core functionality that rest-graph provides.  In this case, simply use
  `require 'rest-graph/core'`

* Used in web applications, and then mostly you'll want more than the core.
  For example, how to get the access token, how to authenticate to Facebook,
  and how to use different settings (e.g. app_id, secret, etc) in different
  environments.  In this case, you'll want `require 'rest-graph/rails_util'`
  (if your web framework is Rails) and `require 'rest-graph/config_util'`.
  See below for usages of those two extra utilities.

## File Structure

rest-graph is modular, so utilities are all separated.  Different `require`
will get you different things.  Here we list all different requires.

* `require 'rest-graph'`

  This is for convenience and lazies which just loads everything.
  You can see below for usages.

* `require 'rest-graph/core'`

  This is for the core functionality.  Other than API calls (which is
  documented in [rdoc][]), you might want to have some default values
  for `RestGraph.new`, then you don't have to do this all the time:
  `RestGraph.new(:app_id => '1829')`.  For example, you might want:
  `RestGraph.new.app_id` to return value `'1829'` instead of `nil`,
  and still be able to overwrite it when passing `:app_id` like this:
  `RestGraph.new(:app_id => 'abcd')`. If so, you'll do:

      require 'rest-graph/core'

      module MyRestGraphSettings
        def default_app_id
          '1829'
        end
      end

      RestGraph.send(:extend, MyRestGraphSettings)

      RestGraph.new.app_id # => '1829'

  Or you can simply define it in `RestGraph`.

      class RestGraph
        def self.default_app_id
          '1829'
        end
      end

      RestGraph.new.app_id # => '1829'

  If you want to set those defaults in a config file with different
  environments, then `require 'rest-graph/config_util'` is for you.
  See below.

[rdoc]: http://rdoc.info/projects/cardinalblue/rest-graph

* `require 'rest-graph/config_util`

  This is for automatically reading setting from a certain config file.
  To use it, use: `RestGraph.load_config(path_to_yaml_file, environment)`
  A config file would look like this: [rest-graph.yaml][]  You can embed
  ERB template in it.  After the config has been loaded, every call to
  `RestGraph.new` would respect those settings.  e.g. `RestGraph.new.app_id`
  would return the app_id you set in the config file, instead of `nil`.

[rest-graph.yaml]: ../test/config/rest-graph.yaml

* `require 'rest-graph/rails_util'`

  This is for people using Rails. (compatible and tested with both Rails 2
  and Rails 3)  `include RestGraph::RailsUtil` in your controller would
  give you `rest_graph_setup` and `rest_graph` methods in both controller
  and helper.  The former is used to configure the behaviour for each action,
  the latter is used to access the instance of `RestGraph` which is setup in
  `rest_graph_setup`.

* `require 'rest-graph/test_util'`
* `require 'rest-graph/facebook_util'`
