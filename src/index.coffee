_ = require 'lodash'
Promise = require 'when'

ActivityItemSchema = require './models/ActivityItem'

module.exports = (System) ->
  mongoose = System.api.getMongoose 'public'
  ActivityItem = ActivityItemSchema mongoose

  saveModel = (item) ->
    deferred = Promise.defer()
    item.save (err) ->
      return deferred.reject err if err
      deferred.resolve item
    deferred.promise

  models = {}
  postInit = ->
    toPopulate = System.api.getGlobal 'public.activityItem.populate'
    return unless toPopulate
    for k, v of toPopulate
      models[k] = mongoose.model v
    # console.log 'models', Object.keys models

  populateModel = (item) ->
    Promise.all _.map models, (Model, property) ->
      deferred = Promise.defer()
      unless item.attributes?[property]
        return {
          property: property
          items: []
        }
      ids = item.attributes[property] ? []
      Model
      .where
        _id:
          '$in': ids
      .find (err, items) ->
        return deferred.reject err if err
        deferred.resolve
          property: property
          items: items
      deferred.promise
    .then (arr) ->
      # console.log 'make sure item.fullAttributes exists', item.fullAttributes
      item.fullAttributes = {} unless item.fullAttributes?
      for field in arr
        # console.log 'adding', field.property, 'item.fullAttributes', item.fullAttributes
        item.fullAttributes[field.property] = field.items
    .then -> item

  routes:
    admin:
      '/admin/item/:id/show': 'show'
      '/admin/item/:id/save': 'resave'
      '/admin/item/byguid/:guid': 'showGuid'
      '/admin/item/test': 'test'
      '/admin/item/test2': 'test2'
      '/admin/item/output': 'output'

  handlers:
    show: (req, res, next) ->
      ActivityItem
      .where
        _id: req.params.id
      .populate 'identity'
      .findOne (err, item) ->
        return next err if err
        return next() unless item
        System.api.do 'activityItem.populate', item
        .then ->
          if item.toObject
            item = item.toObject()
          delete item.data
          res.render 'show',
            item: item
    resave: (req, res, next) ->
      ActivityItem
      .where
        _id: req.params.id
      .populate 'identity'
      .findOne (err, item) ->
        return next err if err
        return next() unless item
        System.api.do 'activityItem.save', item
        .then ->
          if item.toObject
            item = item.toObject()
          delete item.data
          delete item.identity.data
          return res.redirect "/admin/item/#{item._id}/show"
          res.render 'show',
            item: item
    showGuid: (req, res, next) ->
      ActivityItem
      .where
        guid: req.params.guid
      .populate 'identity'
      .findOne (err, item) ->
        return next err if err
        return next() unless item
        System.api.do 'activityItem.populate', item
        .then ->
          if item.toObject
            item = item.toObject()
          delete item.data
          delete item.identity.data
          res.render 'show',
            item: item
    test: (req, res, next) ->
      ActivityItem
      .where
        guid: 'test'
      .remove (err) ->
        return next err if err
        item = new ActivityItem
          guid: 'test'
          attributes:
            characteristic: [
              '55a74b26b4beb9871934c3a0'
              '55a74b7a8c465f221af1f130'
            ]
        console.log 'new item', item
        item.save (err) ->
          return next err if err
          System.api.do 'activityItem.populate', item
          .then ->
            res.send item
          .catch (err) ->
            next err
    test2: (req, res, next) ->
      ActivityItem
      .where
        guid: 'test'
      .findOne (err, item) ->
        return next err if err
        System.api.do 'activityItem.populate', item
        .done ->
          res.send item
        , (err) ->
          next err
    output: (req, res, next) ->
      ActivityItem
      .where
        platform: req.query.platform
      .limit req.query.limit
      .find (err, items) ->
        return next err if err
        res.send data: _.pluck items, 'data'

  globals:
    public:
      activityItem:
        populate: {}
    events:
      init:
        post: postInit
      activityItem:
        save:
          do: saveModel
        populate:
          do: populateModel
