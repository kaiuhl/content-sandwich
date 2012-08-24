# A state machine that manages the transition between blocks of content.
#
# - expects `data-state` and `data-state-group` attributes on each state elem.
# - automatically manages transitions through `data-state-transition`.
#
# Depends upon jquery & underscore (things you should already be using)
#
# Usage:
# sm = ContentSandwich("my-state-group")
#
# URL looks like
# => http://something.com/#group/state//group/state

window.ContentSandwich = (group) ->
  ContentSandwich.instances[group] ||= new ContentSandwich.StateMachine(group)

ContentSandwich.instances = {}
ContentSandwich.state = {}

# initialize all groups after the page loads
$ ->
  groups = $("[data-state-group]").map (i, el) -> $(el).attr('data-state-group')
  _.chain(groups).uniq().each (group) -> ContentSandwich(group)

class ContentSandwich.StateMachine
  constructor: (@group) ->
    @functions = {}
    @global_listeners()
    @init()

  init: ->
    # get array of possible states
    @states = _.map $("[data-state-group='#{@group}']"), (state) ->
      $(state).attr("data-state")

    # add listeners for each state
    _.each @states, (state) =>
      @listeners state

    # try to deserialize, otherwise transition to the default state
    @deserialize()
    @transition(@states[0]) if @states[0] and not @currentState

  # keep all binding up to date
  global_listeners: ->
    $(document).on "ajax:complete ajaxComplete", => @init()

  # transition states on click
  listeners: (stateName) ->
    $(document).on "click", "[data-state-transition='#{stateName}']", (e) =>
      e.preventDefault()
      @transition($(e.currentTarget).attr("data-state-transition"))
      $(document).trigger("transition:#{stateName}")

  # hide inactive states, show active state
  transition: (stateName) ->
    console.log "Transitioning to #{stateName}"
    throw "Undefined state `#{stateName}`" unless stateName in @states
    if @functions[stateName]?() isnt false
      $("[data-state-group='#{@group}'][data-state='#{stateName}']").show()
      $("[data-state-group='#{@group}'][data-state!='#{stateName}']").hide()
      _.each @states, (state) ->
        $("[data-state-transition='#{state}']").toggleClass('active_tab', state is stateName)
      @currentState = stateName
      $(document).trigger("transition:#{@group}")
    else # cancelled transition
      $(document).trigger("transition:cancel:#{@group}")
      @functions[@currentState]?()
    @serialize()

  # accepts function that's called on transition
  on: (stateName, func) ->
    @functions[stateName] = func

  off: (stateName) -> @functions[stateName] = null

  # url update
  serialize: ->
    ContentSandwich.state[@group] = @currentState if @currentState
    if history.replaceState
      state = _.map(ContentSandwich.state, (state, group) -> "#{group}/#{state}").join('//')
      history.replaceState?({}, document.title, "#{location.pathname}##{state}")

  deserialize: ->
    if location.hash isnt ''
      states = location.hash.split('#')[1].split('//')
      _.each states, (pair) =>
        [group, state] = pair.split('/')
        @transition(state) if group is @group

