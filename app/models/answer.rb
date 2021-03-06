# encoding: utf-8
class Answer
  include Mongoid::Document
  include Mongoid::Timestamps

  field :finish, type: Boolean, default: false
  field :finished_at, type: Integer
  # each value in the answer_content has the following keys:
  # => item_index: only for choice answer
  # => content: array, element of which is hash, can be text or images
  # => comment: array, element of which is hash, can be text of images
  field :answer_content, type: Hash, default: { }

  belongs_to :homework, class_name: "Homework", inverse_of: :answers
  belongs_to :student, class_name: "User", inverse_of: :student_answers

  def self.ensure_answer(student, homework, coach)
    return nil if homework.nil?
    a = student.student_answers.where(homework_id: homework.id).first
    if a.present?
      a
    else
      a = Answer.create(student_id: student.id, homework_id: homework.id, coach_id: coach.id)
      homework.q_ids.each { |e| a.answer_content[e] = { } }
      a
    end
  end

  def submit
    return false if self.answer_content.blank?
    self.homework.q_ids.each do |e|
      if self.answer_content[e].blank?
        return false
      end
    end
    self.update_attribute(:finish, true)
    if self.finished_at.blank?
      self.finished_at = Time.now.to_i
      self.save
    end
    true
  end

  def update_answer_content(q_id, new_answer)
    q_answer = self.answer_content[q_id] || { }
    q_answer["answer_index"] = new_answer["answer_index"]
    q_answer["comment"] = new_answer["comment"]
    if new_answer["answer_content_img_serverId"].to_s != q_answer["answer_content_img_serverId"].to_s
      if new_answer["answer_content_img_serverId"].blank?
        # delete the image
        q_answer["answer_content_img_serverId"] = ""
        q_answer["answer_content_img_id"] = ""
      else
        # download the image from weixin server and save
        q_answer["answer_content_img_serverId"] = new_answer["answer_content_img_serverId"]
        media = WeixinMedia.download_media(q_answer["answer_content_img_serverId"], new_answer["answer_content_img_rotate"])
        q_answer["answer_content_img_id"] = media.id.to_s
        q_answer["answer_content_img_file_type"] = media.file_type
      end
    end
    if new_answer["answer_content_img_serverId"].present? && new_answer["answer_content_img_rotate"].present?
      # only change the rotate
      WeixinMedia.update_rotate(q_answer["answer_content_img_id"], new_answer["answer_content_img_rotate"])
    end
    if new_answer["coach_comment_img_serverId"].to_s != q_answer["coach_comment_img_serverId"].to_s
      if new_answer["coach_comment_img_serverId"].blank?
        # delete the image
        q_answer["answer_content_img_serverId"] = ""
        q_answer["answer_content_img_id"] = ""
      else
        # download the image from weixin server and save
        q_answer["coach_comment_img_serverId"] = new_answer["coach_comment_img_serverId"]
        media = WeixinMedia.download_media(q_answer["coach_comment_img_serverId"], new_answer["coach_comment_img_rotate"])
        q_answer["coach_comment_img_id"] = media.id.to_s
        q_answer["coach_comment_img_file_type"] = media.file_type.to_s
      end
    end
    if new_answer["coach_comment_img_serverId"].present? && new_answer["coach_comment_img_rotate"].present?
      # only change the rotate
      WeixinMedia.update_rotate(q_answer["coach_comment_img_id"], new_answer["coach_comment_img_rotate"])
    end
    self.answer_content[q_id] = q_answer
    self.save
  end
end
