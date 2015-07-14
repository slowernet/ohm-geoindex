module Ohm
  module Geoindex
    VERSION = "0.0.1"
    
    def self.included(model)
      begin
        Ohm.redis.call! 'GEOADD'
      rescue RuntimeError => e
        raise "This version of Redis (#{Ohm.redis.url}) does not support the geospatial API." if e.message =~ /unknown command/
      end

      model.extend(ClassMethods)
    end

    def save
      super
      redis.queue "MULTI"
      redis.queue 'ZREM', self.class.key[:geoindex], self.id
      redis.queue 'GEOADD', self.class.key[:geoindex], self.longitude, self.latitude, self.id
      redis.queue "EXEC"
      redis.commit
      self
    end

    def delete
      redis.call 'ZREM', self.class.key[:geoindex], self.id
      super
    end

    module ClassMethods
      def geoindex(coords)
        @geoindex = coords
      end

      def within(center, radius, sort = nil)
        raise IndexNotFound unless @geoindex
        if center.is_a?(self.ancestors.first)
          ids = redis.call 'GEORADIUSBYMEMBER', key[:geoindex], center.id, *self.parse_radius(radius), sort
        else
          ids = redis.call 'GEORADIUS', key[:geoindex], *center, *self.parse_radius(radius), sort
        end
        self.ancestors.first.fetch(ids)
      end

      protected
        def parse_radius(r)
          r.downcase.strip.scan(/(\d+)\s*(\S+)/).flatten
        end
    end
  end
end
