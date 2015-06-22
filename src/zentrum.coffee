Client = require './client.coffee'

gum =require 'getusermedia'

peer = new Peer 'zentrum',
  key: '2rm8if3cntz3q5mi'
  iceServers: [
    url: 'stun:stun.l.google.com:19302'
  ]

display_err = (msg)-> console.error msg

g={}

peer.on 'open', (id)-> console.log('My peer ID is: ' + id)
peer.on 'close', ()-> console.log('My peer closed')
peer.on 'disconnected', ()->
  console.log('My peer disconnected')
  setTimeout ()->
    peer.reconnect()
  , 700

peer.on 'error', (err)->
  switch err.type
    when 'browser-incompatible' then display_err "browser does not support some or all WebRTC features"
    when 'disconnected' then display_err  "peer already disconnected from the server and can no longer make any new connections on it."
    when 'invalid-id' then display_err  "invalid ID, bad characters"
    when 'invalid-key' then display_err "Peer api key problem"
    when 'network' then display_err "Lost or cannot establish a connection to the signalling server."
    when 'peer-unavailable' then display_err "peer does not exist"
    when 'ssl-unavailable' then display_err "PeerJS is being used securely, but the cloud server does not support SSL"
    when 'server-error' then display_err "Unable to reach the server."
    when 'socket-error' then display_err "An error from the underlying socket."
    when 'socket-closed' then display_err "The underlying socket closed unexpectedly."
    when 'unavailable-id' then display_err "The ID passed into the Peer constructor is already taken."
    when 'webrtc' then display_err err.messsage
    else display_err "unknown error"
   
peer.on 'connection', (conn)->
  g[conn.peer] = new Client conn.peer unless g[conn.peer]?
  c =g[conn.peer]
  c.add_data_conn conn
  conn.on 'open', c.on_data_open.bind c
  conn.on 'close', c.on_data_close.bind c
  conn.on 'error', c.on_data_error.bind c
  conn.on 'data', c.on_data_data.bind c

peer.on 'call', (conn)->
  g[conn.peer] = new Client conn.peer unless g[conn.peer]?
  c = g[conn.peer]
  c.add_media_conn conn
  conn.answer() # media_stream
  conn.on 'open',c.on_media_open.bind c
  # Firefox doesn't yet support the onclose event.
  conn.on 'close', c.on_media_close.bind c
  conn.on 'error', c.on_media_error.bind c
  conn.on 'stream', c.on_media_stream.bind c


t=0
setInterval( ()->
  now = Date.now()
  for k,a of g
    if a.alive?.arrived < now - 12*1000
      a.fade_out( 0.1 )
      setTimeout( ->
        a.destroy_it()
        delete g[k]
        console.log "removed #{k}", g
      , 200)
  len = Math.max Object.keys(g).length,2
  idx=t%len
  all={}
  i=0
  for k,a of g
    if i++ is idx
      all[k] =
        audio: "on"
        m_conn: if a?.m_conn? then a.m_conn.open else false
      a.trigger_adsr( 2.5)
    else
      all[k] =
        audio: "off"
        m_conn: if a?.m_conn? then a.m_conn.open else false
      #a.set_gain 0.0
  for k,a of g
    a.d_conn.send all
  t++
, 2000)


