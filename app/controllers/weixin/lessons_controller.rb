require 'array'
# encoding: utf-8
class Weixin::LessonsController < Weixin::ApplicationController

  def exercise
    @local_course = LocalCourse.find(params[:local_course_id])
    @return_path = weixin_course_path(@local_course)
    @lesson = Lesson.find(params[:id])
    lesson_index = @local_course.course.lesson_id_ary.index(params[:id])
    @title = Lesson.lesson_helper(lesson_index) + @lesson.name

    @exercise = @lesson.homework
    @answer = Answer.ensure_answer(@current_user, @lesson.homework, @local_course.coach)
  end

  def report
    @local_course = LocalCourse.find(params[:local_course_id])
    @return_path = weixin_course_path(@local_course)
    @lesson = Lesson.find(params[:id])
    lesson_index = @local_course.course.lesson_id_ary.index(params[:id])
    @title = Lesson.lesson_helper(lesson_index) + @lesson.name
    @report = @current_user.reports.where(lesson_id: @lesson.id.to_s).first
  end

  def record
    @local_course = LocalCourse.find(params[:local_course_id])
    @return_path = weixin_course_path(@local_course)
    @lesson = Lesson.find(params[:id])
    lesson_index = @local_course.course.lesson_id_ary.index(params[:id])
    @title = Lesson.lesson_helper(lesson_index) + @lesson.name
  end
end
