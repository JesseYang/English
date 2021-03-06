# encoding: utf-8
class Tablet::ActionLogsController < Tablet::ApplicationController

  def index
    u = User.find(params[:student_id])
    @logs = u.action_logs.all.asc(:log_id)
  end

  def create
    retval = ActionLog.batch_create(params[:logs])
    render json: { success: true, max_id: retval.max } and return
  end

  def clear
    ActionLog.destroy_all
    redirect_to action: :index and return
  end
end
