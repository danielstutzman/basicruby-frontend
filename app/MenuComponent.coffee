MenuComponent = React.createClass

  displayName: 'MenuComponent'

  render: ->
    { table, tr, td } = React.DOM

    table { border: 1 },
      _.map @props.topics, (topic) ->
        tr { key: topic.num },
          td {},
            topic.num
          td {},
            topic.title

module.exports = MenuComponent
