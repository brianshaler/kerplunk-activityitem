_ = require 'lodash'
React = require 'react'

{DOM} = React

module.exports = React.createFactory React.createClass
  render: ->
    Component = @props.getComponent @props.globals.public.streamItem
    DOM.section
      className: 'content'
    ,
      Component _.extend {}, @props,
        itemId: @props.item._id
      DOM.h3 null, "Score: #{Math.round @props.item.attributes?.score ? 0}"
      _.map @props.item.fullAttributes, (attrs, name) ->
        DOM.div
          key: "attr-#{name}"
        ,
          DOM.h3 null, name
          _.map attrs, (attr, index) ->
            DOM.p
              key: "attr-#{name}-#{index}"
            ,
              attr.text
              ': '
              Math.round attr.attributes?.score ? 0

      DOM.pre null,
        JSON.stringify @props.item, null, 2
