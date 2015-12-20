require 'test_helper'

module Extface
  class Driver::DaisyFx1200Test < ActiveSupport::TestCase
    setup do
      @driver = extface_drivers(:daisy_fx1200)
      @driver.flush # clear receive buffer
    end
    
    test "handle" do
      assert_equal nil, @driver.handle('bad packet')
      assert_equal 6, @driver.handle("\x01data\x03data"), "Frame not match"
      assert_equal 9, @driver.handle("pre\x01data\x03data"), "Frame with preamble not match"
      assert_equal 8, @driver.handle("\x16\x16\x01data\x03data"), "Frame with ACK preamble not match"
      assert_equal 4, @driver.handle("pre\x15"), "NAK not match"
      assert_equal 6, @driver.handle("\x01data\x03\x01data\x03"), "Two packets not match only the first"
    end
    
    test "response frame" do
      frame_class = @driver.class::RespFrame
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
        @driver.autofix_unclosed_doc #should not affect test
        @driver.fsend(0x2C) # paper move command
      end
      simulate_device_pull(job)
      @driver.handle("\x01\x31\x20\x4A\x88\x80\xC0\x80\x80\xB8\x04\x88\x80\xC0\x80\x80\xB8\x05\x30\x37\x3A\x34\x03\x01\x31\x20\x4A\x88\x80\xC0\x80\x80\xB8\x04\x88\x80\xC0\x80\x80\xB8\x05\x30\x37\x3A\x34\x03".b)
      simulate_device_pull(job)
      @driver.handle("\x01\x38\x21\x30\x30\x30\x30\x30\x35\x30\x2C\x30\x30\x30\x30\x34\x39\x04\x80\x80\x88\x80\x80\xB8\x05\x30\x36\x35\x30\x03".b)
      job_thread.join
      assert @driver.errors.empty?
    end
    
    test "sequence mismatch" do
      job = extface_jobs(:one)
      job_thread = Thread.new do
        @driver.set_job(job)
        @driver.autofix_unclosed_doc #should not affect test
        result = @driver.fsend(0x2C) # paper move command
      end
      simulate_device_pull(job)
      @driver.handle("\x01\x31\x20\x4A\x88\x80\xC0\x80\x80\xB8\x04\x88\x80\xC0\x80\x80\xB8\x05\x30\x37\x3A\x34\x03")
      simulate_device_pull(job)
      @driver.handle("\x01\x31\x20\x4A\x88\x80\xC0\x80\x80\xB8\x04\x88\x80\xC0\x80\x80\xB8\x05\x30\x37\x3A\x34\x03")
      simulate_device_pull(job)
      @driver.handle("\x01\x38\x21\x30\x30\x30\x30\x30\x33\x37\x2C\x30\x30\x30\x30\x33\x36\x04\x80\x80\x88\x80\x80\xB8\x05\x30\x36\x35\x31\x03")
      job_thread.join
      assert @driver.errors.empty?
    end
    
    test "autofix unclosed doc" do
      job = extface_jobs(:one)
      job_thread = Thread.new do
        @driver.set_job(job)
        @driver.autofix_unclosed_doc
      end
      # status byte 2 bit 3 (fiscal doc open) 80 80 88 80 80 B8
      assert_equal simulate_device_pull(job).b[3].ord, @driver.class::Info::STATUS
      @driver.handle("\x01\x31\x20\x4A\x80\x80\x88\x80\x80\xB8\x04\x80\x80\x88\x80\x80\xB8\x05\x30\x37\x32\x34\x03")
      assert_equal simulate_device_pull(job).b[3].ord, @driver.class::Sales::CANCEL_DOC
      @driver.handle("\x01\x38\x21\x30\x30\x30\x30\x30\x31\x36\x2C\x30\x30\x30\x30\x31\x35\x04\x80\x80\x88\x80\x80\xB8\x05\x30\x36\x34\x3B\x03")
      assert_equal simulate_device_pull(job).b[3].ord, @driver.class::Printer::CUT
      @driver.handle("\x01\x2B\x22\x34\x04\x80\x80\x88\x80\x80\xB8\x05\x30\x33\x3C\x3A\x03")
      job_thread.join
      assert @driver.errors.empty?
    end
  end
end

=begin production bug
D, [2015-12-19T03:17:06.320883 #7496] DEBUG -- : --> 01 24 20 4A 05 30 30 39 33 03
D, [2015-12-19T03:17:08.687275 #9818] DEBUG -- : <-- 01 31 20 4A 88 80 C0 80 80 B8 04 88 80 C0 80 80 B8 05 30 37 3A 34 03 01 31 20 4A 88 80 C0 80 80 B8 04 88 80 C0 80 80 B8 05 30 37 3A 34 03
D, [2015-12-19T03:17:08.730121 #7496] DEBUG -- : --> 01 2D 21 30 31 2C 31 2C 30 30 30 30 31 05 30 32 32 3E 03
D, [2015-12-19T03:17:08.868456 #9818] DEBUG -- : <-- 01 31 20 4A 88 80 C0 80 80 B8 04 88 80 C0 80 80 B8 05 30 37 3A 34 03 01 38 21 30 30 30 30 30 35 30 2C 30 30 30 30 34 39 04 80 80 88 80 80 B8 05 30 36 35 30 03
D, [2015-12-19T03:17:10.452179 #7662] DEBUG -- : --> 01 24 20 4A 05 30 30 39 33 03
D, [2015-12-19T03:17:14.058523 #7864] DEBUG -- : --> 01 24 20 4A 05 30 30 39 33 03
D, [2015-12-19T03:17:20.461714 #7662] DEBUG -- : --> 01 24 20 4A 05 30 30 39 33 03
D, [2015-12-19T03:17:24.051068 #7864] DEBUG -- : --> 01 24 20 4A 05 30 30 39 33 03
D, [2015-12-19T03:17:30.463707 #7662] DEBUG -- : --> 01 24 20 4A 05 30 30 39 33 03
D, [2015-12-19T03:17:34.054570 #7864] DEBUG -- : --> 01 24 20 4A 05 30 30 39 33 03 
=end