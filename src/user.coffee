gum =require 'getusermedia'

create_element = (name, attrs)->
  el = document.createElement name
  for k,v of attrs
    el.setAttribute k,v
  return el

canvas = document.getElementById('leiwand')


my_col="grey"
draw_circle = (ctx, center, r, col)->
  ctx.beginPath()
  ctx.arc center.x, center.y, r, 0, 2 * Math.PI, false
  ctx.fillStyle = col
  ctx.fill()
  ctx.lineWidth = 1
  ctx.strokeStyle = '#222222'
  ctx.stroke()

draw = (data)->
  ctx = canvas.getContext '2d'
  ctx.canvas.width  = window.innerWidth
  ctx.canvas.height = window.innerHeight
  ctx.clearRect(0, 0, canvas.width, canvas.height)
  centerX = canvas.width / 2
  centerY = canvas.height / 2
  r_w = canvas.width/ 5
  r_h = canvas.height/ 5
  r = Math.min r_w, r_h
  #console.log "drawing", peer_id,g[peer_id] if g
  #console.log "m_conn", m_conn.open if m_conn?
  ctx.beginPath()
  ctx.arc centerX, centerY, r, 0, 2 * Math.PI, false
  ctx.fillStyle = my_col
  ctx.fill()
  ctx.lineWidth = 5
  ctx.strokeStyle = '#222222'
  ctx.stroke()
  if data?
    arr = (v for k,v of data when k isnt peer_id)
    theta_inc = 2*Math.PI / arr.length
    for a,i in arr
      theta = i* theta_inc
      center =
        x : centerX + (r * Math.cos theta)
        y : centerY + (r * Math.sin theta)
      draw_circle ctx,center,r/5, (if a.audio is "on" then "green" else "red" )
    
    
    
    

draw()

peer = new Peer '',
  key: '2rm8if3cntz3q5mi'
  iceServers: [
    url: 'stun:stun.l.google.com:19302'
  ]


peer_reconnect = ()->
  console.log "peer disconnected.."
  setTimeout ()->
    console.log "reconnecting to peer.."
    peer.reconnect()
  , 1000



d_conn=null
m_conn=null
m_stream=null
peer_id = null


peer.on 'open', (id)->
  peer_id =id
  console.log "connected as #{peer_id}"
  data_connect()
  gum {video:false,audio:true}, (err, media_stream)->
    return console.error err if err
    m_stream = media_stream
    media_connect()

peer.on 'close', ()-> peer_reconnect()
peer.on 'disconnected', ()-> peer_reconnect()
peer.on 'connection', (conn)-> console.log "got a data connection"

data_reconnect = ()->
  d_conn.close() if d_conn?
  d_conn=null
  setTimeout ()->
    data_connect()
  , 1000

data_connect = ()->
  d_conn  = peer.connect 'zentrum'
  d_conn.on 'error', (err)-> console.error err.message
  d_conn.on 'close', ()-> my_col="grey"; draw(); console.log "closed data"
  d_conn.on 'open', ()-> draw()
  d_conn.on 'data', (data)->
    d_conn.send now: Date.now()
    if m_conn?.open and  data?[peer_id]?.m_conn
      if data?[peer_id]?.audio is "on"
        my_col = "#00ff00"
      else
        my_col ="red"
    draw(data)


media_reconnect = ()->
  m_conn.close() if m_conn?
  m_conn = null
  setTimeout ()->
    media_connect()
  , 1000

media_connect = ()->
  console.log "doing media connect"
  if m_stream
    m_conn = peer.call 'zentrum', m_stream
    console.log "media", m_stream
    m_conn.on 'open', ()->  console.log "sending audio"
    m_conn.on 'close', ()-> console.log "audio closed"
    m_conn.on 'error', (err)-> console.error err.message

setInterval ()->
  data_reconnect() unless d_conn?.open
  media_reconnect() unless m_conn?.open
  my_col = "grey" unless d_conn?.open and m_conn?.open
  draw()
, 15000
