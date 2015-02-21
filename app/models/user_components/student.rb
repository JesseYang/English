# encoding: utf-8
module UserComponents::Student
  extend ActiveSupport::Concern

  included do
    field :note_update_time, type: Hash, default: {}
    has_many :notes
    has_and_belongs_to_many :klasses, class_name: "Klass", inverse_of: :students
  end

  module ClassMethods
    def search_teachers(subject, name)
      if name.blank?
        return { success: true, teachers: [] }
      end
      if subject == 0
        teachers = User.where(teacher: true, name: /#{name}/)
      else
        teachers = User.where(teacher: true, subject: subject, name: /#{name}/)
      end
      teachers_info = teachers.map { |t| t.teacher_info_for_student(true) }
      { success: true, teachers: teachers_info }
    end
  end

  def list_my_teachers
    teachers_info = self.klasses.map { |e| e.teacher } .uniq.map { |t| t.teacher_info_for_student }
    { success: true, teachers: teachers_info }
  end

  def teacher_info_for_student(with_classes = false)
    info = {
      id: self.id.to_s,
      name: self.name.to_s,
      subject: self.subject,
      school: self.school.name,
      desc: self.teacher_desc,
      avatar: ""
    }
    return info if !with_classes
    info[:classes] = []
    self.classes.each do |c|
      next if !c.visible
      info[:classes] << {
        id: c.id.to_s,
        name: c.name,
        desc: c.desc
      }
    end
    info
  end

  def list_notes
    self.notes.map { |e| [e.id.to_s, e.updated_at.to_i] }
  end

  def add_note(qid, hid, summary = "", tag = "", topics = "")
    note = self.notes.where(question_id: qid, homework_id: hid).first
    if note.present?
      note.update_note(summary, tag, topics)
    else
      note = Note.create_new(qid, summary, tag, topics)
      self.notes << note
    end
    self.set_note_update_time(note.subject)
    return note
  end

  def update_note(nid, summary, tag, topics)
    note = self.notes.find(nid)
    return if note.nil?
    note.update_note(summary, tag, topics)
    self.set_note_update_time(note.subject)
    return note
  end

  def rm_note(nid)
    note = self.notes.find(nid)
    note.destroy if note.present?
    self.set_note_update_time(note.subject)
  end

  def set_note_update_time(subject)
    self.note_update_time[subject] = Time.now.to_i
    self.save
  end

  def export_note(note_id_str, has_answer, has_note, email)
    notes = []
    note_id_str.split(',').each do |note_id|
      n = Note.where(id: note_id).first
      next if n.blank?
      note = {
        "type" => n.type,
        "image_path" => n.image_path
        "content" => n.content,
        "items" => n.items
      }
      if has_answer.to_s == "true"
        note.merge!({ "answer" => n.answer || -1, "answer_content" => n.answer_content })
      end
      if has_note.to_s == "true"
        note.merge!({ "tag" => n.tag, "topics" => n.topics.map { |e| e.name }, "summary" => n.summary })
      end
      notes << note
    end
    response = User.post("/ExportNote.aspx",
      :body => {notes: notes.to_json} )
    filepath = response.body
    download_path = "public/documents/export-#{SecureRandom.uuid}.docx"

    open(download_path, 'wb') do |file|
      file << open("#{Rails.application.config.word_host}/#{URI.encode filepath}").read
    end
    ExportNoteEmailWorker.perform_async(email, download_path) if email.present?
    URI.encode(download_path[download_path.index('/')+1..-1])
  end

  def move_to(old_klass, new_klass_id)
    self.klasses.delete(old_klass)
    new_klass = Klass.find(new_klass_id)
    self.klasses << new_klass
  end

  def copy_to(klass_id)
    klass = Klass.find(klass_id)
    self.klasses << klass if !self.klasses.include?(klass)
  end

  def delete_from_class(klass)
    self.classes.delete(klass) and return if klass.default
    teacher = klass.teacher
    other_classes = teacher.classes.where(:id.ne => klass.id)
    the_other_class = teacher.classes.where(default: true).first
    other_students = other_classes.map { |e| e.students }
    the_other_class.students << self if !other_students.include?(self)
    self.klasses.delete(klass)
  end
end
