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
- [x] metadata (client)
- [x] metadata (server)
- [x] interceptor (client)
- [x] interceptor (server)
- [ ] deadline (client)
- [x] deadline (server)

### client streamer

- [x] recv/send msg
- [x] metadata (client)
- [x] metadata (server)
- [x] interceptor (client)
- [x] interceptor (server)
- [ ] deadline (client)
- [x] deadline (server)

### bidi_streamer

- [x] recv/send msg
- [x] metadata (client)
- [x] metadata (server)
- [x] interceptor (client)
- [x] interceptor (server)
- [ ] deadline (client)
- [ ] deadline (server)

## Error handling

- [x] resouce exhausted (body size is to large)
- [x] internal
- [ ] resouce exhausted (worker is exhausted)
- [x] duration parse in header
- [x] send `grpc-status` along with header frame if possible
   - need to support  https://nghttp2.org/documentation/nghttp2_submit_response.html, data_prd is not NULL
- [x] unimplemented error
- [ ] goaway
- [ ] cancel
- [ ] support h2's header continuation

## Others

- [x] multi thread (griffin)
- [x] mutli process (griffin)
- [ ] connection persistent (client, griffin)
- [ ] send metadata in trailrs frame
- [ ] add server request spec
- [ ] add client request spec
- [ ] handle RST FRAME

## bugs

- [x] status_check is invoked twice
- [x] undefined local variable or method `finish' for #<GrpcKit::Sessions::ClientSession:0x00007f9ae3abf970> (NameError)
- [x] clients don't use same object even if thier connections alive

