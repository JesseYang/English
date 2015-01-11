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
      redirect_to new_account_session_path
    end
  end

  def student_app
    
  end

  def app_download
    
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
