_     = require 'underscore'
React = require 'react'

UNCHECKED_BOX = '\u2610'
CHECKED_BOX   = '\u2611'

MenuComponent = React.createClass

  displayName: 'MenuComponent'

  imageTag: (path, atts) ->
    React.DOM.img _.extend(atts, { src: "/images/#{path}" })

  humanize: (s) ->
    s.replace(/_/g, ' ').replace /(\w+)/g, (match) ->
      match.charAt(0).toUpperCase() + match.slice(1)

  imageTagForExerciseColor: (color, size) ->
    switch color
      when 'purple'
        @imageTag 'exercise_icons/play-button-purple-60.png',
          width: size, height: size
      when 'yellow'
        @imageTag 'exercise_icons/light_bulb_60.png',
          width: size, height: size
      when 'red'
        @imageTag 'exercise_icons/red_bug_60.png',
          width: size, height: size
      when 'blue'
        @imageTag 'exercise_icons/question_mark_60.png',
          width: size, height: size
      when 'green'
        @imageTag 'exercise_icons/pen-and-paper-60.png',
          width: size, height: size
      when 'orange'
        @imageTag 'exercise_icons/jack-o-lantern-60.png',
          width: size, height: size

  thForColor: (color, line1, line2) ->
    { br, th } = React.DOM
    th
      className: color
      @imageTagForExerciseColor color, 60
      br {}
      line1
      br {}
      line2

  doneIndicator: (topic, color) ->
    { a, div } = React.DOM
    completed = topic.completed[color]
    a { className: 'done-indicator', href: completed.next },
      if color == 'purple'
        if completed.num > 0
          CHECKED_BOX
        else
          UNCHECKED_BOX
      else
        if completed.num > 0
          [UNCHECKED_BOX, div { className: 'num-completions' }, completed.num]
        else
           UNCHECKED_BOX

  render: ->
    { br, div, h1, h2, table, tbody, td, th, tr } = React.DOM

    trs = []
    trs.push tr { key: 'first' },
      th
        className: 'title'
        style: { verticalAlign: 'bottom' }
        h2 {}, 'Beginner'
      @thForColor 'purple', 'Watch',     'intro'
      @thForColor 'yellow', 'Run an',    'example'
      @thForColor 'blue',   'Predict',   'output'
      @thForColor 'red',    'Fix the',   'bugs'
      @thForColor 'green',  'Implement', 'the spec'

    _.each ['beginner', 'intermediate'], (level) =>
      if level != 'beginner' # because we'll show it left of the icons
        trs.push tr { key: level },
          th { className: 'title' },
            br { key: 1 }
            br { key: 2 }
            if level == 'intermediate'
              @imageTag 'under_construction.png', style: { float: 'right' },
                title: 'Under construction'
            h2 { key: 3 }, @humanize(level)
            td { className: 'purple', key: 'purple' }
            td { className: 'yellow', key: 'yellow' }
            td { className: 'blue'  , key: 'blue' }
            td { className: 'red'   , key: 'red' }
            td { className: 'green' , key: 'green' }
      _.each @props.topics, (topic) =>
        if topic.level == level
          trs.push tr { key: "#{topic.level}-#{topic.num}" },
            th
              className: 'title'
              if topic.under_construction
                @imageTag 'under_construction.png', style: { float: 'left' },
                  title: 'Under construction'
              span { dangerouslySetInnerHTML: { __html: topic.title_html } }

            _.map ['purple', 'yellow', 'blue', 'red', 'green'], (color) =>
              td { className: color, key: color },
                if topic.completed[color]
                  @doneIndicator topic, color

            if topic.under_construction
              @imageTag 'under_construction.png', style: { float: 'left' },
                title: 'Under construction'

        _.map ['purple', 'yellow', 'blue', 'red', 'green'], (color) =>
          td { className: color }

    div {},
      h1 { className: 'basic-ruby' }, 'Basic Ruby'
      div { className: 'learn-programming' },
        'daily workouts until programming is easy'
      br { style: { clear: 'both' } }
      br {}
      br {}
      br {}
      br {}
      table { style: { borderSpacing: 0, margin: '0 auto' } },
        tbody {},
          trs

module.exports = MenuComponent
