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
  end
end
