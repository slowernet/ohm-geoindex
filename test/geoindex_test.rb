require 'test/unit'
require 'ohm'
require 'ohm/geoindex'

Ohm.redis = Redic.new(ENV["REDIS_URL"])

class Beach < Ohm::Model
  include Ohm::Geoindex

  attribute :longitude
  attribute :latitude
  geoindex [:longitude, :latitude]
end

class GeoindexTest < Test::Unit::TestCase
  def setup
    Ohm.flush
    @manly = Beach.create(latitude: -33.797948, longitude: 151.289414)
    @bondi = Beach.create(latitude: -33.891472, longitude: 151.277243)
    @coogee = Beach.create(latitude: -33.921017, longitude: 151.257566) # ~14km from manly
  end

  def test_within_by_object
    a = Beach.within(@coogee, '10 km', 'asc')
    assert_equal(a, [@coogee, @bondi])
    a = Beach.within(@coogee, '20 km', 'asc')
    assert_equal(a, [@coogee, @bondi, @manly])
  end

  def test_within_by_coords
    a = Beach.within([151.257566, -33.921017], '10 km', 'desc') # coogee
    assert_equal(a.size, 2)
    assert_equal(a.last, @coogee)
  end

  def test_index_update
    a = Ohm.redis.call('ZSCORE', @bondi.class.key[:geoindex], @bondi.id)
    @bondi.update(latitude: -33.921017, longitude: 151.257566)  # bondi moves to coogee
    b = Ohm.redis.call('ZSCORE', @bondi.class.key[:geoindex], @bondi.id)
    assert_not_equal(a, b)
    c = Ohm.redis.call('ZSCORE', @bondi.class.key[:geoindex], @coogee.id)
    assert_equal(b, c)    
  end

  def test_radius_parsing
    a = Beach.within(@coogee, '10 km', 'asc')
    assert_equal(a, [@coogee, @bondi])
    a = Beach.within(@coogee, '10000m', 'asc')
    assert_equal(a, [@coogee, @bondi])
  end

  def test_sort
    a = Beach.within(@coogee, '10 km', 'asc')
    assert_equal(a, [@coogee, @bondi])
    a = Beach.within(@coogee, '10000m', 'desc')
    assert_equal(a, [@bondi, @coogee])
  end

  def test_index_delete
    @manly.delete
    a = Ohm.redis.call('ZCARD', @bondi.class.key[:geoindex])
    assert_equal(a, 2)
  end
end
