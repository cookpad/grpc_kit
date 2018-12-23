# frozen_string_literal: true

require 'grpc_kit/rpc_desc'
require 'grpc_kit/grpc/stream'

RSpec.describe GrpcKit::RpcDesc do
  let(:rpc_desc) do
    described_class.new(
      name: name,
      marshal: marshal,
      unmarshal: unmarshal,
      marshal_method: 'marshal_method',
      unmarshal_method: 'unmarshal_method',
      service_name: service_name,
    )
  end

  let(:marshal) { double(:marshal) }
  let(:unmarshal) { double(:unmarshal) }
  let(:name) { 'GetFeature' }
  let(:service_name) { 'routeguide.RouteGuide' }
  let(:handler) { double(:handler) }
  let(:interceptor) { Class.new(GrpcKit::Grpc::Interceptor).new }

  describe '#build_server' do
    let(:server) { rpc_desc.build_server(handler) }

    context 'when request_response' do
      context 'without interceptor' do
        before do
          expect(GrpcKit::MethodConfig).to receive(:build_for_server).with(hash_including(interceptor: nil))
        end

        it { expect(server).to be_a(GrpcKit::Rpcs::Server::RequestResponse) }
      end

      context 'with interceptor' do
        let(:server) { rpc_desc.build_server(handler, interceptors: [interceptor]) }

        before do
          expect(GrpcKit::MethodConfig).to receive(:build_for_server) do |hash|
            expect(hash[:interceptor]).to be_a(GrpcKit::Interceptors::Server::RequestResponse)
          end
        end

        it { expect(server).to be_a(GrpcKit::Rpcs::Server::RequestResponse) }
      end
    end

    context 'when client_streamer' do
      let(:marshal) { GrpcKit::Grpc::Stream.new(super()) }

      context 'without interceptor' do
        before do
          expect(GrpcKit::MethodConfig).to receive(:build_for_server).with(hash_including(interceptor: nil))
        end

        it { expect(server).to be_a(GrpcKit::Rpcs::Server::ClientStreamer) }
      end

      context 'with interceptor' do
        let(:server) { rpc_desc.build_server(handler, interceptors: [interceptor]) }

        before do
          expect(GrpcKit::MethodConfig).to receive(:build_for_server) do |hash|
            expect(hash[:interceptor]).to be_a(GrpcKit::Interceptors::Server::ClientStreamer)
          end
        end

        it { expect(server).to be_a(GrpcKit::Rpcs::Server::ClientStreamer) }
      end
    end

    context 'when server_streamer' do
      let(:unmarshal) { GrpcKit::Grpc::Stream.new(super()) }

      context 'without interceptor' do
        before do
          expect(GrpcKit::MethodConfig).to receive(:build_for_server).with(hash_including(interceptor: nil))
        end

        it { expect(server).to be_a(GrpcKit::Rpcs::Server::ServerStreamer) }
      end

      context 'with interceptor' do
        let(:server) { rpc_desc.build_server(handler, interceptors: [interceptor]) }

        before do
          expect(GrpcKit::MethodConfig).to receive(:build_for_server) do |hash|
            expect(hash[:interceptor]).to be_a(GrpcKit::Interceptors::Server::ServerStreamer)
          end
        end

        it { expect(server).to be_a(GrpcKit::Rpcs::Server::ServerStreamer) }
      end
    end

    xcontext 'bidi_streamer' do
    end
  end

  describe '#build_client' do
    let(:client) { rpc_desc.build_client(interceptors: [interceptor]) }

    context 'when request_response' do
      before do
        expect(GrpcKit::MethodConfig).to receive(:build_for_client) do |hash|
          expect(hash[:interceptor]).to be_a(GrpcKit::Interceptors::Client::RequestResponse)
        end
      end

      it { expect(client).to be_a(GrpcKit::Rpcs::Client::RequestResponse) }
    end

    context 'when client_streamer' do
      let(:marshal) { GrpcKit::Grpc::Stream.new(super()) }

      before do
        expect(GrpcKit::MethodConfig).to receive(:build_for_client) do |hash|
          expect(hash[:interceptor]).to be_a(GrpcKit::Interceptors::Client::ClientStreamer)
        end
      end

      it { expect(client).to be_a(GrpcKit::Rpcs::Client::ClientStreamer) }
    end

    context 'when server_streamer' do
      let(:unmarshal) { GrpcKit::Grpc::Stream.new(super()) }

      before do
        expect(GrpcKit::MethodConfig).to receive(:build_for_client) do |hash|
          expect(hash[:interceptor]).to be_a(GrpcKit::Interceptors::Client::ServerStreamer)
        end
      end

      it { expect(client).to be_a(GrpcKit::Rpcs::Client::ServerStreamer) }
    end

    xcontext 'bidi_streamer' do
    end
  end

  describe '#ruby_style_name' do
    it { expect(rpc_desc.ruby_style_name).to eq(:get_feature) }

    context 'when interceptors is not empty' do
    end
  end

  describe '#build_client' do
    context 'when interceptors is not empty' do
    end
  end

  describe '#ruby_style_name' do
    it { expect(rpc_desc.ruby_style_name).to eq(:get_feature) }
  end

  describe '#path' do
    it { expect(rpc_desc.path).to eq('/routeguide.RouteGuide/GetFeature') }
  end

  describe '#request_response?' do
    it { expect(rpc_desc.request_response?).to eq(true) }

    context 'marshal is stream' do
      let(:marshal) { GrpcKit::Grpc::Stream.new(super()) }
      it { expect(rpc_desc.request_response?).to eq(false) }
    end

    context 'unmarshal is stream' do
      let(:unmarshal) { GrpcKit::Grpc::Stream.new(super()) }
      it { expect(rpc_desc.request_response?).to eq(false) }
    end

    context 'both marshal and unmarshal are stream' do
      let(:marshal) { GrpcKit::Grpc::Stream.new(super()) }
      let(:unmarshal) { GrpcKit::Grpc::Stream.new(super()) }

      it { expect(rpc_desc.request_response?).to eq(false) }
    end
  end

  describe '#client_streamer?' do
    it { expect(rpc_desc.client_streamer?).to eq(false) }

    context 'marshal is stream' do
      let(:marshal) { GrpcKit::Grpc::Stream.new(super()) }
      it { expect(rpc_desc.client_streamer?).to eq(true) }
    end

    context 'unmarshal is stream' do
      let(:unmarshal) { GrpcKit::Grpc::Stream.new(super()) }
      it { expect(rpc_desc.client_streamer?).to eq(false) }
    end

    context 'both marshal and unmarshal are stream' do
      let(:marshal) { GrpcKit::Grpc::Stream.new(super()) }
      let(:unmarshal) { GrpcKit::Grpc::Stream.new(super()) }

      it { expect(rpc_desc.client_streamer?).to eq(false) }
    end
  end

  describe '#server_streamer?' do
    it { expect(rpc_desc.server_streamer?).to eq(false) }

    context 'marshal is stream' do
      let(:marshal) { GrpcKit::Grpc::Stream.new(super()) }
      it { expect(rpc_desc.server_streamer?).to eq(false) }
    end

    context 'unmarshal is stream' do
      let(:unmarshal) { GrpcKit::Grpc::Stream.new(super()) }
      it { expect(rpc_desc.server_streamer?).to eq(true) }
    end

    context 'both marshal and unmarshal are stream' do
      let(:marshal) { GrpcKit::Grpc::Stream.new(super()) }
      let(:unmarshal) { GrpcKit::Grpc::Stream.new(super()) }

      it { expect(rpc_desc.server_streamer?).to eq(false) }
    end
  end

  describe '#bidi_streamer?' do
    it { expect(rpc_desc.bidi_streamer?).to eq(false) }

    context 'marshal is stream' do
      let(:marshal) { GrpcKit::Grpc::Stream.new(super()) }
      it { expect(rpc_desc.bidi_streamer?).to eq(false) }
    end

    context 'unmarshal is stream' do
      let(:unmarshal) { GrpcKit::Grpc::Stream.new(super()) }
      it { expect(rpc_desc.bidi_streamer?).to eq(false) }
    end

    context 'both marshal and unmarshal are stream' do
      let(:marshal) { GrpcKit::Grpc::Stream.new(super()) }
      let(:unmarshal) { GrpcKit::Grpc::Stream.new(super()) }

      it { expect(rpc_desc.bidi_streamer?).to eq(true) }
    end
  end
end
