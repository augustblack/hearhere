# just use one of these
a_ctx = new (window.AudioContext || window.webkitAudioContext)()

create_element = (name, attrs)->
  el = document.createElement name
  for k,v of attrs
    el.setAttribute k,v
  return el

class ClientComponent
  constructor: ( @peer)->
    @ui = create_element "div",class:"ui"
    @status_el = create_element "div", class:"status"
    @status_el.textContent = "connecting..."
    @alive =
      now: Date.now()
      arrived : Date.now()
    @ui.appendChild @status_el
    document.body.appendChild @ui

  log: ( msg )->
    return console.log @peer, arguments[0] if arguments.length is 0
    return console.log @peer, arguments

  error: (msg)->
    console.error msg

  create_volume_el : ()->
    opts=
      type: "range"
      min:0
      max:1.5
      step:0.1
    return create_element "input", opts

  fade_out: (dur)->
    return this unless @gain?.gain?.linearRampToValueAtTime?
    now = a_ctx.currentTime
    @gain.gain.cancelScheduledValues now
    @gain.gain.setValueAtTime @gain.gain.value, now
    @gain.gain.linearRampToValueAtTime 0.0, now + dur
    return this

  trigger_adsr: (dur)->
    return this unless @gain?.gain?.linearRampToValueAtTime?
    now = a_ctx.currentTime
    that=this
    @set_vol(1.0)
    @gain.gain.cancelScheduledValues now
    @gain.gain.setValueAtTime @gain.gain.value, now
    @gain.gain.linearRampToValueAtTime 1.2, now + (0.05*dur)
    @gain.gain.linearRampToValueAtTime 1.0, now + (0.1*dur)
    @gain.gain.linearRampToValueAtTime 1.0, now + (0.75*dur)
    @gain.gain.exponentialRampToValueAtTime(0.0001, now + dur)
    @gain.gain.linearRampToValueAtTime 0.0, now + dur+0.1
    setTimeout( ->
      that.set_vol( 0.0)
    , dur*1000)
    return this

  set_vol : (val)->
    @vol_el.value = parseFloat val if @vol_el?
    return this

  set_gain : (val)->
    @gain.gain.value = val if @gain?.gain?
    @set_vol val
    return this

  destroy_it : ()->
    @m_conn.close() if @m_conn?.open
    @d_conn.close() if @d_conn?.open
    document.body.removeChild @ui
    return

  on_data_open: ()-> @log "data connect"
  on_data_close: ()-> @log "data disconnect"
  on_data_error: (err)-> @error err.message
  on_data_data: (data)->
    if data?.now?
      @alive.arrived = Date.now()
      @alive.now = data.now
    lag = (@alive.arrived - data.now)/1000
    @status_el.textContent =  "lag:#{lag}s"
    return

  on_media_open: ()-> @log "audio connect"
  on_media_close: ()-> @log "audio disconnect"
  on_media_error: (err)-> @error err.message
  on_media_stream: (a_stream)->
    # connecting the stream's audio this way doesn't work in Chrome. See:
    # http://stackoverflow.com/questions/24287054/chrome-wont-play-webaudio-getusermedia-via-webrtc-peer-js
    # https://code.google.com/p/chromium/issues/detail?can=2&q=121673&colspec=ID%20Pri%20M%20Iteration%20ReleaseBlock%20Cr%20Status%20Owner%20Summary%20OS%20Modified&id=121673
    @src = a_ctx.createMediaStreamSource a_stream
    @gain = a_ctx.createGain()
    @src.connect(@gain)
    @gain.connect(a_ctx.destination)
    
    @vol_el = @create_volume_el()
    @vol_el.addEventListener "input", @on_input_change.bind this
    @ui.insertBefore(@vol_el, @ui.firstChild)
    @set_gain 0.0
    return


  on_input_change: (evt)->
    @gain.gain.value = parseFloat(evt.target.value) if evt.target?.value and @gain


  add_data_conn: (d_conn)->
    @d_conn.close() if @d_conn
    @d_conn = d_conn
    ###
    console.log("connection label: ", d_conn.label)
    console.log("connection peer: ", d_conn.peer)
    console.log("connection metadata: ", d_conn.metadata)
    console.log("connection open: ", d_conn.open)
    console.log("connection reliable: ", d_conn.reliable)
    console.log("connection serialization: ", d_conn.serialization)
    console.log("connection buffersize: ", d_conn.bufferSize)
    ###
   
  add_media_conn: (m_conn)->
    @m_conn.close() if @m_conn
    @m_conn = m_conn
    console.log("media type: ", m_conn.type)
    console.log("media peer: ", m_conn.peer)
    console.log("media metadata: ", m_conn.metadata)
    console.log("media open: ", m_conn.open)

module.exports = ClientComponent


