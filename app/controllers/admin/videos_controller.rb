#encoding: utf-8
class Admin::VideosController < Admin::ApplicationController

  def index
    @lesson = Lesson.find(params[:lesson_id])
    @videos = [ ]
    @lesson.video_id_ary.each do |vid|
      next if vid.blank?
      @videos << Video.find(vid)
    end
  end

  def list
    l = Lesson.find(params[:lesson_id])
    videos = l.video_id_ary.map { |e| Video.find(e) }
    hash = { "请选择" => -1 }
    videos.each_with_index do |v, i|
      hash[v.course_name + ", " + v.lesson_name + ", 第#{i+1}段 " + v.name] = v.id.to_s
    end
    render json: { success: true, data: hash } and return
  end

  def show
    @video = Video.find(params[:id])
  end

  def create
    if params[:existing_video_content].to_s != "-1"
      existing_video = Video.find(params[:existing_video_content])
      video_url = existing_video.video_url
    else
      # save the video content file
      video_content = VideoContent.new
      video_content.video = params[:video_content]
      filetype = "mp4"
      video_content.store_video!
      filepath = video_content.video.file.file
      video_url = "/videos/" + filepath.split("/")[-1]
    end

    lesson = Lesson.find(params[:video]["lesson_id"])

    # @video = Video.new(video_type: params[:video]["video_type"].to_i,
    @video = Video.new(video_type: 1,
      name: params[:video]["name"],
      knowledge: params[:video]["knowledge"],
      video_url: video_url)
    @video.lesson = lesson
    @video.save

    # update the lesson_id_ary for the course
    index = params[:video]["order"].to_i - 1
    if index >= 0
      lesson.video_id_ary ||= []
      lesson.video_id_ary[index] = @video.id.to_s
      lesson.save
    end

    @video.touch_parents

    redirect_to action: :index, lesson_id: lesson.id.to_s and return
  end


  def update
    v = Video.find(params[:id])
    v.name = params[:video]["name"]
    v.knowledge = params[:video]["knowledge"]
    v.save
    render json: {success: true} and return
  end

  def destroy
    @video = Video.find(params[:id])
    lesson = @video.lesson
    if lesson.present?
      video_index = lesson.video_id_ary.index(@video.id.to_s)
      if video_index != -1
        lesson.video_id_ary[video_index] = nil
        lesson.save
      end
    end
    # if no other videos use the same file, remove the video file
    videos = Video.where(videl_url: @video.video_url)
    if videos.length == 1 && File.exist?("public" + @video.video_url)
      File.delete("public" + @video.video_url)
    end
    @video.destroy
    redirect_to action: :index, lesson_id: lesson.id.to_s and return
  end
end
