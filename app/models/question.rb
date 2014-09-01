require 'rqrcode_png'
require 'open-uri'
require 'RMagick'
class Question
  include Mongoid::Document
  include Mongoid::Timestamps
  field :type, type: String
  field :subject, type: Integer
  field :content, type: Array, default: []
  field :items, type: Array, default: []
  field :preview, type: Boolean, default: true
  field :answer, type: Integer
  field :answer_content, type: Array, default: []
  field :inline_images, type: Array, default: []
  field :q_figures, type: Array, default: []
  field :a_figures, type: Array, default: []
  belongs_to :homework
  has_many :notes

  IMAGE_TYPE = %w{jpeg png jpg bmp}
  IMAGE_DIR = Rails.application.config.image_dir
  DOWNLOAD_URL = Rails.application.config.image_download_url

  include HTTParty
  base_uri Rails.application.config.convert_image_url

  before_destroy do |doc|
    # delete all images files
    doc.inline_images.each do |e|
      File.delete("#{IMAGE_DIR}/#{e}")
    end
  end


  def self.create_choice_question(content, items, answer, answer_content, q_figures, a_figures, images_to_convert)
    # convert by windows server
    converted_images = []
    images_to_convert.map! { |e| e.gsub("equation*").gsub("figure*") }
    images_to_convert.each_slice(10).to_a.each do |sub_images_to_convert|
      sub_converted_images = Question.get("/ConvertImage.aspx?filename=#{sub_images_to_convert.join(',')}&host=#{Rails.application.config.server_host}").split(',')
      sub_converted_images.each_with_index do |filename, i|
        if filename != sub_images_to_convert[i]
          open("#{IMAGE_DIR}/#{filename}", 'wb') do |file|
            file << open("#{DOWNLOAD_URL}/#{filename}").read
          end
          File.delete("#{IMAGE_DIR}/#{sub_images_to_convert[i]}")
        end
      end
      converted_images += sub_converted_images
    end

=begin
    # convert by local rmagick
    converted_images = images_to_convert.map do |filename|
      converted_filename = filename
      name = filename.split('.')[0]
      suffix = filename.split('.')[1]
      if !%w{jpeg png jpg bmp}.include?(suffix)
        i = Magick::Image.read("#{IMAGE_DIR}/#{filename}").first
        i.trim.write("#{IMAGE_DIR}/#{name}.png") { self.quality = 1 }
        converted_filename = "#{name}.png"
        File.delete("#{IMAGE_DIR}/#{filename}")
      end
      converted_filename
    end
=end

    question = self.create(type: "choice",
      content: content.map { |e| e.gsub("equation*", "") },
      items: items.map { |e| e.gsub("equation", "") },
      answer: answer,
      answer_content: (answer_content || []).map { |e| e.gsub("equation*", "") },
      q_figures: q_figures.map { |e| e.gsub("figures*", "") },
      a_figures: a_figures.map { |e| e.gsub("figures*", "") },
      inline_images: converted_images)
  end

  def self.create_analysis_question(content, answer_content, q_figures, a_figures, images_to_convert)
    # converted by windows server
    converted_images = []
    images_to_convert.map! { |e| e.gsub("equation*").gsub("figure*") }
    images_to_convert.each_slice(10).to_a.each do |sub_images_to_convert|
      sub_converted_images = Question.get("/ConvertImage.aspx?filename=#{sub_images_to_convert.join(',')}&host=#{Rails.application.config.server_host}").split(',')
      sub_converted_images.each_with_index do |filename, i|
        if filename != sub_images_to_convert[i]
          open("#{IMAGE_DIR}/#{filename}", 'wb') do |file|
            file << open("#{DOWNLOAD_URL}/#{filename}").read
          end
          File.delete("#{IMAGE_DIR}/#{sub_images_to_convert[i]}")
        end
      end
      converted_images += sub_converted_images
    end

=begin
    # converted by local rmagick
    converted_images = images_to_convert.map do |filename|
      converted_filename = filename
      name = filename.split('.')[0]
      suffix = filename.split('.')[1]
      if !%w{jpeg png jpg bmp}.include?(suffix)
        i = Magick::Image.read("#{IMAGE_DIR}/#{filename}").first
        i.trim.write("#{IMAGE_DIR}/#{name}.png") { self.quality = 1 }
        converted_filename = "#{name}.png"
        File.delete("#{IMAGE_DIR}/#{filename}")
      end
      converted_filename
    end
=end

    question = self.create(type: "analysis",
      content: content,
      answer_content: answer_content || [],
      q_figures: q_figures,
      a_figures: a_figures,
      inline_images: converted_images)
  end

  def update_content(question_content, question_answer)
    tables = (self.content + self.answer_content ).select do |e|
      e.class == Hash && e["type"] == "table"
    end

    new_content = question_content.split(/\n|\r/).map do |line|
      if line.match(/table[0-9]+/)
        # table
        table_index = line.scan(/table([0-9]+)/)[0][0].to_i
        tables[table_index]
      else line.class == String
        # normal line
        tidyup_line = line
        line.scan(/\$([a-z 0-9]{8})\$/).each do |e|
          inline_images.each do |image|
            if image.start_with?(e[0])
              tidyup_line.gsub!(e[0], image)
              break
            end
          end
        end
        tidyup_line
      end
    end
    self.content = new_content

    new_answer_content = question_answer.split(/\n|\r/).map do |line|
      if line.match(/table[0-9]+/)
        # table
        table_index = line.scan(/table([0-9]+)/)[0][0].to_i
        tables[table_index]
      else line.class == String
        # normal line
        tidyup_line = line
        line.scan(/\$([a-z 0-9]{8})\$/).each do |e|
          inline_images.each do |image|
            if image.start_with?(e[0])
              tidyup_line.gsub!(e[0], image)
              break
            end
          end
        end
        tidyup_line
      end
    end
    self.answer_content = new_answer_content
    self.save
  end

  def update_items(items)
    self.items = []
    items.each do |item|
      tidyup_item = item
      item.scan(/\$([a-z 0-9]{8})\$/).each do |e|
        inline_images.each do |image|
          if image.start_with?(e[0])
            tidyup_item.gsub!(e[0], image)
            break
          end
        end
      end
      self.items << tidyup_item
    end
    self.save
  end

  def generate_qr_code
    if !File.exist?("public/qr_code/#{self.id.to_s}.png")
      link = MongoidShortener.generate(Rails.application.config.server_host + "/student/questions/#{self.id.to_s}")
      qr = RQRCode::QRCode.new(link, :size => 4, :level => :h )
      png = qr.to_img
      png.resize(90, 90).save("public/qr_code/#{self.id.to_s}.png")
    end
    "/qr_code/#{self.id.to_s}.png"
  end
end
