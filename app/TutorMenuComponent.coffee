_     = require 'underscore'
React = require 'react'

type  = React.PropTypes

TutorMenuComponent = React.createClass

  displayName: 'TutorMenuComponent'

  propTypes:
    groups: type.array.isRequired

  render: ->
    { a, b, br, div, h1, h2, i, li, p, span, ul } = React.DOM

    group1 = _.find @props.groups, (group) ->
      group.id == 1
    group2 = _.find @props.groups, (group) ->
      group.id == 2
    groups3Plus = _.filter @props.groups, (group) ->
      group.id >= 3
    html = (s) ->
      React.DOM.span { dangerouslySetInnerHTML: { __html: s } }
    backticksToCode = (s) ->
      html s.replace(/`(.*?)`/g, "<code>$1</code>")
    truncate = (s, len) ->
      if s.length > len then s.substring(0, len) + '...' else s

    div { style: { fontFamily: 'sans-serif', width: '600px', margin: '0 auto' } },
      h1 {}, 'Online Ruby Tutor'
      p {},
        i, 'A free educational tool to visualize execution traces ',
           'of user-supplied Ruby programs'

      h2 {}, '1. Trace some examples'
      ul {},
        _.map group1.exercises, (exercise) ->
          li { key: exercise.task_id },
            a { href: "/tutor/exercise/#{exercise.task_id}" },
              exercise.description

      h2 {}, '2. Trace your own program'
      ul {},
        li {},
          a { href: '/tutor/exercise/D000' },
            'Write your own'

      h2 {}, '3. Learn to program by solving puzzles'
      p {},
        i {},
          'D means a demonstration: '
          'click through the cases to make sure you understand.'
          br {}
          'C means a challenge: '
          'you need to fix the code to make the tests pass.'
      ul {}
        _.map groups3Plus, (group) ->
          li { key: group.id },
            b {},
              backticksToCode group.name
            ul {},
              _.map group.exercises, (exercise) ->
               li { key: exercise.task_id },
                  a { href: "/tutor/exercise/#{exercise.task_id}" },
                    exercise.task_id
                    backticksToCode truncate(exercise.description, 60)

module.exports = TutorMenuComponent
