# encoding: utf-8
class TabletAnswer
  include Mongoid::Document
  include Mongoid::Timestamps

  # key is question id value, value is a hasn which has two keys:
  # => answer
  # => duration
  field :answer_content, type: Hash, default: { }
  # type can be pre_test, exercise, or post_test
  field :type, type: String, default: ""

  belongs_to :exercise, class_name: "Homework", inverse_of: :tablet_answers
  belongs_to :student, class_name: "User", inverse_of: :tablet_answers

  def self.create_new(student, exercise, data, type)
    tablet_answer = TabletAnswer.where(student_id: student.id, exercise_id: exercise.id).first ||  TabletAnswer.new(type: type)
    tablet_answer.exercise = exercise
    tablet_answer.student = student
    answer_content = { }
    exercise.q_ids.each_with_index do |qid, i|
      answer_content[qid] = { answer: data["answer"][i], duration: data["duration"][i] }
    end
    tablet_answer.answer_content = answer_content
    tablet_answer.save
  end

  def is_correct?(qid)
    q = Question.find(qid)
    return false if self.answer_content[qid].blank?
    if q.type == "blank" || q.type == "analysis"
      return self.answer_content[qid]["answer"] > 0
    else
      return self.answer_content[qid]["answer"] == q.answer
    end
  end
end
