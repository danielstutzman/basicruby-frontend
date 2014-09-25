_     = require 'underscore'
React = require 'react'

type  = React.PropTypes

TutorExerciseComponent = React.createClass

  displayName: 'TutorExerciseComponent'

  propTypes:
    exercise: type.object.isRequired
    user_code: type.string.isRequired

  render: ->
    { h1 } = React.DOM

    h1 {}, 'Online Ruby Tutor'

module.exports = TutorExerciseComponent
