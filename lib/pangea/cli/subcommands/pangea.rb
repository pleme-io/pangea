require %(tty-option)

# shared command behavior for all commands in Pangea
class PangeaCommand
  include TTY::Option

  flag :help do
    short %(-h)
    long %(--help)
    desc %(Print usage)
  end

  flag :version do
    short %(-v)
    long %(--version)
    desc %(Print version)
  end
end
