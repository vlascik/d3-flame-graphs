# function that converts from a particular data format into the generic one
# expected by the plugin
window.debugging = true

runnableVals = []
convert = (rawData, valueFunc) ->

  # timeElapsed = new Date()
  # timeElapsed.setSeconds(value)
  # timeFormat = countdown.DAYS | countdown.HOURS | countdown.MINUTES | countdown.SECONDS
  node =
    name: rawData.n,
    value: valueFunc(rawData),
    # time: countdown(new Date(), timeElapsed, timeFormat)
    children: []

  # the a field is the list of children
  return node if not rawData.a
  for child in rawData.a
    subTree = convert(child, valueFunc)
    if subTree
      node.children.push(subTree)
  node

d3.json "data/profile.json", (err, data) ->
  allStates = (node) ->
    value = 0
    for state in ['RUNNABLE', 'BLOCKED', 'TIMED_WAITING', 'WAITING']
      value += node.c[state] if not isNaN(node.c[state])
    value


  profile = convert(data.profile, allStates)
  tooltip = (d) -> "#{d.name} <br /><br />
    #{d.value} samples<br />
    #{((d.value / profile.value) * 100).toFixed(2)}% of total"
  flameGraph = d3.flameGraph('#d3-flame-graph', profile)
    .size([1200, 600])
    .cellHeight(20)
    .zoomEnabled(true)
    .tooltip(tooltip)
    .render()

  d3.select('#highlight')
    .on 'click', () ->
      nodes = flameGraph.select((d) -> /java\.util.*/.test(d.name))
      nodes.classed("highlight", (d, i) -> not d3.select(@).classed("highlight"))

  d3.select('#zoom')
    .on 'click', () ->
      # jump to the first java.util.concurrent method we can find
      node = flameGraph.select(((d) -> /CountDownLatch\.await$/.test(d.name)), false)[0]
      flameGraph.zoom(node)

  unhide = false
  d3.select('#hide')
    .on 'click', () ->
      flameGraph.hide ((d) -> /Unsafe\.park$/.test(d.name) or /Object\.wait$/.test(d.name)), unhide
      unhide = !unhide

  d3.select('#runnable')
    .on 'click', () ->
      profile = convert(data.profile, ((node) -> if node.c['RUNNABLE'] then node.c['RUNNABLE'] else 0))
      flameGraph = d3.flameGraph('#d3-flame-graph', profile)
        .size([1200, 600])
        .cellHeight(20)
        .zoomEnabled(true)
        .tooltip(tooltip)
        .render()