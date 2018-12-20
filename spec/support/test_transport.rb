# frozen_string_literal: true

class TestTransport
  def write_data(d, last: false)
    @write_data ||= +''
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

  def end_write
    @end_wirte ||= true
  end

  def get_end_write
    @end_wirte
  end

  def submit_headers(d)
    @submit_headers ||= {}
    @submit_headers.merge!(d)
  end

  def get_submit_headers
    @submit_headers
  end
end
