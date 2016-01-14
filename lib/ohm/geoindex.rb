require 'ohm'

module Ohm
  module Geoindex
    VERSION = "0.0.3"
    
    def self.included(model)
      begin
        Ohm.redis.call!('GEOADD')
      rescue RuntimeError => e
        raise "This version of Redis (#{Ohm.redis.url}) does not support the geospatial API." if e.message =~ /unknown command/
      end

      model.extend(ClassMethods)
    end

    def save
      super
      redis.queue('MULTI')
      redis.queue('ZREM', self.class.key[:geoindex], self.id)
      coordinates = self.class.instance_variable_get('@geoindex').map { |d| attributes[d] }
      redis.queue('GEOADD', self.class.key[:geoindex], *coordinates, self.id)
      redis.queue('EXEC')
      redis.commit
      self
    end

    def delete
      redis.call('ZREM', self.class.key[:geoindex], self.id)
      super
    end

    module ClassMethods
      def geoindex(coords)
        @geoindex = coords
      end

      def within(center, radius, withdist: nil, sort: nil, count: nil)
        raise IndexNotFound unless @geoindex
        unless center.is_a?(self.ancestors.first) || (center.is_a?(Array) && center.size == 2)
          raise ArgumentError, "center must be a set of [lng, lat] coordinates or model already in the index." 
        end

        args = center.is_a?(self.ancestors.first) ? ['GEORADIUSBYMEMBER', key[:geoindex], center.id] : ['GEORADIUS', key[:geoindex], *center]
        args << parse_radius(radius)
        args << "withdist" if withdist
        args << sort if sort
        args << ["count", count] if count

        results = redis.call(*(args.flatten))

        # extract ids so we can fetch all at once
        # can be [:id, :id, ...] or [[:id, :dist], [:id, :dist], ...]
        ids = results.map { |r| [*r][0] }
        models = self.ancestors.first.fetch(ids)

        if withdist
          results.each_with_index.map { |r,i| [models[i], r[1].to_f] }
        else
          models
        end
      end

      protected
        def parse_radius(r)
          r.downcase.strip.scan(/(\d+)\s*(\S+)/).flatten
        end
    end
  end
end
