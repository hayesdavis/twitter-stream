$:.unshift "."
require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'twitter/json_stream'
require 'stringio'

include Twitter

Host = "127.0.0.1"
Port = 9550

class JSONServer < EM::Connection
  attr_accessor :data
  def receive_data data
    $recieved_data = data
    send_data $data_to_send
    EventMachine.next_tick {
      close_connection if $close_connection
    }
  end
end

describe JSONStream do
  
  context "on create" do
    
    it "should return stream" do
      EM.should_receive(:connect).and_return('TEST INSTANCE')
      stream = JSONStream.connect {}
      stream.should == 'TEST INSTANCE'
    end
    
    it "should define default properties" do
      EM.should_receive(:connect).with do |host, port, handler, opts|
        host.should == 'stream.twitter.com'
        port.should == 80
        opts[:path].should == '/1/statuses/filter.json'
        opts[:method].should == 'GET'
      end
      stream = JSONStream.connect {}
    end
    
    it "should connect to the proxy if provided" do
      EM.should_receive(:connect).with do |host, port, handler, opts|
        host.should == 'my-proxy'
        port.should == 8080
        opts[:host].should == 'stream.twitter.com'
        opts[:port].should == 80
        opts[:proxy].should == 'http://my-proxy:8080'
      end
      stream = JSONStream.connect(:proxy => "http://my-proxy:8080") {}
    end
  end
  
  context "on valid stream" do
    attr_reader :stream
    before :each do
      $body = File.readlines(fixture_path("twitter/tweets.txt"))
      $body.each {|tweet| tweet.strip!; tweet << "\r" }
      $data_to_send = http_response(200,"OK",{},$body)
      $recieved_data = ''
      $close_connection = false
    end
    
    it "should add no params" do
      connect_stream
      $recieved_data.should include('/1/statuses/filter.json HTTP')
    end
    
    it "should add custom params" do
      connect_stream :params => {:name => 'test'}
      $recieved_data.should include('?name=test')
    end
    
    it "should parse headers" do
      connect_stream
      stream.code.should == 200
      stream.headers.keys.map{|k| k.downcase}.should include('content-type')
    end
    
    it "should parse headers even after connection close" do
      connect_stream
      stream.code.should == 200
      stream.headers.keys.map{|k| k.downcase}.should include('content-type')
    end
    
    it "should extract records" do
      connect_stream :user_agent => 'TEST_USER_AGENT'
      $recieved_data.upcase.should include('USER-AGENT: TEST_USER_AGENT')
    end
    
    it "should permit custom headers" do
      connect_stream :headers=>{"X-Custom-Header"=>"Custom"}
      $recieved_data.upcase.should include('X-CUSTOM-HEADER: CUSTOM')
    end
    
    it "should deliver each item" do
      items = []
      connect_stream do
        stream.each_item do |item|
          items << item
        end
      end
      # Extract only the tweets from the fixture
      tweets = $body.map{|l| l.strip }.select{|l| l =~ /^\{/ }
      items.size.should == tweets.size
      tweets.each_with_index do |tweet,i|
        items[i].should == tweet
      end
    end
    
    it "should send correct user agent" do
      connect_stream
    end
  end

  shared_examples_for "network failure" do
    it "should reconnect on network failure" do
      connect_stream do
        stream.should_receive(:reconnect)
      end
    end
    
    it "should reconnect with 0.25 at base" do
      connect_stream do
        stream.should_receive(:reconnect_after).with(0.25)
      end
    end
    
    it "should reconnect with linear timeout" do
      connect_stream do
        stream.nf_last_reconnect = 1
        stream.should_receive(:reconnect_after).with(1.25)
      end
    end
    
    it "should stop reconnecting after 100 times" do
      connect_stream do
        stream.reconnect_retries = 100
        stream.should_not_receive(:reconnect_after)
      end
    end
    
    it "should notify after reconnect limit is reached" do
      timeout, retries = nil, nil
      connect_stream do
        stream.on_max_reconnects do |t, r|
          timeout, retries = t, r
        end
        stream.reconnect_retries = 100
      end
      timeout.should == 0.25
      retries.should == 101
    end    
  end
  
  context "on network failure" do
    attr_reader :stream
    before :each do
      $data_to_send = ''
      $close_connection = true
    end
    
    it "should timeout on inactivity" do
      connect_stream :stop_in => 1.5 do
        stream.should_receive(:reconnect)        
      end
    end    
    
    it_should_behave_like "network failure"
  end
  
  context "on server unavailable" do
    
    attr_reader :stream
    
    # This is to make it so the network failure specs which call connect_stream  
    # can be reused. This way calls to connect_stream won't actually create a 
    # server to listen in.
    def connect_stream_without_server(opts={},&block)
      connect_stream_default(opts.merge(:start_server=>false),&block)
    end
    alias_method :connect_stream_default, :connect_stream
    alias_method :connect_stream, :connect_stream_without_server
    
    it_should_behave_like "network failure"
  end  
  
  context "on application failure" do
    attr_reader :stream
    before :each do
      $data_to_send = "HTTP/1.1 401 Unauthorized\r\nWWW-Authenticate: Basic realm=\"Firehose\"\r\n\r\n"
      $close_connection = true
    end
    
    it "should reconnect on application failure 10 at base" do
      connect_stream do
        stream.should_receive(:reconnect_after).with(10)
      end
    end
    
    it "should reconnect with exponential timeout" do
      connect_stream do
        stream.af_last_reconnect = 160
        stream.should_receive(:reconnect_after).with(320)
      end
    end
    
    it "should not try to reconnect after limit is reached" do
      connect_stream do
        stream.af_last_reconnect = 320
        stream.should_not_receive(:reconnect_after)
      end
    end
  end  

  context "on stream with chunked transfer encoding" do
    attr_reader :stream
    before :each do
      $recieved_data = ''
      $close_connection = false
    end

    it "should ignore empty lines" do
      body_chunks = ["{\"screen"+"_name\"",":\"user1\"}\r\r\r{","\"id\":9876}\r\r"]
      $data_to_send = http_response(200,"OK",{},body_chunks)
      items = []
      connect_stream do
        stream.each_item do |item|
          items << item
        end
      end
      items.size.should == 2
      items[0].should == '{"screen_name":"user1"}'
      items[1].should == '{"id":9876}'
    end

    it "should parse full entities even if split" do
      body_chunks = ["{\"id\"",":1234}\r{","\"id\":9876}"]
      $data_to_send = http_response(200,"OK",{},body_chunks)
      items = []
      connect_stream do
        stream.each_item do |item|
          items << item
        end
      end
      items.size.should == 2
      items[0].should == '{"id":1234}'
      items[1].should == '{"id":9876}'
    end
  end

  context "on compressed stream with chunked transfer encoding" do
    attr_reader :stream

    before :each do
      $recieved_data = ''
      $close_connection = false
    end

    it "should decompress gzipped entities correctly" do
      raw_body = %Q({"screen_name":"user1"}\r{"id":9876})

      body = ""
      gzw = Zlib::GzipWriter.new(StringIO.new(body))
      gzw.write(raw_body)
      gzw.flush

      # Don't close the gzip writer before chunking because we don't want the 
      # content to sent to the connection to have a gzip footer because a real 
      # stream would not
      body = chunk_content(body)
      gzw.close

      $data_to_send = http_response(200,"OK",{"Content-Encoding"=>"gzip"},body)
      items = []
      connect_stream do
        stream.each_item do |item|
          items << item
        end
      end
      items.size.should == 2
      items[0].should == '{"screen_name":"user1"}'
      items[1].should == '{"id":9876}'
    end

    it "should decompress deflated entities correctly" do
      raw_body = %Q({"screen_name":"user1"}\r{"id":9876})

      body = Zlib::Deflate.deflate(raw_body)
      body = chunk_content(body)

      $data_to_send = http_response(200,"OK",{"Content-Encoding"=>"deflate"},body)
      items = []
      connect_stream do
        stream.each_item do |item|
          items << item
        end
      end
      items.size.should == 2
      items[0].should == '{"screen_name":"user1"}'
      items[1].should == '{"id":9876}'
    end

  end

end