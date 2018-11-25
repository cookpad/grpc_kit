# frozen_string_literal: true

module GrpcKit
  class GrpcTime
    MAX = 10**9 - 1

    # @param value [String,Integer]
    def initialize(value)
      @unit = nil
      @value = nil

      if value.is_a?(String)
        from_string(value)
      elsif value.is_a?(Integer)
        from_integer(value)
      else
        raise ArgumentError, "unsupported value: #{value}, class=#{value.class}"
      end
    end

    # @return [Float]
    def to_f
      case @unit
      when 'S'
        @value * 1.0
      when 'H'
        @value * 60 * 60.0
      when 'M'
        @value * 60.0
      when 'm'
        @value * 10**-3
      when 'u'
        @value * 10**-6
      when 'n'
        @value * 10**-9
      else
        raise 'This case would never happen'
      end
    end

    # @return [String]
    def to_s
      "#{@value}#{@unit}"
    end

    # @return [Time]
    def to_absolute_time
      case @unit
      when 'S'
        Time.now + @value
      when 'H'
        Time.now + @value * 60 * 60
      when 'M'
        Time.now + @value * 60
      when 'm'
        t = Time.now
        Time.at(t.to_i, (t.nsec * (10**-3)) + (@value * 10**3))
      when 'u'
        t = Time.now
        Time.at(t.to_i, (t.nsec * (10**-3)) + @value)
      when 'n'
        t = Time.now
        Time.at(t.to_i, (t.nsec * (10**-3)) + (@value * 10**-3))
      else
        raise 'This case would never happen'
      end
    end

    private

    def from_integer(value)
      @value = value < 0 ? MAX : value
      @unit = 'S'
    end

    def from_string(value)
      size = value.size
      if size < 2
        raise ArgumentError, "Invalid format: too short #{value}"
      end

      if size > 9
        raise ArgumentError, "Invalid format: too long #{value}"
      end

      unit = value.byteslice(-1, 1)
      value = Integer(value.byteslice(0, size - 1))
      case unit
      when 'H', 'M', 'S', 'm', 'u', 'n'
        @value = value
        @unit = unit
      else
        raise ArgumentError, "Invalid unit `#{unit}`: #{value}"
      end
    end
  end
end
