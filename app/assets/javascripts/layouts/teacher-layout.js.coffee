$ ->
  dropdown = false

  if window.controller == "teacher/homeworks"
    $("#app-user-navbar .nav .homeworks").addClass("active")

  $(".ef-dropdown-toggle").click (event) ->
    if $(this).hasClass("dropdown-active")
      $(this).removeClass("dropdown-active")
      $(".ef-dropdown-menu").addClass("hide")
      dropdown = false
    else
      $(this).addClass("dropdown-active")
      $(".ef-dropdown-menu").removeClass("hide")
      dropdown = true
    false

  $("body").click ->
    if dropdown
      $(".ef-dropdown-toggle").removeClass("dropdown-active")
      $(".ef-dropdown-menu").addClass("hide")
      dropdown = false
    true

  $(".ef-dropdown-menu").click ->
    false
