# encoding: utf-8
class WeixinBind
  include Mongoid::Document
  include Mongoid::Timestamps

  field :weixin_open_id, type: String
  # can be "client", "coach" or "student"
  field :type, type: String
  field :nickname, type: String
  belongs_to :student, class_name: "User", inverse_of: :student_weixin_binds
  belongs_to :coach, class_name: "User", inverse_of: :coach_weixin_bind
  belongs_to :client, class_name: "User", inverse_of: :client_weixin_bind

  def self.find_student_by_open_id(open_id)
  	weixin_bind = WeixinBind.where(type: "student", weixin_open_id: open_id).first
  end

  def self.find_coach_by_open_id(open_id)
    weixin_bind = WeixinBind.where(type: "coach", weixin_open_id: open_id).first
  end

  def self.find_client_by_open_id(open_id)
    weixin_bind = WeixinBind.where(type: "client", weixin_open_id: open_id).first
  end

  def self.create_student_bind(student, info)
    wb = WeixinBind.create(weixin_open_id: info[:open_id], type: "student", nickname: info[:nickname])
    wb.student = student
    wb.save
  end

  def self.create_coach_bind(coach, info)
    wb = WeixinBind.create(weixin_open_id: info[:open_id], type: "coach", nickname: info[:nickname])
    wb.coach = coach
    wb.save
  end

  def self.create_client_bind(client, info)
    wb = WeixinBind.create(weixin_open_id: info[:open_id], type: "client", nickname: info[:nickname])
    wb.client = client
    wb.save
  end
end
