#= require 'utility/ajax'
#= require 'utility/refresh_navbar'
#= require 'utility/tools'
$ ->

  $(".show-answer-btn").click ->
    if $(".question-answer").hasClass("hide")
      $(".question-answer").removeClass("hide")
      $(this).text("隐藏答案")
    else
      $(".question-answer").addClass("hide")
      $(this).text("显示答案")

  $("#email-checkbox").change ->
    if $(this).is(":checked")
      $("#email-input").attr("disabled", false)
    else
      $("#email-input").attr("disabled", true)

  $("#export-btn").click ->
    # check the illegal of email
    if $("#email-checkbox").is(":checked") && !$.validateEmail($("#email-input").val())
      $("#export-notification").notification({content: "请输入正确格式的邮箱"})
      return
    $("#export-btn").text("正在导出...")
    $("#export-btn").attr("disabled", true)
    $this = $(this)
    $.getJSON(
      '/user/notes/export',
      {
        has_answer: $("#answer-checkbox").is(":checked"),
        send_email: $("#email-checkbox").is(":checked"),
        email: $("#email-input").val()
      },
      (retval) ->
        $('#export').modal('toggle')
        $this.attr("disabled", false)
        $this.text("导出")
        console.log retval.file_path
        if $("#email-checkbox").is(":checked")
          $("#app-notification").notification({content: "已导出并发送至" + $("#email-input").val()})
        else
          window.open "/" + retval.file_path
          $('#download a').attr("href", "/" + retval.file_path)
          $('#download').modal('toggle')
    )



  $("#check_questions").click ->
    $.get(
      '/user/questions/' + $(this).data("question-id") + '/similar',
      { },
      (retval) ->
        $(".page-operation-div").addClass("hide")
        $(".question-operation-div").removeClass("hide")
        $("#similar-questions-div").html(retval)
        $("#similar-questions-div").slideDown()
    )
    false

  $("#append_note").click ->
    $this = $(this)
    $.postJSON(
      '/user/questions/' + $(this).data("question-id") + '/append_note',
      { },
      (retval) ->
        console.log retval
        if !retval.success && retval.reason == "require sign in"
          $('#sign').modal({
            show: 'false'
          });
        else
          $this.attr("disabled", true)
          $this.html("已加入错题本")
    )
    false

  $("form#sign_in_user").bind "ajax:success", (e, data, status, xhr) ->
    if data.success
      # hide the sign modal
      $('#sign').modal('hide')
      # append the question to the note
      $.postJSON(
        '/user/questions/' + $("#append_note").data("question-id") + '/append_note',
        { },
        (retval) ->
          $("#append_note").attr("disabled", true)
          $.refresh_navbar($("#sign_in_user #user_email").val())
      )
      # show the notification
      $("#app-notification").notification({content: "登录成功，已加入错题本"})
    else
      $("#sign-notification").notification({content: "邮箱或密码错误"})
      
  $("form#sign_up_user").bind "ajax:success", (e, data, status, xhr) ->
    if data.success
      # hide the sign modal
      $('#sign').modal('hide')
      # append the question to the note
      $.postJSON(
        '/user/questions/' + $("#append_note").data("question-id") + '/append_note',
        { },
        (retval) ->
          $("#append_note").attr("disabled", true)
          $.refresh_navbar($("#sign_up_user #user_email").val())
      )
      # show the notification
      $("#app-notification").notification({content: "注册成功，已加入错题本"})
    else
      $("#sign-notification").notification({content: "注册失败"})