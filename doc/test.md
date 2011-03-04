
# Test

## Introduction

A collection of tools integrated with [RR][] to ease the pain of
testing. There are 3 levels of tools to stub the result of
calling APIs. The highest level is `TestUtil.login(1234)` which
would stub a number of results to pretend the user 1234 is
logged-in.

The second level are the get/post/put/delete methods for
TestUtil. For example, to make rg.get('1234') return a
particular value (such as a hash {'a' => 1}), use
TestUtil.get('1234'){ {'a' => 1} } to set it up to return
the specified value (typically a hash).

The third level is for setting default_data and default_response
for TestUtil. The default_data is the default value for rg.data,
which includes the access_token and the user_id (uid). The
default_response is the response given by any RestGraph API call
(e.g. get, post) when no explicit response has been defined in
the second level.

To use TestUtil, remember to install RR (gem install rr) and
require 'rest-graph/test_util'. Then put
RestGraph::TestUtil.setup before any test case starts, and put
RestGraph::TestUtil.teardown after any test case ends. Setup
would stub default_data and default_response for you, and
teardown would remove any stubs on RestGraph. For Rails, you
might want to put these in test_helper.rb under "setup" and
"teardown" block, just as the name suggested. For bacon or
rspec style testing, these can be placed in the "before" and
"after" blocks.

In addition, you can get the API calls history via
RestGraph::TestUtil.history. This would get cleaned up in
RestGraph::TestUtil.teardown as well.

[RR]: https://github.com/btakita/rr

## Login emulation

## default_response

##
