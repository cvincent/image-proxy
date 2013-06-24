module Anisoptera
  class Commander
    def command(file_path = nil)
      raise ArgumentError, "no original file provided. Do commander.file('some_file.jpg')" unless @original
      file_path ||= full_file_path
      cmd = []
      cmd << @geometry if @geometry
      cmd << @greyscale if @greyscale
      cmd << @square if @square # should clear command
      if @encode
        cmd << "#{@encode}:-" # to stdout
      else
        cmd << '-'
      end

      "#{@convert_command} #{file_path.gsub(" ", "\ ")} " + cmd.join(' ')
    end
  end
end
