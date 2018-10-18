# frozen_string_literal: true

module GrpcKit
  module Session
    class Duration < Struct.new(:sec, :msec, :usec, :nsec)
      MAX_TIMEOUT = 10**9 - 1
      HOUR = 60 * 60
      MIN = 60
      MILL_SEC = 10**-3
      MICRO_SEC = 10**-6
      NANO_SEC = 10**-9

      # @params val [String]
      def self.decode(value)
        size = value.size
        if size < 2
          raise "Invalid format: too short #{value}"
        end

        unit = value.slice!(-1, 1)
        d = Duration.new(0, 0, 0, 0)
        n = Integer(value)

        case unit
        when 'H'
          d.sec = n * HOUR
        when 'M'
          d.sec = n * MIN
        when 'S'
          d.sec = n
        when 'm'
          d.msec = n
        when 'u'
          d.usec = n
        when 'n'
          d.nsec = n
        else
          raise "Invalid unit `#{unit}`: #{value + unit} "
        end
        d
      end

      def to_timeout
        v = 0

        if nsec && (nsec != 0)
          v += (NANO_SEC * nsec)
        end

        if usec && (usec != 0)
          v += (MICRO_SEC * usec)
        end

        if msec && (msec != 0)
          v += (MILL_SEC * msec)
        end

        if sec
          v += sec
        end

        v
      end

      # @params val [Numeric]
      def self.from_numeric(val)
        case val
        when nil
        when Numeric
          if val < 0
            Duration.new(MAX_TIMEOUT, 0, 0, 0)
          elsif val == 0
            Duration.new(0, 0, 0, 0)
          else
            Duration.new(val, 0, 0, 0)
          end
        else
          raise "Cannot make timeout from #{val}"
        end
      end

      # TODO
      def to_s
        if nsec && (nsec != 0)
          "#{nsec}n"
        elsif usec && (usec != 0)
          "#{usec}u"
        elsif msec && (msec != 0)
          "#{msec}m"
        elsif sec
          "#{sec}S"
        end
      end
    end
  end
end
