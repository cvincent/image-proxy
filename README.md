# image-proxy

An asynchronous on-demand image processing proxy with simple disk caching.

## Installation

Fork/clone.

## Why

Having to know the various geometries needed of user-uploaded images ahead of
time is a drag.  If a design changes the needed dimensions for such images, all
of the originals must be re-processed. And all of this processing takes up
space on your background worker queues. Also, using a queue to resize uploaded
images can make for awkward user experience implementation when a user might
expect to see their uploaded image right after they submit it yet the
processing job is still sitting on the queue.

Instead, why not just resize images on demand? Changes in a design's
requirements for image dimensions can be implemented instantaneously without
taking up time on your background queue. And your app need not jump through any
extra hoops to ensure the processed image is ready for viewing the moment it's
uploaded.

## Dependencies

Depends on ImageMagick's `convert` command-line tool.

## Usage

Clone the repository and run:

    bundle install --path=vendor
    bundle exec thin start -p 3001

Go to the following URL:

    http://localhost:3001/image_proxy/constrain/320/240/assets/images/my-image.jpg

This will cache, resize, cache, and serve up the image here:

    http://my-upstream-server.com/assets/images/my-image.jpg

This is really just a basic Sinatra app built on Sinatra-Synchrony, so check
the source and modify as you see fit. Of interest:

 * `ImageResizer`: This is the Sinatra app itself, with a single endpoint.
 * `ImageLocator`: Handles caching of original images from upstream and
   processed versions of original images. You'll notice that the upstream
   address is currently hardcoded here.
 * `ImageProcessor`: Various processors. These make use of a class from
   Anisoptera to construct an ImageMagick conversion command. Would be fairly
   easy to extend with custom processors as you might need them.

## Future improvements

 * Tests. This started out as a spike to check the feasibility of the idea, but
   we all know that so-called prototypes eventually make it into production. ;)
 * Configuration. Get rid of the hardcoded upstream address and cache sweep
   intervals.
 * Build in a cryptographic signature check with a shared secret to prevent
   abuse and potential DOS.
 * Smarter caching. Right now all originals from upstream and processed versions
   are swept periodically, regardless of the age of each individual file. Would
   be better to have a FIFO approach with a disk limit instead.
 * Do disk I/O in asynchronous chunks.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
