###
# ActivityItem schema
###

module.exports = (mongoose) ->
  Schema = mongoose.Schema
  ObjectId = Schema.ObjectId

  ActivityItemSchema = new Schema
    guid:
      type: String
      index:
        unique: true
      required: true
    identity:
      type: ObjectId
      index: true
      ref: 'Identity'
    message:
      type: String
      default: ''
    messageFull:
      type: String
      default: ''
    media: [{}]
    location:
      type: [Number]
      index: '2dsphere'
    postedAt:
      type: Date
      default: Date.now
      index: true
    platform:
      type: String
      default: 'unknown'
    platformId:
      type: String
      default: ''
    read:
      type: Boolean
      default: false
    liked:
      type: Boolean
      default: false
    disliked:
      type: Boolean
      default: false
    ratings: {}
    attributes: {}
    data: {}
    activity: [
      type: ObjectId
      ref: 'ActivityItem'
    ]
    activityOf:
      type: ObjectId
      ref: 'ActivityItem'
    createdAt:
      type: Date
      default: Date.now
      index: true
    updatedAt:
      type: Date
      default: Date.now
      index: true
  ,
    toObject:
      virtuals: true
    toJSON:
      virtuals: true

  ActivityItemSchema
    .virtual 'fullAttributes'
    .get ->
      @_fullAttributes = {} unless @_fullAttributes
      @_fullAttributes

  ActivityItemSchema.methods.unshortenUrls = (cb) ->
    cb()

  ActivityItemSchema.statics.getOrCreate = (data, next) ->
    Identity = mongoose.model 'Identity'
    ActivityItem = mongoose.model 'ActivityItem'

    q = {}
    if data.item.guid?
      q.guid = data.item.guid
    else if data.item.platform and data.item.platformId
      q.platform = data.item.platform
      q.platformId = data.item.platformId
    else
      err = new Error 'invalid item search'
      return next err

    err = null
    userData = data.identity.data

    # delete data.identity.data
    where = {}
    for k, v of data.identity
      if k != 'data'
        where[k] = v

    Identity.getOrCreate where, (err, identity) ->
      return next err if err
      identity.data = {} unless identity.data
      for k, v of userData
        identity.data[k] = v
      identity.markModified 'data'
      ActivityItem.findOne q, (err, item) ->
        return next err if err
        if item
          item.identity = identity._id
          item.save (err) ->
            next null, item, identity
        else
          data.item.attributes = {} unless data.item.attributes
          data.item.attributes.rated = false unless data.item.attributes.rated
          item = new ActivityItem data.item
          item.identity = identity
          next null, item, identity

  ActivityItemSchema.pre 'save', (next) ->
    @updatedAt = new Date()
    @markModified 'attributes'
    next()

  mongoose.model 'ActivityItem', ActivityItemSchema
