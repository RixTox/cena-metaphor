@Card = class Card
  constructor: (@parent, @card, @pass) ->
    tmpl = _.template $('#tmpl-line').html()
    @$el = $(tmpl card: @card, pass: @pass)[0]
    $('span.message', @$el).click =>
      $('.control', @$el).toggleClass 'show'
      false
    $('.control', @$el).mouseout ->
      $(@).removeClass 'show'
    $('.button.icon-remove', @$el).click =>
      @remove()
      false
    $('input', @$el).keydown (e) =>
      if e.keyCode == 13
        @go()
    $(@$el).hide()
    @parent.prepend @$el
    $(@$el).show 300, =>
      unless @card or @pass
        $('.input-card', @$el).focus()
  addMessage: (icon, message, style = '', show) ->
    if style instanceof Array
      style = style.join ' '
    if typeof style == 'string'
      style = "message #{style}"
    $wrap = $('span.message', @$el)
      .removeAttr('class')
      .addClass(style)
      .html('')
    $control = $('.control', @$el)
    unless icon and message
      return $control.removeClass 'slide'
    $icon = $("<icon class=\"icon-#{icon}\">")
    $message = $("<span>").text message
    $control.addClass 'slide'
    $wrap.append($icon).append($message)
    if show
      $('.control', @$el).addClass 'show'
  getCard: ->
    @card ? $('.input-card', @$el).val()
  getPass: ->
    @pass ? $('.input-pass', @$el).val()
  remove: ->
    return if @parent.length() <= 1
    @parent.remove @
    $(@$el).hide 300, =>
      @$el.remove()
  go: ->
    card = @getCard()
    pass = @getPass()
    return unless card and pass
    @addMessage 'loading icon-spin', 'Working'
    $.post 'start',
      card: card
      pass: pass
    , (data) =>
      console.log data
      if data.status == 'success'
        @addMessage 'tick', 'Done', 'success'
      if data.status == 'error'
        @addMessage 'cross', data.message, 'fail', true

@CardList = class CardList
  constructor: (@$el) ->
    @list = new Array()
  add: (num, pass) ->
    @list.push new Card @, num, pass
  append: (el) ->
    @$el.append el
  prepend: (el) ->
    @$el.prepend el
  start: ->
    for item in @list
      item.go()
  length: ->
    @list.length
  indexOf: (card) ->
    @list.indexOf card
  remove: (index) ->
    if typeof index == 'object'
      index = @indexOf index
    if index >= 0
      @list.splice index, 1

$(document).ready =>
  @cardList = new CardList $('#card-list')
  cardList.add()
  $('.button.add').click ->
    cardList.add()
    false
  $('.button.start').click ->
    cardList.start()
    false
