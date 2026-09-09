# Changelog

## v0.6.0 (2026-09-09)

- breaking change: Drop Ruby 2.5, 2.6, 2.7, 3.0, 3.1, and 3.2 from CI ([db918cb](https://github.com/cookpad/grpc_kit/commit/db918cbe0ceadf263ff528ace82c90983ee989f2) & [#42](https://github.com/cookpad/grpc_kit/pull/42))
- bug: Fix tests for Ruby 3+ ([#36](https://github.com/cookpad/grpc_kit/pull/36))
- bug: Fix exceptions in an auto-trimmer thread in CI build with TruffleRuby ([#38](https://github.com/cookpad/grpc_kit/pull/38))
- bug: Drain the waker pipe in Session::IO#select ([#41](https://github.com/cookpad/grpc_kit/pull/41))
- improve: Add TruffleRuby in CI ([#37](https://github.com/cookpad/grpc_kit/pull/37))
- improve: Add Ruby 3.3, 3.4, 4.0 in CI ([#42](https://github.com/cookpad/grpc_kit/pull/42))

## v0.5.1 (2021-05-19)

- improve: Set END_STREAM flag on the last DATA frame on request stream ([#34](https://github.com/cookpad/grpc_kit/pull/34))

## v0.5.0 (2021-04-22)

- improve: Configurable max_receive_message_size and max_send_message_size ([#33](https://github.com/cookpad/grpc_kit/pull/33))

## v0.4.0 (2020-10-23)

- bug: Fix Ruby 2.7 keyword argument separation warnings ([#27](https://github.com/cookpad/grpc_kit/pull/27))
- bug: HTTP/2 Trailer (grpc-status) might not be sent due to race condition ([#30](https://github.com/cookpad/grpc_kit/pull/30))
- improve: Reduce number of select(2) calls by adding pipe(2) to wake blocking threads ([#28](https://github.com/cookpad/grpc_kit/pull/28))
- improve: Improved performance when receiving streaming messages by blocking queue. ([#31](https://github.com/cookpad/grpc_kit/pull/31))

