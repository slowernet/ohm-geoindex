ohm-geoindex
=============

### In early development. Requires Redis >= 3.2.

<!-- [![Build Status](https://travis-ci.org/slowernet/ohm-geoindex.png?branch=master)](https://travis-ci.org/slowernet/ohm-geoindex) -->

A plugin for [Ohm](https://github.com/soveran/ohm) models which enables radius queries via the Redis geospatial API.

Setup
-----

1. Add the gem:

```ruby
gem 'ohm-geoindex'
````

1. Include the module in your model:

```ruby
include Ohm::Geoindex 
```

1. Add a geospatial index to your model with the following:

```ruby
geoindex [:longitude, :latitude]	# :longitude, :latitude are attributes
```

Note that `(lon,lat)` is the universal ordering convention for the Redis geospatial API.

Usage
-----

To perform a radius query, use the `within` class method.

```ruby
@manly = Beach.create(latitude: -33.797948, longitude: 151.289414)
@bondi = Beach.create(latitude: -33.891472, longitude: 151.277243)
@coogee = Beach.create(latitude: -33.921017, longitude: 151.257566) # ~14km from manly

>> Beach.within(@coogee, '10 km', 'asc')
=> [@coogee, @bondi]
>> Beach.within(@coogee, '10 mi', 'desc')
=> [@manly, @bondi, @coogee]
>> Beach.within([151.257566, -33.921017], '10 mi', 'asc')	# coords are @coogee's
=> [@coogee, @bondi, @manly]
```

See the Redis docs for [`GEORADIUS`](http://redis.io/commands/georadius) and [`GEOADD`](http://redis.io/commands/geoadd) for radius unit syntax.

Tests
--------------

`rake` will attempt to start a redis binary at ./test/redis-server at port 7771 for the duration of the test run.

Requirements
------------

This plugin works with Ohm >= 2.2.0.

