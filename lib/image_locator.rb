class ImageLocator
  require "digest/md5"
  require "em-synchrony/fiber_iterator"

  ORIGINALS_CACHE_DIRECTORY = File.dirname(__FILE__) + "/../image-cache/originals/"
  PROCESSED_CACHE_DIRECTORY = File.dirname(__FILE__) + "/../image-cache/processed/"
  CACHE_PREFIX = "cached-"

  def initialize(host, path, ext)
    @host, @path, @ext = host, path, ext
  end

  attr_accessor :host, :path, :ext

  def original_image_path
    original_cache_path.tap do
      unless File.exists?(original_cache_path)
        image_data = fetch_image_data_from_remote
        File.open(original_cache_path, "wb+") { |f| f.write(image_data) }
      end
    end
  end

  def processed_image_path(processor)
    processed_cache_path(processor).tap do |path|
      unless File.exists?(path)
        image_data = processor.processed_image_data(original_image_path)
        File.open(path, "wb+") { |f| f.write(image_data) }
      end
    end
  end

  def content_type
    case ext.downcase
    when "png"
      "image/png"
    when "jpg", "jpeg"
      "image/jpeg"
    when "gif"
      "image/gif"
    end
  end

  private

  def fetch_image_data_from_remote
    Faraday.get(remote_url.gsub(" ", "%20")).body
  end

  def remote_url
    @remote_url ||= "http://" + remote_domain_and_path
  end

  def remote_domain_and_path
    @remote_domain_and_path ||= "#{host}/#{path}.#{ext}"
  end

  def original_cache_path
    @original_cache_path ||= ORIGINALS_CACHE_DIRECTORY + cache_file_name
  end

  def processed_cache_path(processor)
    @processed_cache_paths ||= {}
    @processed_cache_paths[processor.key] ||= PROCESSED_CACHE_DIRECTORY + cache_file_name(processor.key)
  end

  def cache_file_name(extra = "")
    @cache_file_names ||= {}
    @cache_file_names[extra] ||= CACHE_PREFIX + cache_name + "-" + extra + "." + ext
  end

  def cache_name
    @cache_name ||= Digest::MD5.hexdigest(remote_domain_and_path)
  end

  class << self
    def sweep_originals!
      remove_files(cached_originals)
    end

    def sweep_processed!
      remove_files(cached_processed)
    end

    private

    def cached_originals
      Dir.glob(ORIGINALS_CACHE_DIRECTORY + CACHE_PREFIX + "*").to_a
    end

    def cached_processed
      Dir.glob(PROCESSED_CACHE_DIRECTORY + CACHE_PREFIX + "*").to_a
    end

    def remove_files(files)
      EM::Synchrony::FiberIterator.new(files).each do |file|
        EM::Synchrony.system("rm #{file}")
      end
    end
  end
end
