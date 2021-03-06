# encoding: utf-8
require 'rmagick'
require 'httparty'
class WeixinMedia
  include HTTParty
  base_uri "https://file.api.weixin.qq.com"
  format  :json

  include Mongoid::Document
  include Mongoid::Timestamps

  @@save_folder = "public/weixin_media/"

  field :server_id, type: String, default: ""
  field :file_type, type: String, default: ""
  field :error_code, type: String, default: ""
  field :downloaded, type: Boolean, default: false


  def self.save_folder
    @@save_folder
  end

  def self.image_folder
    @@save_folder[6..-1]
  end

  def self.download_media(media_id, rotate=0)
    m = WeixinMedia.create(server_id: media_id)
    url = "/cgi-bin/media/get?access_token=#{Weixin.get_access_token}&media_id=#{media_id}"
    response = Weixin.get(url)
    if response.response.code != "200"
      m.error_code = "http_#{response.response.code}"
      m.save
      return m.id.to_s
    end
    case response.headers["content-type"]
    when "text/plain"
      # an error message
      m.error_code = JSON.parse(response.body)["errcode"]
      m.save
      return m.id.to_s
    when "image/jpeg"
      m.file_type = "jpg"
      file = File.open(@@save_folder + m.id.to_s + "." + m.file_type, 'wb')
      file.write(response.body)
      m.downloaded = true
      m.save
      return m
    end
  end

  def self.update_rotate(media_id, rotate)
    media = WeixinMedia.where(id: media_id).first
    img = Magick::ImageList.new(@@save_folder + media.id.to_s + "." + media.file_type)
    img.rotate!(rotate.to_f)
    img.write(@@save_folder + media.id.to_s + "." + media.file_type)
    return media
  end
end
