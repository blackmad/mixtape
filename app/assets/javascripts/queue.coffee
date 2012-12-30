class window.Queue
  this.id = (id) ->
      "enqueued-" + id

  constructor: (@main) ->
    @$queue = $("#queue")
    @$queue.sortable({update: (e, ui) =>
      this.moveItem(ui.item.data("id"), ui.item.next().data("id"))
    });
    @$queue.disableSelection();


  addTrack: (id, name, artist, album, albumKey, art) =>
    @main.send({
      event: "add",
      id: id,
      name: name,
      artist: artist,
      album: album,
      albumKey: albumKey,
      icon: art
    })

  moveItem: (id, putBefore) => @main.send({event: "move", id: id, putBefore: putBefore})

  voteUp: (id) => @main.send({event: "voteup", id: id})
  voteDown: (id) => @main.send({event: "votedown", id: id})

  reload: () => jsRoutes.controllers.Application.queue(@main.room).ajax({success: (o) => this.render(o)})
  render: (r) => @$queue.empty().append(r.queue.map(this.renderItem))

  findOrReload: (id, f) =>
    $r = $("#" + Queue.id(id))
    if $r then f($r) else this.reload()

  itemAdded: (item) => @$queue.append(this.renderItem(item))
  itemUpdated: (item) => this.findOrReload(item.id, ($r) => this.fillItem(item, $r.empty()))
  itemMoved: (id, nowBefore) => this.findOrReload(id, ($r) =>
    if nowBefore then $r.insertBefore($("#" + Queue.id(nowBefore))) else @$queue.append($r)
  )

  itemSkipped: (id) => this.findOrReload(id, ($r) => $r.remove())

  renderItem: (res) =>
    this.fillItem(res, $("<div>").addClass("enqueued").attr("id", Queue.id(res.id)).data("id", res.id))

  fillItem: (res, $r) =>
    $r.append $("<img>").addClass("icon").attr("src", res.track.icon).click (e) =>
      e.stopPropagation()
      @main.showAlbum(res.track.albumKey)

    $r.append $("<span>").addClass("name").text(res.track.name)
    $from = $("<div>").addClass("details")
    $r.append $from

    $from.append $("<a>").addClass("trackartist").text(res.track.artist).click (e) =>
      e.stopPropagation()
      @main.showArtist(res.track.artistKey)
    $from.append $("<a>").addClass("trackalbum").text(res.track.album).click (e) =>
      e.stopPropagation()
      @main.showAlbum(res.track.albumKey)
    $r.append $("<div>").addClass("clearfix")
    $r

class window.Player