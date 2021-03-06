class Main
  constructor: (@room, rdioToken) ->
    @connected = false
    @$content = $("#content")
    @queue = new Queue(this)
    @player = new Player this, $("#player"), rdioToken, () =>
      this.reconnect () => @player.setLocalPlayback(true)
    @chat = new Chat(this)

    new Search(this, $("#searchterm"), $("#searchresults"))
    window.setTimeout this.checkConnection, 1500

  reloadState: (f) =>
    jsRoutes.controllers.Application.queue(@room).ajax({success: (o) =>
      @queue.render(o.queue)
      @player.setPlaying(o.playing)
      f() if f
    })

  showArtist: (r) => jsRoutes.controllers.Rdio.artist(r).ajax({success: (o) => new Artist(this, o).show()})
  showAlbum: (a) => jsRoutes.controllers.Rdio.album(a).ajax({success: (o) => new Album(this, o).show()})

  openSocket: (f) =>
    console.log("opening socket")
    sock = new WebSocket(jsRoutes.controllers.Application.controls(@room).webSocketURL())
    sock.onmessage = this.handleMsg
    sock.onclose = () =>
      @connected = false
      console.error "Socket Closed!"
      window.setTimeout (() => this.reconnect()), 15000
    sock.onopen = () =>
      @connected = true
      f() if f
    sock

  reconnect: (f) =>
    @sock = this.openSocket () =>
      @player.notifyServerListening()
      @player.notifyServerBroadcasting()
      this.reloadState(f)

  checkConnection: =>
    this.reconnect() unless @connected


  handleMsg: (msg) =>
    o = JSON.parse msg.data
    console.debug "recv: ", o unless o.event == "progress"
    switch o.event
      when "added" then               @queue.itemAdded(o.item)
      when "updated" then             @queue.itemUpdated(o.item)
      when "skipped"  then            @queue.itemSkipped(o.id)
      when "playing-song-skipped" then @player.skip(o.id)
      when "moved"  then              @queue.itemMoved(o.id, o.nowBefore)
      when "started" then             @player.start(o.item)
      when "progress" then            @player.updatePosition(o.pos, o.ts)
      when "finished" then            @player.setPlaying(false)
      when "start-broadcasting" then  @player.setSendEvents(true)
      when "stop-broadcasting" then   @player.setSendEvents(false)
      when "leavejoin" then           @chat.guestlistChanged(o.users, o.listeners, o.lurkers)
      when "chat" then                @chat.message(o.msg, o.who)
      when "reload" then              this.reloadState()
      else
        console.warn "unknown event: " + o.event, o

  send: (msg) =>
    console.debug "send: ", msg unless msg.event == "progress"
    @sock.send JSON.stringify msg

jQuery ->
  window.mixtape = new Main(ROOM, RDIOTOKEN)