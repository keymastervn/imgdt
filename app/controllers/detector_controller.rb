require 'mini_magick'
require 'open-uri'

class DetectorController < ApplicationController
  def index
  end

  def detect
    brightness_threshold_white = 250
    brightness_threshold_black = 5
    alpha_threshold = 0.9

    image_url = params[:url]

    file_name = File.basename(URI.parse(image_url).path)

    stats = {}

    begin
      image = URI.open(image_url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE) do |file|
        MiniMagick::Image.read(file)
      end

      # Get pixel data (RGBA)
      pixels = image.get_pixels(_map = 'RGBA')

      total_pixels = 0
      visible_pixels = 0
      transparent_pixels = 0
      white_pixels = 0
      black_pixels = 0

      pixels.each do |row|
        row.each do |pixel|
          r, g, b, a = pixel
          alpha = a.to_f / 255.0
          total_pixels += 1

          unless alpha < alpha_threshold # Keep only opaque pixels

            visible_pixels += 1

            # Count white pixels (all channels above brightness threshold)
            if r > brightness_threshold_white && g > brightness_threshold_white && b > brightness_threshold_white
              white_pixels += 1
            end

            # Count black pixels (all channels below brightness threshold)
            if r < brightness_threshold_black && g < brightness_threshold_black && b < brightness_threshold_black
              black_pixels += 1
            end
          else
            transparent_pixels += 1
          end
        end
      end

      stats = {
        total_pixels:,
        visible_pixels:,
        transparent_pixels:,
        white_pixels:,
        black_pixels:,
        white_over_total_ratio: white_pixels.to_f / total_pixels,
        white_over_transparent_ratio: white_pixels.to_f / transparent_pixels,
        white_over_black_ratio: white_pixels.to_f / black_pixels,
        black_over_white_ratio: black_pixels.to_f / white_pixels
      }
    ensure
      image.destroy!
    end

    render json: stats
  end
end
