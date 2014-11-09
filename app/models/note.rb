# encoding: utf-8
class Note
  include Mongoid::Document
  include Mongoid::Timestamps

  # note should be a snapshoot of the original question
  field :subject, type: Integer
  field :type, type: String
  field :content, type: Array, default: []
  field :items, type: Array, default: []
  field :preview, type: Boolean, default: true
  field :answer, type: Integer, default: -1
  field :answer_content, type: Array, default: []
  field :inline_images, type: Array, default: []
  field :q_figures, type: Array, default: []
  field :a_figures, type: Array, default: []

  field :question_str, type: String, default: ""

  # tag set is copied from homework when note is created
  field :tag_ary, type: Array, default: []

  # note part
  field :topic_str, type: String, default: ""
  field :summary, type: String
  field :tag, type: String
  belongs_to :user
  belongs_to :question
  has_and_belongs_to_many :topics

  def update_note(summary, note_type, topics)
    q = Question.find(self.question_id)
    self.update_attributes(subject: q.subject,
      question_type: q.type,
      type: q.type,
      content: q.content,
      items: q.items,
      preview: q.preview,
      answer: q.answer,
      answer_content: q.answer_content,
      inline_images: q.inline_images,
      q_figures: q.q_figures,
      a_figures: q.a_figures,
      summary: summary,
      note_type: note_type)
    self.topics.clear
    topics.split(',').each do |e|
      next if e.blank?
      t = Topic.find_or_create(e, q.homework.subject)
      t.notes << self if t.present?
    end
    self.update_attributes({question_str: self.content.join + items.join,
      topic_str: self.topics.map { |e| e.name } .join(',') })
  end

  def self.create_new(qid, summary, note_type, topics)
    q = Question.find(qid)
    n = Note.create(subject: q.subject,
      question_type: q.type,
      type: q.type,
      content: q.content,
      items: q.items,
      preview: q.preview,
      answer: q.answer,
      answer_content: q.answer_content,
      inline_images: q.inline_images,
      q_figures: q.q_figures,
      a_figures: q.a_figures,
      summary: summary,
      note_type: note_type)
    q.notes << n
    topics.split(',').each do |e|
      next if e.blank?
      t = Topic.find_or_create(e, q.homework.subject)
      t.notes << n if t.present?
    end
    n.update_attributes({question_str: n.content.join + n.items.join,
      topic_str: n.topics.map { |e| e.name } .join(',') })
    n
  end

  def item_len
    item_max_len = items.map { |e| e.length } .max
  end
end
