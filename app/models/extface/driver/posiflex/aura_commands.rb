module Extface
  module Driver::Posiflex::AuraCommands

    module Info
      GET_PAPER_STATUS            = "\x1D\x72\x49".b
    end
    
    module Printer
      PAPER_CUT                   = "\x1B\x69".b
    end

  end
end

# https://sourceforge.net/p/chromispos/discussion/help/thread/c004783b/2fc4/attachment/Aura%20Printer%20Command%20Manual.pdf