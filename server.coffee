express = require('express')
http = require('http')
path = require('path')
fs = require('fs')

app = express()
srv = http.createServer app
#http = http.Server(app)
io = require('socket.io')(srv)



app.use(express.static(process.cwd() + '/public'))
###
app.get '/', (req, res)->
  res.sendFile "#{__dirname}/public/index.html"
app.get '/js/bundle.js', (req,res)->
  res.sendFile "#{__dirname}/public/js/bundle.js"
app.get '/js/master.js', (req,res)->
  res.sendFile "#{__dirname}/public/js/master.js"

###

app.get '/master', (req, res)->
  res.sendFile "#{__dirname}/public/master.html"


master = io.of('/master')
clients = io.of('/clients')


nureine=null
master.on 'connection', (m)->
  console.log "got master"
  if nureine?
    m.emit "eskannnureinegeben", "eskannnureinegeben"
    m.disconnect()
  nureine =m


  m.on 'disconnect', ()->
    clients.emit "master disconnect", "master is disconnected"
    nureine =null

  m.on 'error',  (err)->
    console.error err.msg
    clients.emit "master error", "wavefarm central is having difficulties"

  m.on 'offer', (offer)->
    console.log "got newpeer offer", offer.peer_id
    clients.to(offer.peer_id).emit('offer', offer)

  m.on 'pulse', (payload)->
    clients.emit('pulse', payload)

  m.on 'ice', (candidate)->
    console.log "master got ice"
    clients.emit 'ice', candidate

clients.on 'connection', (c)->
  console.log 'new user connected', c.id
  master.emit "newpeer", c.id

  c.on 'error',  (err)->
    console.error err.msg


  c.on 'disconnect', ()->
    console.log "disconnect", c.id
    master.emit "disconnect peer", c.id

  c.on 'answer', (answer)->
    console.log "got answer from client", c.id
    answer.peer_id = c.id
    master.emit "answer", answer

  c.on 'ice', (candidate)->
    console.log "client got ice"
    candidate.peer_id = c.id
    master.emit "ice" , candidate


srv.listen 3000, ()-> console.log('listening on *:3000')
