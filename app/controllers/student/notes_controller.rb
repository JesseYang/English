# encoding: utf-8
class Student::NotesController < Student::ApplicationController
  before_filter :require_student, only: [:create, :batch]

  def create
    begin
      note = current_user.add_note(params[:question_id], params[:summary].to_s, params[:tag].to_s, params[:topics].to_s)
      new_teacher = note.check_teacher(current_user)
      retval = { note: note, note_update_time: current_user.note_update_time }
      retval[:teacher] = new_teacher.teacher_info_for_student(true) if new_teacher.present?
      render_with_auth_key retval
    rescue Mongoid::Errors::InvalidFind, Mongoid::Errors::DocumentNotFound
      render_with_auth_key ErrCode.ret_false(ErrCode::QUESTION_NOT_EXIST)
    end
  end

  def batch
    begin
      notes = params[:question_ids].map { |qid| current_user.add_note(qid) }
      new_teachers = notes.map { |n| n.check_teacher(current_user) }
      new_teachers = new_teachers.select { |e| !e.nil? } .uniq
      retval = { note_update_time: current_user.note_update_time }
      if new_teachers.present?
        retval[:teachers] = new_teachers.map { |e| e.teacher_info_for_student(true) }
      end
      render_with_auth_key retval
    rescue Mongoid::Errors::InvalidFind, Mongoid::Errors::DocumentNotFound
      render_with_auth_key ErrCode.ret_false(ErrCode::QUESTION_NOT_EXIST)
    end
  end

  def note_update_time
    render_with_auth_key({ note_update_time: current_user.note_update_time })
  end

  def index
    render_with_auth_key({ notes: current_user.list_notes })
  end

  def show
    begin
      note = current_user.notes.find(params[:id])
      render_with_auth_key({ note: note })
    rescue Mongoid::Errors::InvalidFind, Mongoid::Errors::DocumentNotFound
      render_with_auth_key ErrCode.ret_false(ErrCode::NOTE_NOT_EXIST)
    end
  end

  def update
    begin
      note = current_user.update_note(params[:id], params[:summary], params[:tag].to_s, params[:topics].to_s)
      render_with_auth_key({ note: note, note_update_time: current_user.note_update_time })
    rescue Mongoid::Errors::InvalidFind, Mongoid::Errors::DocumentNotFound
      render_with_auth_key ErrCode.ret_false(ErrCode::NOTE_NOT_EXIST)
    end
  end

  def destroy
    begin
      current_user.rm_note(params[:id])
      render_with_auth_key({ note_update_time: current_user.note_update_time })
    rescue Mongoid::Errors::InvalidFind, Mongoid::Errors::DocumentNotFound
      render_with_auth_key ErrCode.ret_false(ErrCode::NOTE_NOT_EXIST)
    end
  end

  def export
    file_path = current_user.export_note(
      params[:note_id_str],
      params[:has_answer].to_s == "true",
      params[:has_note].to_s == "true",
      params[:email]
    )
    render_with_auth_key({ file_path: file_path })
  end
end
