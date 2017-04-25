require 'test_helper'

module Extface
  class Driver::Datecs::Fp550Test < ActiveSupport::TestCase
    setup do
      @driver = extface_drivers(:datecs_fp550)
      @driver.flush # clear receive buffer
    end
    
    test "handle" do
      assert_equal nil, @driver.handle('bad packet')
      assert_equal 6, @driver.handle("\x01data\x03data"), "Frame not match"
      assert_equal 9, @driver.handle("pre\x01data\x03data"), "Frame with preamble not match"
      assert_equal 8, @driver.handle("\x16\x16\x01data\x03data"), "Frame with ACK preamble not match"
      assert_equal 4, @driver.handle("pre\x15"), "NAK not match"
    end
    
    test "build packet" do
      assert_equal "\x01\x24\x20\x4a\x05\x30\x30\x39\x33\x03".b, @driver.build_packet(0x4a), "packet without data"
      assert_equal "\x01\x25\x21\x4a\x58\x05\x30\x30\x3e\x3d\x03".b, @driver.build_packet(0x4a, 'X'), "packet with data"
    end
    
    test "response frame" do
      frame_class = @driver.class::Frame
      assert frame_class.new("\x15").nak?, "NAK message failed"
      assert frame_class.new("\x16\x16").ack?, "ACK message failed"
      assert_nothing_raised do
        assert_equal false, frame_class.new("bad data\x01\x25\x21\x4asome broken packet\x58\x05\x30\x30\x3e\x3d\x03".b).valid?
      end
      frame = frame_class.new("\x16\x01\x2C\x2F\x2D\x50\x04\x88\x80\xC0\x80\x80\xB0\x05\x30\x34\x35\x39\x03".b)
      assert frame.valid?, "Vailid frame not recognized"
      assert_equal "\x01\x2C\x2F\x2D\x50\x04\x88\x80\xC0\x80\x80\xB0\x05\x30\x34\x35\x39\x03".b, frame.frame
      assert_equal "\x2c".b, frame.len
      assert_equal "\x2f".b, frame.seq
      assert_equal "\x2d".b, frame.cmd
      assert_equal "\x50".b, frame.data
      assert_equal "\x88\x80\xC0\x80\x80\xB0".b, frame.status
      assert_equal "\x30\x34\x35\x39".b, frame.bcc
      #bad check sum
      frame = frame_class.new("\x01\x2C\x2F\x2D\x50\x04\x88\x80\xC0\x80\x80\xB0\x05\x30\x34\x35\x38\x03".b)
      assert_equal false, frame.valid?
      assert frame.errors.messages[:bcc]
      #bad length
      frame = frame_class.new("\x01\x2b\x2F\x2D\x50\x04\x88\x80\xC0\x80\x80\xB0\x05\x30\x34\x35\x38\x03".b)
      assert_equal false, frame.valid?
      assert frame.errors.messages[:len]
    end
    
    test "fsend" do
      job = extface_jobs(:one)
      job_thread = Thread.new do
        @driver.set_job(job)
        result = @driver.fsend(0x2C) # paper move command
      end
      simulate_device_pull(job)
      @driver.handle("\x01\x31\x20\x4A\x88\x80\xC0\x80\x80\xB8\x04\x88\x80\xC0\x80\x80\xB8\x05\x30\x37\x3A\x34\x03".b)
      simulate_device_pull(job)
      @driver.handle("\x01\x38\x21\x30\x30\x30\x30\x30\x35\x30\x2C\x30\x30\x30\x30\x34\x39\x04\x80\x80\x88\x80\x80\xB8\x05\x30\x36\x35\x30\x03".b)
      job_thread.join
      assert @driver.errors.empty?
    end
 
    test "build_sale_data encoding" do
      sale_data = @driver.build_sale_data OpenStruct.new(text1: "012345678901234567890123АБВГДЕ", price: 1)
      packet = @driver.build_packet 0x00, sale_data
      assert_equal 39, packet[1].ord - 0x20
      sale_data = @driver.build_sale_data OpenStruct.new(text1: "012345678901234567890123АБВГДЕЖЗИ", price: 1)
      packet = @driver.build_packet 0x00, sale_data
      assert_equal 39, packet[1].ord - 0x20
    end
  end
end

=begin
1432096828.834384 "del" "extface:d29183a38460cc33dfdfc2a38c20eb7d"
1432096828.835035 "del" "extface:d29183a38460cc33dfdfc2a38c20eb7d:5"
1432096828.912680 "subscribe" "extface:354"
1432096828.916584 "rpush" "extface:354" "\x01% JX\x0500><\x03"
1432096834.022511 "blpop" "extface:354" "1"
1432096834.025004 "publish" "extface:354" "OK"
1432096834.025467 "unsubscribe"
1432096834.025726 "blpop" "extface:354" "1"
1432096834.026166 "publish" "extface:354" "OK"
1432096834.026509 "blpop" "extface:354" "1"
1432096834.122677 "publish" "extface:354" "Job 354 device connected!"
1432096834.124782 "blpop" "extface:d29183a38460cc33dfdfc2a38c20eb7d:5" "3"
1432096834.155940 "append" "extface:d29183a38460cc33dfdfc2a38c20eb7d" "\x01+ J\x04\x80\x80\x92\x8f\x80\xb2\x0503?1\x03"
1432096834.255090 "get" "extface:d29183a38460cc33dfdfc2a38c20eb7d"
1432096834.259587 "rpush" "extface:d29183a38460cc33dfdfc2a38c20eb7d:5" "\x01+ J\x04\x80\x80\x92\x8f\x80\xb2\x0503?1\x03"
1432096834.261451 "set" "extface:d29183a38460cc33dfdfc2a38c20eb7d" ""
1432096834.287925 "subscribe" "extface:354"
1432096834.288641 "rpush" "extface:354" "\x01$!-\x050077\x03"
1432096834.289568 "publish" "extface:354" "OK"
1432096834.289927 "blpop" "extface:354" "1"
1432096834.290075 "unsubscribe"
1432096834.303192 "publish" "extface:354" "Job 354 completed!"
1432096834.381481 "append" "extface:d29183a38460cc33dfdfc2a38c20eb7d" "\x16"
1432096834.381674 "get" "extface:d29183a38460cc33dfdfc2a38c20eb7d"
1432096834.384880 "rpush" "extface:d29183a38460cc33dfdfc2a38c20eb7d:5" "\x16"
1432096834.385729 "set" "extface:d29183a38460cc33dfdfc2a38c20eb7d" ""
1432096834.695593 "append" "extface:d29183a38460cc33dfdfc2a38c20eb7d" "\x16"
1432096834.696066 "get" "extface:d29183a38460cc33dfdfc2a38c20eb7d"
1432096834.721265 "rpush" "extface:d29183a38460cc33dfdfc2a38c20eb7d:5" "\x16"
1432096834.722383 "set" "extface:d29183a38460cc33dfdfc2a38c20eb7d" ""
1432096835.041215 "append" "extface:d29183a38460cc33dfdfc2a38c20eb7d" "\x16\x16\x16\x16\x01,!-F\x04\x80\x80\x92\x8f\x80\xb2\x05041<\x03"
1432096835.041828 "get" "extface:d29183a38460cc33dfdfc2a38c20eb7d"
1432096835.073717 "rpush" "extface:d29183a38460cc33dfdfc2a38c20eb7d:5" "\x16"
1432096835.075013 "set" "extface:d29183a38460cc33dfdfc2a38c20eb7d" "\x16\x16\x16\x01,!-F\x04\x80\x80\x92\x8f\x80\xb2\x05041<\x03"

=end