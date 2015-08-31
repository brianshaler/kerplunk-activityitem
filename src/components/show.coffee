_ = require 'lodash'
React = require 'react'

{
  a
  div
  em
  h3
  p
  pre
  section
} = React.DOM

module.exports = React.createFactory React.createClass
  render: ->
    Component = @props.getComponent @props.globals.public.streamItem
    section
      className: 'content'
    ,
      Component _.extend {}, @props,
        itemId: @props.item._id
      h3 null, "Score: #{Math.round @props.item.attributes?.score ? 0}"
      _.map @props.item.fullAttributes, (attrs, name) ->
        div
          key: "attr-#{name}"
        ,
          h3 null, name
          _.map attrs, (attr, index) ->
            p
              key: "attr-#{name}-#{index}"
            ,
              attr.text
              ': '
              Math.round attr.attributes?.score ? 0

      pre null,
        JSON.stringify @props.item, null, 2
