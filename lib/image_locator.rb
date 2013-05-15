class ImageLocator
  require "digest/md5"
  require "em-synchrony/fiber_iterator"

  S3_BUCKET = "https://cantaloupe-contests.s3.amazonaws.com/"
  ORIGINALS_CACHE_DIRECTORY = File.dirname(__FILE__) + "/../image-cache/originals/"
  PROCESSED_CACHE_DIRECTORY = File.dirname(__FILE__) + "/../image-cache/processed/"
  CACHE_PREFIX = "cached-"

  def initialize(path, ext)
    @path, @ext = path, ext
  end

  attr_accessor :path, :ext

  def original_image_path
    original_cache_path.tap do
      unless File.exists?(original_cache_path)
        image_data = fetch_image_data_from_s3
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

  def fetch_image_data_from_s3
    Faraday.get(s3_url).body
  end

  def s3_url
    @s3_url ||= S3_BUCKET + path + "." + ext
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
    @cache_name ||= Digest::MD5.hexdigest(path + "." + ext)
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
