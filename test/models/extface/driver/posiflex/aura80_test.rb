require 'test_helper'

module Extface
  class Driver::Posiflex::Aura80Test < ActiveSupport::TestCase
    setup do
      @driver = extface_drivers(:posiflex_aura80)
      @driver.flush # clear receive buffer
    end
    
    test "handle" do
      assert_equal 1, @driver.handle("\x0C")
    end
    
    test "status" do
      job = extface_jobs(:one)
      job_thread = Thread.new do
        @driver.set_job(job)
      end
      data = simulate_device_pull(job)
      assert_equal data.b, @driver.class::Info::GET_PAPER_STATUS
      @driver.handle("\x00")
      job_thread.join
      assert @driver.errors.empty?, @driver.errors.full_messages
    end
    
    test "paper out" do
      job = extface_jobs(:one)
      job_thread = Thread.new do
        @driver.set_job(job)
      end
      data = simulate_device_pull(job)
      assert_equal data.b, @driver.class::Info::GET_PAPER_STATUS
      @driver.handle("\x0C")
      job_thread.join
      assert_equal @driver.errors.messages[:base], ["Paper out"]
    end
    
    test "autocut" do
      job = extface_jobs(:one)
      job_thread = Thread.new do
        @driver.set_job(job)
        @driver.autocut
      end
      simulate_device_pull(job) #status command
      @driver.handle("\x00")
      data = simulate_device_pull(job)
      assert_equal data.b, @driver.class::Printer::PAPER_CUT
      job_thread.join
    end
  end
end

# https://sourceforge.net/p/chromispos/discussion/help/thread/c004783b/2fc4/attachment/Aura%20Printer%20Command%20Manual.pdf
# Paper sensor status [n =1, 49]
# Bit Off/On Hex Decimal Status for ASB
# 0, Off 00 0 Paper roll near-end sensor: paper adequate.
# 1 On 03 3 Paper roll near-end sensor: paper near end.
# 2, Off 00 0 Paper out sensor: paper adequate.
# 3 On 0C 12 Paper out sensor: paper out.
# 4 Off 00 0 Not used Fixed to Off.
# 5,
# 6
# - - - Undefined.
# 7 Off 00 0 Not used Fixed to Off. 
