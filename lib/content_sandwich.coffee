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
    @events = "click"
    @global_listeners()
    @init()

  init: ->
    # get array of possible states
    @states = $("[data-state][data-state-group='#{@group}']").map (i, state) -> $(state).attr("data-state")

    # add listeners for each state
    @iterative_listeners()
    _.each @states, (state) => @state_listeners state

    # default transitions
    @transition_in = ($elem) -> $elem.show()
    @transition_out = ($elem) -> $elem.hide()

    # try to deserialize, otherwise transition to the default state
    @deserialize()
    @transition(@states[0]) if @states[0] and not @current_state

  # keep all binding up to date
  global_listeners: ->
    $(document).on "ajax:complete ajaxComplete", => @init()

  # next & previous listeners
  iterative_listeners: ->
    # next listeners
    jQuery(document).on @events, "[data-state-transition-next='#{@group}']", (e) =>
      index = _.indexOf(@states, @current_state)
      length = @states.length
      e.preventDefault()
      if index isnt (length - 1)
        @transition(@states[index + 1])
      else
        @transition(@states[0])

    # previous listeners
    jQuery(document).on @events, "[data-state-transition-previous='#{@group}']", (e) =>
      index = _.indexOf(@states, @current_state)
      length = @states.length
      e.preventDefault()
      if index isnt 0
        @transition(@states[index - 1])
      else
        @transition(@states[length - 1])
  # transition states on click
  state_listeners: (stateName) ->
    # turn off existing listeners
    $(document).off "click", "[data-state-group='#{@group}'][data-state-transition='#{stateName}']"

    # apply
    $(document).on "click", "[data-state-group='#{@group}'][data-state-transition='#{stateName}']", (e) =>
      e.preventDefault()
      @transition($(e.currentTarget).attr("data-state-transition"))
      $(document).trigger("transition:#{stateName}")

  # hide inactive states, show active state
  transition: (stateName) ->
    throw "Undefined state `#{stateName}`" unless stateName in @states

    #if the state exits, transition to it
    if @functions[stateName]?() isnt false and stateName isnt @current_state
      @transition_in $("[data-state-group='#{@group}'][data-state='#{stateName}']")
      @transition_out $("[data-state-group='#{@group}'][data-state][data-state!='#{stateName}']")
      _.each @states, (state) ->
        $("[data-state-transition='#{state}']").toggleClass('active_tab', state is stateName)
      @current_state = stateName
      $(document).trigger("transition:#{@group}")
    else # cancelled transition
      $(document).trigger("transition:cancel:#{@group}")
      @functions[@current_state]?()
    @serialize()

  # accepts function that's called on transition
  on: (stateName, func) -> @functions[stateName] = func
  off: (stateName) -> @functions[stateName] = null

  # url update
  serialize: ->
    ContentSandwich.state[@group] = @current_state if @current_state
    if history.replaceState
      state = _.map(ContentSandwich.state, (state, group) -> "#{group}/#{state}").join('//')
      history.replaceState?({}, document.title, "#{location.pathname}##{state}")

  deserialize: ->
    if location.hash isnt ''
      states = location.hash.split('#')[1].split('//')
      _.each states, (pair) =>
        [group, state] = pair.split('/')
        @transition(state) if group is @group


