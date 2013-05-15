require "sinatra/base"
require "sinatra/synchrony"
require "faraday"

Faraday.default_adapter = :em_synchrony

require_relative "image_locator"
require_relative "image_processor"

class ImageProxy < Sinatra::Base
  register Sinatra::Synchrony

  ORIGINALS_CACHE_SWEEP_INTERVAL = (60 * 60) * 12 # Every 12 hours
  PROCESSED_CACHE_SWEEP_INTERVAL = (60 * 60) * 2  # Every  2 hours

  @@cache_sweep_initialization = EM::Synchrony::Thread::Mutex.new

  def initialize
    super

    if @@cache_sweep_initialization.try_lock
      EM::Synchrony.add_periodic_timer(ORIGINALS_CACHE_SWEEP_INTERVAL) do
        ImageLocator.sweep_originals!
      end

      EM::Synchrony.add_periodic_timer(PROCESSED_CACHE_SWEEP_INTERVAL) do
        ImageLocator.sweep_processed!
      end
    end
  end

  get "/image_proxy/:type/:w/:h/*.*" do
    type = params[:type]
    width = Integer(params[:w])
    height = Integer(params[:h])

    image_locator = ImageLocator.new(*params[:splat])
    image_processor = ImageProcessor.factory(type, width, height)

    processed_image_path = image_locator.processed_image_path(image_processor)
    content_type(image_locator.content_type)

    f = File.open(processed_image_path, "rb")
    f.read.tap { f.close }
  end
end
