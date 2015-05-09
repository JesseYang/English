# encoding: utf-8
class Video
  include Mongoid::Document
  include Mongoid::Timestamps

  # 1 for knowledge, 2 for example, 3 for episode
  field :video_type, type: Integer
  field :name, type: String
  field :video_url, type: String

  # structure of one element in tags:
  # => tag_type: Integer, 1 for index, 2 for episode
  # => time: Integer
  # => name: String, only for index tags
  # => episode_id: String, only for episode tags
  field :tags, type: Array, default: []

  # for example videos, the question content
  field :content, type: Array, default: []
  # for example videos, recommended finish time
  field :time, type: Integer

  belongs_to :lesson, class_name: "Lesson", inverse_of: :videos

  def touch_parents
    self.lesson.try(:touch)
    self.lesson.try(:touch_parents)
  end

  def order
    index = self.lesson.video_id_ary.index(self.id.to_s)
    if index == -1
      return "未指定序号"
    else
      return "第#{index+1}段"
    end
  end

  def episodes_for_select
    hash = { "请选择" => -1 }
    self.lesson.videos.where(video_type: 3).each do |v|
      hash[v.name] = v.id.to_s
    end
    hash
  end

  def self.existing_video_content_for_select
    hash = { "请选择" => -1 }
    Video.all.each do |v|
      hash[v.course_name + ", " + v.lesson_name + ", " + v.name] = v.id.to_s
    end
    hash
  end

  def self.video_type_for_select
    {
      "请选择" => -1,
      "知识点" => 1,
      "例题" => 2,
      "片段" => 3
    }
  end

  def self.tag_type_for_select
    {
      "请选择" => -1,
      "索引" => 1,
      "知识片段" => 2
    }
  end

  def self.show_type(type_code)
    case type_code
    when 1
      "知识点"
    when 2
      "例题"
    when 3
      "片段"
    else
      "未知"
    end
  end

  def self.show_tag_type(tag_type_code)
    case tag_type_code
    when 1
      "索引"
    when 2
      "知识片段"
    else
      "未知"
    end
  end

  def course_name
    course = self.lesson.course
    course.nil? ? "未绑定" : course.name
  end

  def lesson_name
    self.lesson.name
  end

  def video_order
    video_id_ary = self.lesson.video_id_ary
    index = video_id_ary.index(self.id.to_s)
    index == -1 ? "未指定序号" : index + 1
  end

  def info_for_tablet(lesson, order)
    {
      server_id: self.id.to_s,
      type: self.video_type,
      name: self.name,
      video_order: order,
      time: self.time,
      content: self.content.join("^^^"),
      video_url: self.video_url,
      update_at: self.updated_at.to_s,
      lesson_id: lesson.id.to_s
    }
  end

  def tag_info_for_tablet
    self.tags.map do |t|
      {
        type: t["tag_type"],
        time: t["time"],
        name: t["name"],
        episode_id: t["episode_id"]
      }
    end
  end
end
