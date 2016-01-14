require 'test/unit'
require 'ohm'
require 'ohm/geoindex'

Ohm.redis = Redic.new(ENV["REDIS_URL"])

class Beach < Ohm::Model
  include Ohm::Geoindex

  attribute :lng
  attribute :lat
  geoindex [:lng, :lat]
end

class GeoindexTest < Test::Unit::TestCase
  def setup
    Ohm.flush
    @manly = Beach.create(lng: 151.289414, lat: -33.797948)
    @bondi = Beach.create(lng: 151.277243, lat: -33.891472)
    @coogee = Beach.create(lng: 151.257566, lat: -33.921017) # ~14km from manly
  end

  def test_without_sort
    a = Beach.within(@coogee, '10 km')
    assert_equal(2, a.size)
  end

  def test_within_by_object
    a = Beach.within(@coogee, '10 km', sort: 'asc')
    assert_equal([@coogee, @bondi], a)
    a = Beach.within(@coogee, '20 km', sort: 'asc')
    assert_equal([@coogee, @bondi, @manly], a)
  end

  def test_within_by_coords
    a = Beach.within([151.257566, -33.921017], '10 km', sort: 'desc') # coogee
    assert_equal(2, a.size)
    assert_equal(@coogee, a.last)
  end

  def test_count
    a = Beach.within([151.257566, -33.921017], '10 km', sort: 'asc', count: 1) # coogee
    assert_equal(1, a.size)
    assert_equal(@coogee, a.first)
  end
   
  def test_within_with_distance
    a = Beach.within(@coogee, '10 km', sort: 'asc', withdist: true)
    assert_equal(2, a.size)
    assert_equal([@bondi, 3.7550], a.last)
    a = Beach.within(@coogee, '10 km', withdist: true)
    assert_equal(2, a.size)
  end

  def test_center_missing
    assert_raise do
      Beach.within(nil, '100 m', sort: 'asc')
    end
    assert_raise do
      Beach.within([40, 40, 40], '100 m', sort: 'asc')
    end
  end

  def test_index_update
    a = Ohm.redis.call('ZSCORE', @bondi.class.key[:geoindex], @bondi.id)
    @bondi.update(lat: -33.921017, lng: 151.257566)  # bondi moves to coogee
    b = Ohm.redis.call('ZSCORE', @bondi.class.key[:geoindex], @bondi.id)
    assert_not_equal(a, b)
    c = Ohm.redis.call('ZSCORE', @bondi.class.key[:geoindex], @coogee.id)
    assert_equal(b, c)    
  end

  def test_radius_parsing
    a = Beach.within(@coogee, '10 km', sort: 'asc')
    assert_equal([@coogee, @bondi], a)
    a = Beach.within(@coogee, '10000m', sort: 'asc')
    assert_equal([@coogee, @bondi], a)
    a = Beach.within(@coogee, '10000    m', sort: 'asc')
    assert_equal([@coogee, @bondi], a)
    a = Beach.within(@coogee, '0 km', sort: 'asc')
    assert_equal([@coogee], a)
    assert_raise do
      Beach.within(@coogee, 'one billion feet', sort: 'asc')
    end
  end

  def test_sort
    a = Beach.within(@coogee, '10 km', sort: 'asc')
    assert_equal([@coogee, @bondi], a)
    a = Beach.within(@coogee, '10000m', sort: 'desc')
    assert_equal([@bondi, @coogee], a)
  end

  def test_index_delete
    [@bondi, @coogee, @manly].each_with_index do |b, i|
      b.delete 
      assert_equal(3-(i+1), Ohm.redis.call('ZCARD', Beach.key[:geoindex]))
    end
  end
end
