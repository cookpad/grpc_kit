## Features

### request response

- [x] recv/send msg
- [x] metadata (client)
- [x] metadata (server)
- [x] interceptor (client)
- [x] interceptor (server)
- [x] deadline (client)
- [x] deadline (server)

### server streamer

- [x] recv/send msg
- [ ] metadata (client)
- [ ] metadata (server)
- [x] interceptor (client)
- [x] interceptor (server)
- [ ] deadline (client)
- [ ] deadline (server)

### client streamer

- [x] recv/send msg
- [ ] metadata (client)
- [ ] metadata (server)
- [x] interceptor (client)
- [x] interceptor (server)
- [ ] deadline (client)
- [ ] deadline (server)

### bidi_streamer

- [ ] recv/send msg
- [ ] metadata (client)
- [ ] metadata (server)
- [ ] interceptor (client)
- [ ] interceptor (server)
- [ ] deadline (client)
- [ ] deadline (server)

## Error handling

- [ ] resouce exhausted (body size is to large)
- [ ] resouce exhausted (worker is exhausted)
- [ ] duration parse in header
- [ ] send `grpc-status` along with header frame if possible
   - need to support  https://nghttp2.org/documentation/nghttp2_submit_response.html, data_prd is not NULL
- [ ] unimplemented error
- [ ] goaway
- [ ] cancel
- [ ] support h2's header continuation

## Others

- [x] multi thread (griffin)
- [x] mutli process (griffin)
- [ ] connection persistent (client, griffin)
- [ ] send metadata in trailrs frame
- [ ] tcp connection の keep alive
- [ ] add server request spec
- [ ] add client request spec
