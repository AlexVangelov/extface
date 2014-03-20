require 'active_support/concern'
module Extface
  module Driver::Epson::EscPos
    
    def autocut(partial = true) # (Function B)
      # <GS> 'V' 0x65 x - Full-cut command
      # <GS> 'V' 0x66 x - Partial-cut command
      push partial ? "\x1D\x56\x65\x03" : "\x1D\x56\x66\x03"
    end

  end
end