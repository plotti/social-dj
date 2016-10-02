# encoding: utf-8

class PostUploader < CarrierWave::Uploader::Base
  #include CarrierWave::MimetypeFu
  include CarrierWave::MimeTypes

  # Choose what kind of storage to use for this uploader:
  storage :file
    process :format => 'jpg'

  # storage :fog
  # process :set_content_type
  # def filename 
  #   "original_#{file.extension}" if original_filename 
  # end 
    def filename
       "#{model.id}.jpg"
    end
  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  # def store_dir
  #   "uploads/#{model.class.to_s.underscore}/#{model.id}.#{file.content_type}"
  # end

end
