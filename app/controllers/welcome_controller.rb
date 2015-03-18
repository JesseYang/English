class WelcomeController < ApplicationController
  layout :resolve_layout
  def index
    flash[:notice] = params[:notice]
    # if current_user.try(:school_admin)
    #   redirect_to school_admin_teachers_path and return
    # elsif current_user.try(:teacher)
    if current_user.try(:teacher)
      redirect_to teacher_nodes_path and return
    elsif current_user.present?
      redirect_to student_notes_path and return
    else
      redirect_to new_account_session_path + "?role=#{params[:role]}"
    end
  end

  def student_app
    
  end

  def app_download
    
  end

  def app_version
    retval = { success: true, android: "1.1", ios: "1.0", android_url: "", ios_url: "" }
    retval[:auth_key] = current_user.generate_auth_key if current_user.present?
    render json: retval and return
  end

  private

  def resolve_layout
    case action_name
    when "index"
      'layouts/index'
    when "student_app", "app_download"
      'layouts/welcome'
    end
  end
end
