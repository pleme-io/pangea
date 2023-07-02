require %(tty-color)
require %(tty-box)

module Say
  class << self
    def terminal(msg)
      spec = {
        width: 80,
        style: {
          fg: :yellow,
          bg: :blue,
          border: { fg: :green, bg: :black }
        },
        align: :right,
        border: :thick
        # padding: 0,
        # height: 1
      }

      box = TTY::Box.frame(**spec)

      puts box + "\n"
      puts msg.strip
      puts "\n" + box
    end
  end
end
