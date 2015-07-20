ohm-geoindex
=============

### In early development. Requires Redis >= 3.2.

<!-- [![Build Status](https://travis-ci.org/slowernet/ohm-geoindex.png?branch=master)](https://travis-ci.org/slowernet/ohm-geoindex) -->

A plugin for [Ohm](https://github.com/soveran/ohm) models which enables basic geospatial queries via the Redis [geohashing](http://redis.io/commands#geo) [API](http://cristian.regolo.cc/2015/07/07/introducing-the-geo-api-in-redis.html).

Setup
-----

1. Add the gem:

```ruby
gem 'ohm-geoindex', require: 'ohm/geoindex'
````

2. Include the module in your model and specify the attributes to be indexed. (Note that `(longitude, latitude)` is the ordering convention used throughout the geo API.)

```ruby
class Beach < Ohm::Model
  include Ohm::Geoindex 

  attribute :latitude
  attribute :longitude
  geoindex [:longitude, :latitude]
end
```

Usage
-----

To perform a radius query, use the `within` class method.

```ruby
>> @manly = Beach.create(latitude: -33.797948, longitude: 151.289414)
>> @bondi = Beach.create(latitude: -33.891472, longitude: 151.277243)
>> @coogee = Beach.create(latitude: -33.921017, longitude: 151.257566) # ~14km from manly

>> Beach.within(@coogee, '10 mi', sort: 'desc')
=> [@manly, @bondi, @coogee]
>> Beach.within(@coogee, '10 km', sort: 'asc', withdist: true)
=> [@coogee, @bondi]
>> Beach.within([151.257566, -33.921017], '10 mi', sort: 'asc')	# coords are @coogee's
=> [@coogee, @bondi, @manly]
```

See the Redis docs for [`GEORADIUS`](http://redis.io/commands/georadius) and [`GEOADD`](http://redis.io/commands/geoadd) for allowed unit syntax.

Tests
-----

Because the geo API is only currently available in Redis' unstable branch, `rake test` attempts to start a local redis binary at ./test/redis-server port 7771 for the test run.

Requirements
------------

This plugin works with Ohm >= 2.2.0.

Changelog
---------

0.0.2

* Correct implicit expectation of indexed attribute names.

0.0.1

* Initial release

