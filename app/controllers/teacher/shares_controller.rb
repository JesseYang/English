# encoding: utf-8
class Teacher::SharesController < Teacher::ApplicationController
  layout :resolve_layout
  before_filter :ensure_homework, only: [:show, :stat, :move, :settings, :set_tag, :delete, :export, :generate, :star, :set_basic_setting, :set_tag_set, :reorder, :share, :share_info]

  def ensure_homework
    begin
      @share = Share.find(params[:id])
      @editable = @share.editable
      @homework = @share.node
    rescue
      respond_to do |format|
        format.html
        format.json do
          render_json ErrCode.ret_false(ErrCode::HOMEWORK_NOT_EXIST) and return
        end
      end
    end
  end

  def show
    @title = @homework.name + "-编辑"
    render "teacher/homeworks/show"
  end

  def stat
    @title = @homework.name + "-统计"
    @notes = @share.notes
    @users = @notes.map { |e| e.user } .uniq

    @students = @users.select { |e| @current_user.has_student?(e) }
    @students_notes = @notes.select { |e| @students.include?(e.user) }

    @classes = @current_user.classes.map do |e|
      [e.name.to_s, e.id.to_s]
    end
    @classes.insert(0, ["全体学生", "-1"])
    render "teacher/homeworks/stat"
  end

  def settings
    @title = @homework.name + "-设置"
    @type = %w{basic export tag} .include?(params[:type]) ? params[:type] : "basic"
    case @type
    when "basic"
      @answer_time_type = @homework.answer_time_type || "no"
      @answer_time = @homework.format_answer_time
    when "export"
    when "tag"
      @tag_sets = current_user.tag_sets
      tag_set_ary = @homework.tag_set.split(',')
      all_tag_sets = current_user.tag_sets + TagSet.where(default: true)
      @tag_set_id = ""
      all_tag_sets.each do |tag_set|
        if tag_set_ary.uniq.sort == tag_set.tags.uniq.sort
          @tag_set_id = tag_set.id.to_s
        end
      end
    end
    render "teacher/homeworks/settings"
  end

  def set_basic_setting
    @homework.update_attribute(:name, params[:name])
    answer_time = Time.mktime(*(params[:answer_time].split('-'))).to_i if params[:answer_time_type] == "later"
    if @homework.answer_time_type != params[:answer_time_type]
      @homework.notes.each { |n| n.touch }
    elsif params[:answer_time_type] == "later" && @homework.answer_time != answer_time
      @homework.notes.each { |n| n.touch }
    end
    if %w{no now later} .include? params[:answer_time_type]
      @homework.update_attribute(:answer_time_type, params[:answer_time_type])
    end
    if params[:answer_time_type] == "later"
      @homework.update_attribute(:answer_time, answer_time)
    end
    render_json
  end

  def set_tag_set
    tag_set = TagSet.find(params[:tag_set_id])
    @homework.update_attribute(:tag_set, tag_set.tags.join(','))
    render_json
  end

  def export
    redirect_to URI.encode "/#{@homework.export}"
  end

  def generate
    download_url = "#{Rails.application.config.word_host}/#{@homework.generate(params[:question_qr_code].to_s == 'true', params[:app_qr_code].to_s == "true")}"
    render_json({ download_url: download_url })
  end

  def replace
    homework = Homework.find(params[:id])
    begin
      document = Document.new
      document.document = params[:replace_homework_file]
      document.store_document!
      document.replace_question(homework, params[:question_id])
      flash[:notice] = "已完成题目替换"
      redirect_to action: :show, id: homework.id.to_s
    rescue Exception => e
      if e.message == "wrong filetype"
        flash[:error] = "文件损坏，解析失败"
        redirect_to action: :show, id: homework.id.to_s
      elsif e.message == "no content"
        flash[:error] = "文件中没有有效内容"
        redirect_to action: :show, id: homework.id.to_s
      else
        flash[:error] = "服务器错误，请重试"
        redirect_to action: :show, id: homework.id.to_s
      end
    end
  end

  def insert
    homework = Homework.find(params[:id])
    begin
      document = Document.new
      document.document = params[:insert_homework_file]
      document.store_document!
      document.insert_question(homework, params[:question_id])
      flash[:notice] = "已完成题目插入"
      redirect_to action: :show, id: homework.id.to_s
    rescue Exception => e
      if e.message == "wrong filetype"
        flash[:error] = "文件损坏，解析失败"
        redirect_to action: :show, id: homework.id.to_s
      elsif e.message == "no content"
        flash[:error] = "文件中没有有效内容"
        redirect_to action: :show, id: homework.id.to_s
      else
        flash[:error] = "服务器错误，请重试"
        redirect_to action: :show, id: homework.id.to_s
      end
    end
  end

  def resolve_layout
    case action_name
    when "show", "stat", "settings"
      "layouts/homework"
    else
      "layouts/teacher"
    end
  end
end
