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
      assert_equal 1, @driver.handle("\x16\x16\x01data\x03data"), "Frame with ACK preamble not match"
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
  end
end
