# encoding: utf-8
class Lesson
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :video_id_ary, type: Array, default: []
  field :exercise_page, type: Integer, default: -1
  belongs_to :course, class_name: "Course", inverse_of: :lessons
  has_many :videos, class_name: "Video", inverse_of: :lesson
  has_one :homework, class_name: "Homework", inverse_of: :lesson

  has_many :learn_logs
  has_many :action_logs

  def name_with_course_and_teacher
    course_name = self.course.present? ? self.course.name_with_teacher : "（未绑定课程）"

    course_name + " " + self.name
  end

  def has_video?
    return true if self.videos.present?
    self.video_id_ary.each do |e|
      if e.present?
        return true
      end
    end
    return false
  end

  def touch_parents
    self.course.try(:touch)
  end

  def order
    if self.course.blank?
      return "未绑定"
    else
      index = self.course.lesson_id_ary.index(self.id.to_s)
      if index == -1
        return "未指定序号"
      else
        return "第#{index+1}讲"
      end
    end
  end

  def info_for_tablet(course, order)
    {
      server_id: self.id.to_s,
      course_id: course.id.to_s,
      name: self.name,
      lesson_order: order,
      exercise_page: self.exercise_page,
      update_at: self.updated_at.to_s
    }
  end


  def self.lesson_helper(i)
    ary = %w{一 二 三 四 五 六 七 八 九 十 十一 十二 十三 十四 十五 十六 十七 十八 十九 二十 二十一 二十二 二十三 二十四 二十五 二十六 二 十七 二十八 二十九 三十 三十一 三十二 三十三 三十四 三十五 三十六 三十七 三十八 三十九 四十}
    "第" + ary[i] + "讲："
  end
end
