_     = require 'underscore'
React = require 'react'

UNCHECKED_BOX = '\u2610'
CHECKED_BOX   = '\u2611'

MenuComponent = React.createClass

  displayName: 'MenuComponent'

  humanize: (s) ->
    s.replace(/_/g, ' ').replace /(\w+)/g, (match) ->
      match.charAt(0).toUpperCase() + match.slice(1)

  thForColor: (color, line1, line2) ->
    { br, th, div } = React.DOM
    th
      className: color
      div { className: 'exercise-icon' }
      br {}
      line1
      br {}
      line2

  doneIndicator: (topic, color) ->
    { a, div, span } = React.DOM
    completed = topic.completed[color]
    a { className: 'done-indicator', href: '#' + completed.next },
      if color == 'purple'
        if completed.num > 0
          CHECKED_BOX
        else
          UNCHECKED_BOX
      else
        if completed.num > 0
          [UNCHECKED_BOX,
            div({ key: 1, className: 'num-completions' }, completed.num)]
        else
          UNCHECKED_BOX

  render: ->
    { br, div, h1, h2, span, table, tbody, td, th, tr } = React.DOM

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
              div { className: 'under-construction-icon' }
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
                div { className: 'under-construction-icon' }
              span { dangerouslySetInnerHTML: { __html: topic.title_html } }

            _.map ['purple', 'yellow', 'blue', 'red', 'green'], (color) =>
              td { className: color, key: color },
                if topic.completed[color]
                  @doneIndicator topic, color

        _.map ['purple', 'yellow', 'blue', 'red', 'green'], (color) =>
          td { className: color }

    div { className: 'MenuComponent' },
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
