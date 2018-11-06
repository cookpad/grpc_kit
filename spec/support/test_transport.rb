class TestTransport
  def write_data(d, last: false)
    @write_data ||= ''
    @write_data << d
  end

  def get_write_data
    @write_data
  end

  def write_trailers(d)
    @write_trailers ||= {}
    @write_trailers.merge!(d)
  end

  def get_write_trailers
    @write_trailers
  end

  def start_response(d)
    @start_response ||= {}
    @start_response.merge!(d)
  end

  def get_start_response
    @start_response
  end
end
