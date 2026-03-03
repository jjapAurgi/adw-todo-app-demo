# frozen_string_literal: true

require "aws-sdk-s3"
require "uri"

module Adw
  module R2
    class << self
      def enabled?
        %w[CLOUDFLARE_R2_BUCKET_URL CLOUDFLARE_R2_ACCESS_KEY_ID
           CLOUDFLARE_R2_SECRET_ACCESS_KEY].all? { |v| ENV[v] }
      end

      def bucket_url
        @bucket_url ||= URI.parse(ENV.fetch("CLOUDFLARE_R2_BUCKET_URL"))
      end

      def endpoint
        "#{bucket_url.scheme}://#{bucket_url.host}"
      end

      def bucket_name
        bucket_url.path.delete_prefix("/")
      end

      def client
        @client ||= Aws::S3::Client.new(
          access_key_id: ENV.fetch("CLOUDFLARE_R2_ACCESS_KEY_ID"),
          secret_access_key: ENV.fetch("CLOUDFLARE_R2_SECRET_ACCESS_KEY"),
          endpoint: endpoint,
          region: "us-east-1",
          force_path_style: true,
          ssl_ca_bundle: OpenSSL::X509::DEFAULT_CERT_FILE
        )
      end

      def upload(local_path, object_key)
        File.open(local_path, "rb") do |file|
          client.put_object(
            bucket: bucket_name,
            key: object_key,
            body: file,
            content_type: content_type_for(local_path)
          )
        end
        public_url(object_key)
      end

      def public_url(key)
        base = ENV.fetch("CLOUDFLARE_R2_PUBLIC_DOMAIN", "")
        "#{base}/#{key}"
      end

      def upload_evidence(adw_id, screenshots, logger)
        return screenshots unless enabled?

        screenshots.map do |screenshot|
          local_path = screenshot["path"]
          object_key = "adw/#{adw_id}/review/#{screenshot['filename']}"
          begin
            url = upload(local_path, object_key)
            logger.info("Uploaded #{screenshot['filename']} to R2: #{url}")
            screenshot.merge("url" => url)
          rescue Aws::S3::Errors::ServiceError => e
            logger.warn("R2 upload failed for #{screenshot['filename']}: #{e.message}")
            screenshot
          end
        end
      end

      private

      CONTENT_TYPES = {
        ".png" => "image/png",
        ".jpg" => "image/jpeg",
        ".jpeg" => "image/jpeg",
        ".webp" => "image/webp",
        ".gif" => "image/gif"
      }.freeze

      def content_type_for(path)
        ext = File.extname(path).downcase
        CONTENT_TYPES.fetch(ext, "application/octet-stream")
      end
    end
  end
end
