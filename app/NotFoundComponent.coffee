React = require 'react'

NotFoundComponent = React.createClass

  displayName: 'NotFoundComponent'

  propTypes: {}

  render: ->
    { div } = React.DOM
    div {}, 'Route not found'

module.exports = NotFoundComponent
