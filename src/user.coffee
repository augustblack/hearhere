gum =require 'getusermedia'
a_ctx = new (
  window.AudioContext ||
  window.webkitAudioContext ||
  window.mozAudioContext ||
  window.oAudioContext ||
  window.msAudioContext
)

log = (msg)->
  console.log msg
  status_el.innerHTML += "#{msg}</br>" if status_el?
log_error = (msg)->
  console.log msg
  alert msg
  status_el.innerHTML += "<div class=\"error\">#{msg}</div>" if status_el?


create_element = (name, attrs)->
  el = document.createElement name
  for k,v of attrs
    el.setAttribute k,v
  return el

delete_client = (k,v)->
  document.body.removeChild v.el
  delete other_clients[k]

me ={}
me.el = document.getElementById('me')
status_el = document.getElementById('status')

set_transform = (el, transform)->
  el.style.webkitTransform = transform
  el.style.MozTransform = transform
  el.style.msTransform = transform
  el.style.OTransform = transform
  el.style.transform = transform

set_class = (el, audio)->
  return el.style.backgroundColor = "red" if audio is "off"
  return el.style.backgroundColor = "green" if audio is "on"
  return el.style.backgroundColor = "orange" if audio is "ready"
  return el.style.backgroundColor = "grey"

center =
  x:0
  y:0

window.onresize = on_window_resize = (e)->
  w = window.innerWidth
  h = window.innerHeight
  center=
    x: w / 2
    y: h / 2
  me.radius = Math.min w/5, h/5
  scale= me.radius/100
  transform = "translate(#{center.x}px, #{center.y}px) scale(#{scale}) "
  set_transform me.el, transform
  draw()

create_el = (k,v)->
  el =document.createElement "div"
  el.id = k
  el.className = "circle"
  set_class el, "trouble"
  document.body.appendChild el
  return el


other_clients ={}

draw = ()->
  len = Object.keys(other_clients).length
  inc = 360 / len
  i=0
  set_class me.el, me.audio
  for k,v of other_clients
    theta = inc*i++
    v.el = create_el(k,v) unless v.el?
    scale= me.radius/100 *0.4
    transform =  "translate(#{center.x}px, #{center.y}px)  rotate(#{theta}deg)  translateX(#{me.radius}px) scale(#{scale})"
    set_transform v.el, transform
    set_class v.el, v.audio
    

peer = new Peer '',
  key: '2rm8if3cntz3q5mi'
  iceServers: [
    url: 'stun:stun.l.google.com:19302'
  ]


peer_reconnect = ()->
  log "peer disconnected.."
  setTimeout ()->
    log "reconnecting to peer.."
    peer.reconnect()
  , 1000



d_conn=null
m_conn=null
m_stream=null
peer_id = null


peer.on 'open', (id)->
  peer_id =id
  log "connected as #{peer_id}"
  data_connect()
  gum {video:false,audio:true}, (err, media_stream)->
    return log_error err.message if err
    if a_ctx?.createMediaStreamSource?
      log "setting up dynamic range compression"
      stream_src = a_ctx.createMediaStreamSource(media_stream)

      compressor = a_ctx.createDynamicsCompressor()
      compressor.threshold.value = -50
      compressor.knee.value = 40
      compressor.ratio.value = 12
      compressor.reduction.value = -20
      compressor.attack.value = 0
      compressor.release.value = 0.25

      dest = a_ctx.createMediaStreamDestination()

      stream_src.connect compressor
      compressor.connect dest

      media_stream.addTrack(dest.stream.getAudioTracks()[0])
      media_stream.removeTrack(media_stream.getAudioTracks()[0])

      m_stream = dest.stream

    else
      log "no dynamic range compression"
      m_stream = media_stream

    media_connect()

peer.on 'close', ()-> peer_reconnect()
peer.on 'disconnected', ()-> peer_reconnect()
peer.on 'connection', (conn)-> log "got a data connection"

data_reconnect = ()->
  d_conn.close() if d_conn?
  d_conn=null
  setTimeout ()->
    data_connect()
  , 1000

data_connect = ()->
  d_conn  = peer.connect 'zentrum'
  d_conn.on 'error', (err)-> log_error err.message
  d_conn.on 'close', ()-> me.el.backgroundColor="grey"; draw(); log "closed data"
  d_conn.on 'open', ()-> draw()
  d_conn.on 'data', (data)->
    d_conn.send now: Date.now()
    for k,v of other_clients
     delete_client k,v unless data[k]
    for k,v of data
      if k is peer_id
        me.audio = v.audio
        me.m_conn = v.m_conn || m_conn?.open
      else
        other_clients[k] = {} unless other_clients[k]?
        other_clients[k].el = create_el(k,v) unless other_clients[k]?.el
        other_clients[k].audio = v.audio
        other_clients[k].m_conn = v.m_conn
    draw()


media_reconnect = ()->
  m_conn.close() if m_conn?
  m_conn = null
  setTimeout ()->
    media_connect()
  , 1000

media_connect = ()->
  log "doing media connect"
  if m_stream
    m_conn = peer.call 'zentrum', m_stream
    log "media", m_stream
    m_conn.on 'open', ()->  log "sending audio"
    m_conn.on 'close', ()-> log "audio closed"
    m_conn.on 'error', (err)-> log_error err.message

setInterval ()->
  data_reconnect() unless d_conn?.open
  media_reconnect() unless m_conn?.open
  me.el.backgroundColor = "grey" unless d_conn?.open and m_conn?.open
  draw()
, 15000



on_window_resize()
