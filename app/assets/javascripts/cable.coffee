# Action Cable provides the framework to deal with WebSockets in Rails.
# You can generate new channels where WebSocket features live
# using the rails generate channel command.
#
# Turn on the cable connection by removing the comments
# after the require statements (and ensure it's also on in config/routes.rb).
#
#= require action_cable
#= require_self
#= require_tree ./channels

@App ||= {}

protocol = if location.protocol.match(/^https/)
  'wss'
else
  'ws'

App.cable = ActionCable.createConsumer("#{protocol}:#{location.host}/cable")
#                    -> createConsumer('ws://localhost:3000/cable')

events = App.cable.subscriptions.create "EventsChannel",
  # ws.onOpen
  connected: ->
    $('.connecting').hide()
    $('.connected').show()

  # ws.onClose
  disconnected: ->
    $('.connecting').show().text('Oops, cable gone away, trying to reconnect')
    $('.connected').hide()

  # ws.onMessage
  received: (data) ->
    #$('.debug').text(JSON.stringify(data, null, 4))
    $('#connected-count').text(data.count)
    message = "<li>Connection request for #{data.count} took " +
              "#{Math.round(new Date().getTime() - data.broadcastAt)} ms"
    $('ul#requests').prepend(message)

  requestCount: (data) ->
    $('.debug').text("XXX" + JSON.stringify(data, null, 4))
    @perform("request_count", data)

  streamLiveCount: (data) ->
    @perform("stream_live_count")

notifs = App.cable.subscriptions.create "NotificationsChannel",
  received: (data) ->
    $('ul#requests').prepend("<li>Notification: #{data}</li>")

$(document).ready(->
  $('button#request-current-count').on 'click', ->
    d = {a: 12, b: 34}
    events.requestCount(d)
  $('button#live-current-count').on 'click', ->
    events.streamLiveCount()
    $('#live-current-count').hide()
)
