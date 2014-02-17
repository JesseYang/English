class User::QuestionsController < User::ApplicationController
  before_filter :require_sign_in, only: [:append_note, :append_print]

  def show
    @question = Question.find(params[:id])
    q_ids = @question.group.questions.map { |e| e.id.to_s }
    q_ids.delete(@question.id.to_s)
    @similar_questions_length = q_ids.length
  end

  def append_note
    current_user.add_question_to_note(params[:id])
    respond_to do |format|
      format.html
      format.json do
        render json: { success: true }
      end
    end
  end

  def exercise
    if params[:type] == "group"
      q = Question.find(params[:question_id])
      @questions = q.group.questions
    elsif params[:type] = "note"
      q = Question.find(params[:question_id])
      @questions = current_user.note.map { |e| Question.find(e) }
    else
      @questions = []
    end
  end

  def answer
    logger.info "AAAAAAAAAAAAAAAAAAA"
    logger.info params[:qid_ary]
    logger.info params[:answer_ary]
    logger.info "AAAAAAAAAAAAAAAAAAA"
    questions = params[:qid_ary].map { |e| Question.find(e) }
    result = { detail: [], stats: {right: 0, wrong: 0} }
    questions.each_with_index do |q, index|
      result[:detail] << {
        qid: q.id.to_s,
        answer: q.answer.to_i,
        user_answer: params[:answer_ary][index].to_i
      }
      if q.answer.to_i == params[:answer_ary][index].to_i
        result[:stats][:right] += 1
      else
        result[:stats][:wrong] += 1
      end
    end
    respond_to do |format|
      format.html
      format.json do
        render json: { result: result }
      end
    end
  end
end
