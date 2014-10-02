_     = require 'underscore'
React = require 'react'

type  = React.PropTypes

TutorExerciseComponent = React.createClass

  displayName: 'TutorExerciseComponent'

  propTypes:
    task_id:       type.string.isRequired
    description:   type.string.isRequired
    starting_code: type.string

  render: ->
    { a, b, button, div, h1, h2, textarea } = React.DOM

    html = (s) ->
      React.DOM.span { dangerouslySetInnerHTML: { __html: s } }
    backticksToCode = (s) ->
      html s.replace(/`(.*?)`/g, "<code>$1</code>")

    div {},

      div { id: 'sidebar' },
        a { id: 'edit-tab-link', href: '#' },
          div { id: 'edit-tab', className: 'tab' },
            h2 {}, 'Edit'
            if @props.starting_code
              button { id: 'restore-button', name: 'action', value: 'restore' },
                'Restore original'
            button { id: 'save-button', name: 'action', value: 'save' },
              'Save'

        div { className: 'filler' }
        div { className: 'traces-tabs' },
          div { className: 'tab case-tab', data: { caseNum: 0 } },
            h2 {}, 'Case 0'
        div { className: 'filler filler-tall' }

      div { id: 'edit-content' },
        if @props.task_id
          b {}, "Exercise #{@props.task_id}"
        backticksToCode @props.description

        div { id: 'user_code_div' },
          textarea
            id: 'user_code_textarea'
            name: 'user_code_textarea'
            cols: '40'
            rows: '10'
            value: @props.starting_code
            readOnly: true

      div { className: 'case-contents' }

      div { className: 'footer' },
        'Online Ruby Tutor is (C) 2013 '
        a { href: 'http://www.danielstutzman.com/' }, 'Daniel Stutzman'
        '. '
        a { href: 'https://github.com/danielstutzman/online-ruby-tutor/issues' },
          'File a bug '
        'or '
        a { href: 'https://github.com/danielstutzman/online-ruby-tutor' },
          'submit a pull request. '
        'Visualizations drawn by '
        a { href: 'http://pythontutor.com/' }, 'Online Python Tutor '
        'by '
        a { href: 'http://www.pgbovine.net/' }, 'Philip Guo'

module.exports = TutorExerciseComponent
