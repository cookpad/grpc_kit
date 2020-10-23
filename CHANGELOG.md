# Changelog

## v0.4.0 (2020-10-23)

- bug: Fix Ruby 2.7 keyword argument separation warnings ([#27](https://github.com/cookpad/grpc_kit/pull/27))
- bug: HTTP/2 Trailer (grpc-status) might not be sent due to race condition ([#30](https://github.com/cookpad/grpc_kit/pull/30))
- improve: Reduce number of select(2) calls by adding pipe(2) to wake blocking threads ([#28](https://github.com/cookpad/grpc_kit/pull/28))
- improve: Improved performance when receiving streaming messages by blocking queue. ([#31](https://github.com/cookpad/grpc_kit/pull/31))

