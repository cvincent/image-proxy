class ImageProcessor
  require "digest/md5"
  require "pathname"
  require "anisoptera/commander"

  class << self
    def factory(type, w, h)
      case type
      when "constrain"
        Constrain.new(w, h)
      when "square"
        Square.new(w)
      end
    end
  end

  class Base
    def initialize(*args)
      @key = Digest::MD5.hexdigest(args.join("-"))
      init(*args)
    end

    attr_accessor :key

    def processed_image_data(original_path)
      raise "Called abstract method ImageProcessor::Base#processed_image_data"
    end

    private

    def init(*args)
    end

    def create_commander(path)
      pn = Pathname.new(path)
      Anisoptera::Commander.new(pn.dirname).file(pn.basename)
    end
  end

  class Constrain < Base
    def init(w, h)
      @w, @h = w, h
    end
    private :init

    def processed_image_data(original_path)
      commander = create_commander(original_path)
      commander.thumb("#{@w}x#{@h}>")
      data, status = EM::Synchrony.system(commander.command)
      data
    end
  end

  class Square < Base
    def init(size)
      @size = size
    end
    private :init

    def processed_image_data(original_path)
      commander = create_commander(original_path)
      commander.square(@size)
      data, status = EM::Synchrony.system(commander.command)
      data
    end
  end
end
