#= require 'utility/ajax'
#= require 'ui/widgets/folder_tree'
#= require 'ui/widgets/popup_menu'
#= require "extensions/page_notification"
#= require "./_templates/index_table"
#= require "./_templates/folder_chain"
#= require "./_templates/sharer_list"
#= require "./_templates/sharer_item"
$ ->
  guide = $.cookie(window.user_email + "nodes-index")
  if guide != "true"
    $.cookie(window.user_email + "nodes-index", "true", { expires: 20*365 })
    introJs().start()

  $("#share-input").autocomplete(
    source: "/teacher/settings/colleague_info"
  )
  $("#share-input").attr('autocomplete', 'on')

  $(".page-guide").click ->
    introJs().start()

  # forbit the default right-click popup menu
  $("html").bind "contextmenu", ->
    false
  $("html").click ->
    popup_menu.remove() if popup_menu != null
  $("html").mousedown (event) ->
    if event.button == 2
      popup_menu.remove() if popup_menu != null

  tree = null
  move_tree = null
  homework_table = null
  nodes = [ ]
  popup_menu = null

  refresh_homework_table_and_folder_chain = ->
    if window.flash == ""
      notification = $.page_notification("正在加载", 0)
    if window.type == "folder"
      $.getJSON "/teacher/folders/#{window.folder_id}/chain", (data) ->
        if data.success
          chain_data = 
            type: window.type
            folder_chain: data.chain
          folder_chain = $(HandlebarsTemplates["folder_chain"](chain_data))
          $("#folder-wrapper").empty()
          $("#folder-wrapper").append(folder_chain)
        else
          $.page_notification "服务器出错"
    else
      folder_chain = $(HandlebarsTemplates["folder_chain"](type: window.type))
      $("#folder-wrapper").empty()
      $("#folder-wrapper").append(folder_chain)

    data_url =
      folder: "/teacher/nodes/#{window.folder_id}/list_children"
      all_shares: "/teacher/nodes/all_shares"
      trash: "/teacher/nodes/trash"
      recent: "/teacher/nodes/recent"
      starred: "/teacher/nodes/starred"
      search: "/teacher/nodes/search?keyword=" + encodeURIComponent(window.keyword)
      all_homeworks: "/teacher/nodes/all_homeworks"
      all_slides: "/teacher/nodes/all_slides"
      workbook: "/teacher/nodes/workbook"
    $.getJSON data_url[window.type], (data) ->
      if data.success
        table_data = 
          type: window.type
          nodes: data.nodes
          has_content: data.nodes.length > 0
        homework_table = $(HandlebarsTemplates["index_table"](table_data))
        $("#table-wrapper").empty()
        $("#table-wrapper").append(homework_table)
        notification.notification("set_delay", 500) if notification != undefined
      else
        $.page_notification "服务器出错"

  # get the tree stucture
  $.getJSON "/teacher/folders", (data) ->
    if data.success
      tree = $("#left-part #root-folder").folder_tree(
        content: data.tree
        root_folder_id: data.root_folder_id
        click_name_fun: redirect_folder
      )
      tree.folder_tree("select_folder", window.folder_id) if window.folder_id != ""
    else
      $.page_notification "服务器出错"

  # get the homework table content
  refresh_homework_table_and_folder_chain()

  $("body").on "mousedown", "#root-folder .name-node", (event) ->
    if event.button is 2
      node_type = "Folder"
      id = tree.folder_tree("get_folder_id_by_name_node", event.target)
      name = $(event.target).closest(".name-node").find(".name").text()
      page_type = "folder"
      popup_menu = $("<div />").appendTo("body")
      if $(event.target).closest(".name-node").hasClass("root")
        node_type = "root"
      popup_menu.popup_menu
        pos: [
          event.pageX
          event.pageY
        ]
        content: generate_popup_menu(id, node_type, page_type)
        id: id
        type: node_type
        name: name
      event.stopPropagation()

  $("body").on "mousedown", "#table-wrapper .record", (event) ->
    if event.button is 2
      node_type = $(event.target).closest("tr").attr("data-type")
      id = $(event.target).closest("tr").attr("data-id")
      name = $(event.target).closest("tr").attr("data-name")
      popup_menu = $("<div />").appendTo("body")
      popup_menu.popup_menu
        pos: [
          event.pageX
          event.pageY
        ]
        content: generate_popup_menu(id, node_type, window.type)
        id: id
        type: node_type
        name: name
      event.stopPropagation()

  ######## Begin: rename part ########
  $("body").on "click", ".popup-menu .rename", (event) ->
    data = popup_menu.popup_menu("option")
    $('.popup-menu').remove()
    $('#renameModal').modal('show')
    $("#renameModal").attr("data-type", data.type)
    $("#renameModal").attr("data-id", data.id)
    $("#renameModal .target").val(data.name)

  $('#renameModal').on 'shown.bs.modal', ->
    $('.target').focus()
    $('.target').select()

  $("#renameModal .ok").click ->
    rename($(this).closest("#renameModal"))

  $("#renameModal .target").keydown (event) ->
    code = event.which
    if code == 13
      rename($(this).closest("#renameModal"))

  rename = (modal) ->
    type = modal.attr("data-type")
    id = modal.attr("data-id")
    name = $.trim(modal.find(".target").val())
    if name == ""
      $.page_notification "请输入文件夹名称"
      return false
    $.putJSON "/teacher/nodes/#{id}/rename", {name: name}, (data) ->
      if data.success
        tree.folder_tree("rename_folder", id, name) if type == "Folder"
        refresh_homework_table_and_folder_chain()
      else
        $.page_notification "操作失败，请刷新页面重试"
      $("#renameModal").modal("hide")
  ######## End: rename part ########

  ######## Begin: open part ########
  $("body").on "click", ".popup-menu .open", (event) ->
    open_doc_from_popup_menu()

  $("body").on "click", ".popup-menu .edit", (event) ->
    open_doc_from_popup_menu()

  open_doc_from_popup_menu = ->
    data = popup_menu.popup_menu("option")
    if data.type == "Folder"
      $.page_notification "正在打开文件夹", 0
      window.location.href = "/teacher/nodes?folder_id=#{data.id}"
    else if data.type == "Homework"
      $.page_notification "正在打开作业", 0
      window.location.href = "/teacher/homeworks/#{data.id}"
    else if data.type == "Slide"
      $.page_notification "正在打开课件", 0
      window.location.href = "/teacher/slides/#{data.id}"
    else if data.type == "Share"
      $.page_notification "正在打开作业", 0
      window.location.href = "/teacher/shares/#{data.id}"

  $("body").on "click", "tr.record a .open", (event) ->
    open_doc_from_table($(event.target))

  $("body").on "click", "tr.record a .edit", (event) ->
    open_doc_from_table($(event.target))

  $("body").on "click", "tr.record .node-link", (event) ->
    open_doc_from_table($(event.target))

  open_doc_from_table = (node) ->
    if node.closest("table").attr("data-pagetype") == "trash"
      return false
    tr = node.closest("tr")
    id = tr.attr("data-id")
    node_type = tr.attr("data-type")
    if node_type == "Folder"
      $.page_notification "正在打开文件夹", 0
      window.location.href = "/teacher/nodes?folder_id=" + id
    else if node_type == "Homework"
      $.page_notification "正在打开作业", 0
      window.location.href = "/teacher/homeworks/" + id
    else if node_type == "Slide"
      $.page_notification "正在打开电子课件", 0
      window.location.href = "/teacher/slides/" + id
    else if node_type == "Share"
      $.page_notification "正在打开作业", 0
      window.location.href = "/teacher/shares/" + id
    false
  ######## End: open part ########

  ######## Begin: stat part ########
  $("body").on "click", ".popup-menu .stat", (event) ->
    open_stat_from_popup_menu()

  open_stat_from_popup_menu = ->
    data = popup_menu.popup_menu("option")
    if data.type == "Homework"
      $.page_notification "正在打开统计结果"
      window.location.href = "/teacher/homeworks/#{data.id}/stat"
    else if data.type == "Share"
      $.page_notification "正在打开统计结果"
      window.location.href = "/teacher/shares/#{data.id}/stat"

  $("body").on "click", "tr.record a .stat", (event) ->
    open_stat_from_table($(event.target))

  open_stat_from_table = (node) ->
    tr = node.closest("tr")
    id = tr.attr("data-id")
    node_type = tr.attr("data-type")
    if node_type == "Homework"
      $.page_notification "正在打开统计结果"
      window.location.href = "/teacher/homeworks/#{id}/stat"
    else if node_type == "Share"
      $.page_notification "正在打开统计结果"
      window.location.href = "/teacher/shares/#{id}/stat"
  ######## End: stat part ########

  ######## Begin: new folder part ########
  $("#create-new-link").click ->
    $("#create-dropdown-list").toggleClass("hide")
    false

  $("body").on "click", ".create-folder-link", (event) ->
    $('#newFolderModal').modal("show")
    $('#newFolderModal').attr("data-folderid", window.folder_id)

  $("body").click ->
    $("#create-dropdown-list").addClass("hide")

  $("body").on "click", ".popup-menu .new-folder", (event) ->
    # the new folder name dialog
    data = popup_menu.popup_menu("option")
    $('.popup-menu').remove()
    $('#newFolderModal').modal('show')
    $("#newFolderModal").attr("data-folderid", data.id)

  $('#newFolderModal').on 'shown.bs.modal', ->
    $('.target').focus()
    $('.target').select()

  $("#newFolderModal .ok").click ->
    parent_id = $(this).closest("#newFolderModal").attr("data-folderid")
    name = $.trim($(this).closest("#newFolderModal").find(".target").val())
    new_folder(parent_id, name)

  $("#newFolderModal .target").keydown (event) ->
    code = event.which
    if code == 13
      parent_id = $(this).closest("#newFolderModal").attr("data-folderid")
      name = $.trim($(this).closest("#newFolderModal").find(".target").val())
      new_folder(parent_id, name)

  new_folder = (parent_id, name) ->
    if name == ""
      $.page_notification "请输入文件夹名称"
      return false
    $.postJSON '/teacher/folders',
      {
        parent_id: parent_id 
        name: name
      }, (data) ->
        if data.success
          new_folder_data =
            id: data.folder._id
            name: name
            children: [ ]
          tree.folder_tree("insert_folder", parent_id, new_folder_data)
          tree.folder_tree("open_folder", parent_id)
          refresh_homework_table_and_folder_chain()
        else
          $.page_notification "操作失败，请刷新页面重试"
        $("#newFolderModal").modal("hide")
  ######## End: new folder part ########

  ######## Begin: upload slide part ########
  slideIntervalFunc = ->
    $('#slide-name').html $('#slide_file').val();
  $("#browser-slide-click").click ->
    $("#slide_file").click()
    setInterval(slideIntervalFunc, 1)

  $("body").on "click", ".popup-menu .upload-slide", (event) ->
    data = popup_menu.popup_menu("option")
    $('.popup-menu').remove()
    $('#uploadSlideModal').modal('show')
    $("#uploadSlideModal #folder_id").val(data.id)

  $("#upload-slides-link").click ->
    folder_id = tree.folder_tree("get_selected_folder_id") || window.root_folder_id
    $('#uploadSlideModal').modal("show")
    $("#uploadSlideModal #folder_id").val(folder_id)

  $("#uploadSlideModal form").submit ->
    if $("#uploadSlideModal #slide_file").val() == ""
      notification = $("<div />").appendTo("#uploadSlideModal") 
      notification.notification
        content: "请先选择要上传的课件文件"
      return false
    if !$("#uploadSlideModal #slide_file").val().match(/\.pptx?$/)
      notification = $("<div />").appendTo("#uploadSlideModal") 
      notification.notification
        content: "文件格式错误，请上传ppt或者pptx格式文件"
        delay: 2000
      return false
    notification = $("<div />").appendTo("#uploadSlideModal") 
    notification.notification
      delay: 0
      content: "正在创建课件，请稍候"
  ######## End: upload slide part ########

  ######## Begin: upload homework part ########
  homeworkIntervalFunc = ->
    $('#homework-name').html $('#homework_file').val();
  $("#browser-homework-click").click ->
    $("#homework_file").click()
    setInterval(homeworkIntervalFunc, 1)

  $("body").on "click", ".popup-menu .upload-homework", (event) ->
    data = popup_menu.popup_menu("option")
    $('.popup-menu').remove()
    $('#uploadHomeworkModal').modal('show')
    $("#uploadHomeworkModal #folder_id").val(data.id)

  $("body").on "click", ".upload-doc-link", (event) ->
    folder_id = tree.folder_tree("get_selected_folder_id") || window.root_folder_id
    $('#uploadHomeworkModal').modal('show')
    $("#uploadHomeworkModal #folder_id").val(folder_id)

  $("#uploadHomeworkModal form").submit ->
    if $("#uploadHomeworkModal #homework_file").val() == ""
      notification = $("<div />").appendTo("#uploadHomeworkModal") 
      notification.notification
        content: "请先选择要上传的作业文件"
      return false
    if !$("#uploadHomeworkModal #homework_file").val().match(/\.docx?$/)
      notification = $("<div />").appendTo("#uploadHomeworkModal") 
      notification.notification
        content: "文件格式错误，请上传doc或者docx格式文件"
        delay: 2000
      return false
    $("#uploadHomeworkModal .btn-primary").attr("disabled", "true")
    notification = $("<div />").appendTo("#uploadHomeworkModal") 
    notification.notification
      delay: 0
      content: "正在创建作业，请稍候"
  ######## End: upload homework part ########

  ######## Begin: create homework part ########
  $("body").on "click" ,".popup-menu .new-homework", (event) ->
    data = popup_menu.popup_menu("option")
    $(".popup-menu").remove()
    $('#newHomeworkModal').modal("show")
    $('#newHomeworkModal .folder_id').val(data.id)

  $("body").on "click", ".new-homework-link", (event) ->
    folder_id = tree.folder_tree("get_selected_folder_id") || window.root_folder_id
    $("#newHomeworkModal").modal('show')
    $("#newHomeworkModal .folder-id").val(folder_id)

  $("#newHomeworkModal .ok").click ->
    newHomework()

  $("#newHomeworkModal .target").keydown (event) ->
    code = event.which
    if code == 13
      newHomework()

  newHomework = ->
    name = $.trim($("#newHomeworkModal .target").val())
    if name == ""
      $.page_notification "请输入作业标题"
      return false
    $("#newHomeworkModal .btn-primary").attr("disabled", "true")
    subject = $("#newHomeworkModal #subject").val()
    folder_id = $("#newHomeworkModal .folder-id").val()
    $.postJSON '/teacher/homeworks/create_blank',
      {
        parent_id: folder_id 
        subject: subject 
        name: name
      }, (data) ->
        if data.success
          refresh_homework_table_and_folder_chain()
          window.location.href = "/teacher/homeworks/#{data.homework_id}"
        else
          $.page_notification "操作失败，请刷新页面重试"
        $("#newHomeworkModal").modal("hide")
  ######## End: create homework part ########

  ######## Begin: share part ########
  $("body").on "click", "tr.record a .share", (event) ->
    tr = $(event.target).closest("tr")
    node_type = tr.attr("data-type")
    return if node_type != "Homework"
    name = tr.attr("data-name")
    id = tr.attr("data-id")
    show_share_modal(node_type, id, name)

  $("body").on "click", ".popup-menu .share", (event) ->
    data = popup_menu.popup_menu("option")
    $('.popup-menu').remove()
    show_share_modal(data.type, data.id, data.name)

  show_share_modal = (node_type, id, name) ->
    $("#shareModal").modal("show")
    $("#shareModal").attr("data-type", node_type)
    $("#shareModal").attr("data-id", id)
    $("#shareModal").find('.target-name').text(name)
    $("#shareModal").find("#share-input").val("")
    $.getJSON "/teacher/homeworks/#{id}/share_info", (data) ->
      if data.success
        sharer_list_data = { sharer: data.share_info }
        sharer_list = $(HandlebarsTemplates["sharer_list"](sharer_list_data))
        $("#sharer-list").empty()
        $("#sharer-list").append(sharer_list)
      else
        $.page_notification "服务器出错"

  $("body").on "click", "#shareModal .editable", (event) ->
    li = $(event.target).closest("li")
    cur_editable = li.attr("data-editable")
    if cur_editable == "true"
      li.attr("data-editable", "false")
      li.find(".editable").text("不可编辑")
    else
      li.attr("data-editable", "true")
      li.find(".editable").text("可编辑")

  $("body").on "click", "#shareModal .close-link", (event) ->
    li = $(event.target).closest("li")
    li.remove()

  add_colleague = (info) ->
    cur_list = [ ]
    $("#shareModal ul li").each ->
      cur_list.push($(this).attr("data-id"))
    cur_list_str = cur_list.join(',')
    $.getJSON "/teacher/settings/teacher_info?info=#{info}&list=#{cur_list_str}", (data) ->
      if data.success
        if data.id != undefined
          sharer_item = $(HandlebarsTemplates["sharer_item"](data))
          $(".sharer-list").append(sharer_item)
      else
        $.page_notification "服务器出错"

  $("#share-input").autocomplete(
    select: (event, ui) ->
      value = ui.item.value
      add_colleague(value)
      $("#share-input").val("")
      false
  )

  $("#shareModal .ok").click ->
    modal = $("#shareModal")
    id = modal.attr("data-id")
    teachers = [ ]
    $("#shareModal ul li").each ->
      teacher = {
        id: $(this).attr("data-id")
        editable: $(this).attr("data-editable")
      }
      teachers.push(teacher)
    $.putJSON '/teacher/homeworks/' + id + "/share",
      {
        teachers: teachers
      }, (data) ->
        if data.success
          modal.modal("hide")
          $.page_notification "完成共享设置"
        else
          $.page_notification "操作失败，请刷新页面重试"
        modal.modal("hide")
  ######### End: share part #########

  ######## Begin: move part ########
  $("body").on "click", ".popup-menu .move", (event) ->
    data = popup_menu.popup_menu("option")
    $('.popup-menu').remove()
    show_move_modal(data.type, data.id, data.name)

  $("body").on "click", "tr.record a .move", (event) ->
    tr = $(event.target).closest("tr")
    node_type = tr.attr("data-type")
    name = tr.attr("data-name")
    id = tr.attr("data-id")
    show_move_modal(node_type, id, name)

  show_move_modal = (node_type, id, name) ->
    $('#moveModal').modal('show')
    $("#moveModal").attr("data-type", node_type)
    $("#moveModal").attr("data-id", id)
    $("#moveModal").find('.target-name').text(name)
    $.getJSON "/teacher/folders", (data) ->
      if data.success
        move_tree = $("#moveModal #move-folder").folder_tree(
          content: data.tree
          root_folder_id: data.root_folder_id
          click_name_fun: (folder_id) ->
            move_tree.folder_tree("select_folder", folder_id)
        )
        move_tree.folder_tree("remove_folder", id) if node_type == "Folder"
        move_tree.folder_tree("select_folder", data.root_folder_id)
        move_tree.folder_tree("open_folder", data.root_folder_id)
      else
        $.page_notification "服务器出错"

  $('#moveModal').on 'hidden.bs.modal', ->
    move_tree.folder_tree("destroy")

  $('#moveModal .ok').click ->
    move($(this).closest("#moveModal"))

  $('#moveModal #move-folder').keydown (event) ->
    code = event.which
    if code == 13
      move($(this))

  move = (modal) ->
    node_type = modal.attr("data-type")
    id = modal.attr("data-id")
    des_folder_id = move_tree.folder_tree("get_selected_folder_id")
    $.putJSON '/teacher/nodes/' + id + "/move",
      {
        des_folder_id: des_folder_id
      }, (data) ->
        if data.success
          if node_type == "Folder"
            tree.folder_tree("move_folder", id, des_folder_id)
          refresh_homework_table_and_folder_chain()
        else
          $.page_notification "操作失败，请刷新页面重试"
        modal.modal("hide")
  ######## End: move part ########

  ######## Begin: delete part ########
  $("body").on "click", ".popup-menu .delete", (event) ->
    node_type = popup_menu.popup_menu("option", "type")
    id = popup_menu.popup_menu("option", "id")
    delete_node(node_type, id)

  $("body").on "click", "tr.record a .remove", (event) ->
    tr = $(event.target).closest("tr")
    node_type = tr.attr("data-type")
    id = tr.attr("data-id")
    delete_node(node_type, id)

  delete_node = (node_type, id) ->
    $.deleteJSON "/teacher/nodes/" + id + "/delete", {}, (data) ->
      if data.success
        if node_type == "Folder"
          $(".popup-menu").remove()
          if window.folder_id == id
            parent_id = tree.folder_tree("get_parent_id", id)
            window.location.href = "/teacher/nodes?folder_id=" + parent_id
          else if tree.folder_tree("is_ancestor", id, window.folder_id)
            window.location.href = "/teacher/nodes?folder_id=" + window.root_folder_id
          else
            tree.folder_tree("remove_folder", id)
            refresh_homework_table_and_folder_chain()
        else
          $(".popup-menu").remove()
          refresh_homework_table_and_folder_chain()
      else
        $.page_notification "操作失败，请刷新页面重试"
  ######## End: delete part ########

  ######## Begin: redirect part ########
  redirect_folder = (folder_id) ->
    window.location = '/teacher/nodes?folder_id=' + folder_id
  ######## End: redirect part ########

  ######## Begin: open parent part ########
  $("body").on "click", ".popup-menu .open-parent", (event) ->
    id = popup_menu.popup_menu("option", "id")
    $.getJSON "/teacher/nodes/" + id + "/get_folder_id", (data) ->
      if data.success
        window.location = "/teacher/nodes?folder_id=" + data.folder_id
      else
        $.page_notification "操作失败，请刷新页面重试"
  ######## End: open parent part ########

  ######## Begin: recover part ########
  $("body").on "click", ".popup-menu .recover", (event) ->
    id = popup_menu.popup_menu("option", "id")
    recover_node(id)

  $("body").on "click", "tr.record a .recover", (event) ->
    tr = $(event.target).closest("tr")
    id = tr.attr("data-id")
    recover_node(id)

  recover_node = (id) ->
    $.putJSON "/teacher/nodes/#{id}/recover", { }, (data) ->
      if data.success
        window.location = "/teacher/nodes?folder_id=" + data.parent_id
      else
        $.page_notification "操作失败，请刷新页面重试"

  $("body").on "click", "*[data-pagetype=trash] a.node-link", (event) ->
    $("#recoverModal").modal('show')
    id = $(event.target).closest("tr").attr("data-id")
    $("#recoverModal").attr("data-id", id)
    event.preventDefault()

  $("#recoverModal .ok").click ->
    id = $("#recoverModal").attr("data-id")
    $.putJSON "/teacher/nodes/#{id}/recover", { }, (data) ->
      if data.success
        window.location = "/teacher/nodes?folder_id=" + data.parent_id
      else
        $.page_notification "操作失败，请刷新页面重试"
  ######## End: recover part ########

  ######## Begin: other redirect part ########
  $.each ["trash", "recent", "workbook", "starred", "all_homeworks", "all_slides", "all_shares"], (i, v) ->
    $(".#{v}").click ->
      window.location = "/teacher/nodes?type=#{v}"
  ######## End: other redirect part ########

  ######## Begin: destroy part ########
  $("body").on "click", ".popup-menu .destroy", ->
    id = popup_menu.popup_menu("option", "id")
    destroy_node(id)

  $("body").on "click", "tr.record a .destroy", (event) ->
    tr = $(event.target).closest("tr")
    id = tr.attr("data-id")
    destroy_node(id)

  destroy_node = (id) ->
    $.deleteJSON "/teacher/nodes/#{id}", { }, (data) ->
      if data.success
        $(".popup-menu").remove()
        refresh_homework_table_and_folder_chain()
      else
        $.page_notification "操作失败，请刷新页面重试"
  ######## End: destroy part ########

  ######## Begin: search part ########
  $("#link-search").click ->
    keyword = $("#input-search").val()
    search(keyword)

  $("#input-search").keydown (event) ->
    code = event.which
    if code == 13
      search($(this).val())

  search = (keyword) ->
    if $.trim(keyword) == ""
      $.page_notification "请输入关键字"
      return
    window.location = "/teacher/nodes?type=search&keyword=" + encodeURIComponent(keyword)
  ######## End: destroy part ########

  ######## Begin: add/remove star part #########
  $("body").on "click", ".star-link", (event) ->
    id = $(event.target).closest("tr").attr("data-id")
    icon = $(event.target).closest(".star-link").find("i")
    add_star = icon.hasClass("star-empty")
    $.putJSON "/teacher/nodes/#{id}/star", {
      add: add_star
    }, (data) ->
      if data.success
        if add_star
          icon.removeClass("star-empty")
          icon.addClass("starred")
        else
          icon.addClass("star-empty")
          icon.removeClass("starred")
      else
        $.page_notification "操作失败，请刷新页面重试"
  ######## End: add/remove star part ########


  generate_popup_menu = (id, node_type, page_type) ->
    if node_type == "root"
      return [
        {
          text: "新建文件夹"
          class: "new-folder"
        }
        {
          text: "上传作业"
          class: "upload-homework"
        }
        {
          text: "新建作业"
          class: "new-homework"
        }
      ]
    if page_type == "trash"
      return [
        {
          text: "还原"
          class: "recover"
        }
        {
          text: "彻底删除"
          class: "destroy"
        }
      ]
    if page_type == "recent" || page_type == "search" || page_type == "all_homeworks" || page_type == "all_slides" || page_type == "all_shares" || page_type == "starred"
      return [
        {
          text: "新建文件夹"
          class: "new-folder"
        }
        {
          text: "上传作业"
          class: "upload-homework"
        }
        {
          text: "新建作业"
          class: "new-homework"
        }
        {
          hr: true
        }
        {
          text: "打开所在文件夹"
          class: "open-parent"
        }
        {
          text: "重命名"
          class: "rename"
        }
        {
          text: "移动"
          class: "move"
        }
        {
          text: "删除"
          class: "delete"
        }
      ] if node_type == "Folder"
      return [
        {
          text: "编辑"
          class: "edit"
        }
        {
          text: "统计"
          class: "stat"
        }
        {
          hr: true
        }
        {
          text: "打开所在文件夹"
          class: "open-parent"
        }
        {
          text: "重命名"
          class: "rename"
        }
        {
          text: "移动"
          class: "move"
        }
        {
          text: "删除"
          class: "delete"
        }
        {
          text: "共享"
          class: "share"
        }
      ] if node_type == "Homework"
      return [
        {
          text: "打开"
          class: "edit"
        }
        {
          hr: true
        }
        {
          text: "打开所在文件夹"
          class: "open-parent"
        }
        {
          text: "重命名"
          class: "rename"
        }
        {
          text: "移动"
          class: "move"
        }
        {
          text: "删除"
          class: "delete"
        }
      ] if node_type == "Slide"
      return [
        {
          text: "编辑"
          class: "edit"
        }
        {
          text: "统计"
          class: "stat"
        }
        {
          hr: true
        }
        {
          text: "打开所在文件夹"
          class: "open-parent"
        }
        {
          text: "移动"
          class: "move"
        }
        {
          text: "删除"
          class: "delete"
        }
      ] if node_type == "Share"
    if page_type == "folder"
      return [
        {
          text: "新建文件夹"
          class: "new-folder"
        }
        {
          text: "上传作业"
          class: "upload-homework"
        }
        {
          text: "新建作业"
          class: "new-homework"
        }
        {
          hr: true
        }
        {
          text: "重命名"
          class: "rename"
        }
        {
          text: "移动"
          class: "move"
        }
        {
          text: "删除"
          class: "delete"
        }
      ] if node_type == "Folder"
      return [
        {
          text: "编辑"
          class: "edit"
        }
        {
          text: "统计"
          class: "stat"
        }
        {
          hr: true
        }
        {
          text: "重命名"
          class: "rename"
        }
        {
          text: "移动"
          class: "move"
        }
        {
          text: "删除"
          class: "delete"
        }
        {
          text: "共享"
          class: "share"
        }
      ] if node_type == "Homework"
      return [
        {
          text: "打开"
          class: "edit"
        }
        {
          hr: true
        }
        {
          text: "重命名"
          class: "rename"
        }
        {
          text: "移动"
          class: "move"
        }
        {
          text: "删除"
          class: "delete"
        }
      ] if node_type == "Slide"
      return [
        {
          text: "编辑"
          class: "edit"
        }
        {
          text: "统计"
          class: "stat"
        }
        {
          hr: true
        }
        {
          text: "移动"
          class: "move"
        }
        {
          text: "删除"
          class: "delete"
        }
      ] if node_type == "Share"
