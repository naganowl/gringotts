define (require) ->
  Chaplin = require 'chaplin'
  utils = require 'lib/utils'
  activeSyncMachine = require 'mixins/active-sync-machine'
  stringTemplate = require 'mixins/string-template'
  PaginatedCollection = require 'models/base/paginated-collection'
  PaginatedView = require 'views/base/paginated-view'
  View = require 'views/base/view'

  class MockItemView extends View
    tagName: 'tr'
    className: 'test-item col-md-4'
    getTemplateFunction: -> -> '<td><td><td>'

  class MockPaginatedCollection extends PaginatedCollection
    _.extend @prototype, activeSyncMachine

    urlRoot: '/test'
    DEFAULTS: _.extend {}, PaginatedCollection::DEFAULTS,
      per_page: 10

    initialize: ->
      super
      @activateSyncMachine()

  class MockPaginatedView extends PaginatedView
    _.extend @prototype, stringTemplate

    itemView: MockItemView
    listSelector: 'tbody'
    template: 'paginated-table-test'
    templatePath: 'test/templates'

  class MockInfinitePaginatedView extends PaginatedView
    _.extend @prototype, stringTemplate

    itemView: MockItemView
    listSelector: 'tbody'
    template: 'paginated-table-test'
    templatePath: 'test/templates'
    infinitePagination: true

  describe 'Paginated View', ->
    collection = null
    view = null
    server = null
    viewConfig = {}

    beforeEach ->
      sinon.stub utils, 'reverse'
      server = sinon.fakeServer.create()
      collection = new MockPaginatedCollection ({} for i in [0..101])
      collection.count = 101
      view = new MockPaginatedView _.extend {},
        {collection: collection, routeName: 'test'}, viewConfig
      collection.setState {}
      collection.trigger 'sync', collection

    afterEach ->
      server.restore()
      utils.reverse.restore()
      collection.dispose()
      view.dispose()

    it 'should instantiate', ->
      expect(view).to.be.an.instanceOf PaginatedView

    it 'should render the pagination controls', ->
      expect(view.$('.pagination-controls').length).to.equal 1

    it 'should render the previous page link correctly', ->
      expect(utils.reverse).to.have.been.calledWith 'test', null, {}

    it 'should render the next page link correctly', ->
      expect(utils.reverse).to.have.been.calledWith 'test', null, {page: 2}

    context 'pageInfo', ->
      I18n = null
      expecting = null

      beforeEach ->
        I18n = t: (address, context) ->
          i18ns = items:
            infinite: "#{context.min}-#{context.max}"
            total: "#{context.min}-#{context.max} of #{context.count}"
          _.result i18ns, address

        expecting =
          viewId: view.cid
          count: 101
          page: 1
          perPage: 10
          pages: Math.ceil(101 / 10)
          prev: false
          next: 2
          range: '1-10 of 101'
          routeName: 'test'
          routeParams: undefined
          multiPaged: true
          nextState:
            page: 2
          prevState: {}

      afterEach ->
        expecting = null
        I18n = null

      context 'with normal pagination', ->
        it 'should correctly returns _getPageInfo', ->
          expect(view._getPageInfo()).to.eql expecting

        it 'should show the correct string', ->
          expecting = '1-10 of 101'
          expect(view.$('.pagination-controls strong').text()).to.eql expecting

      context 'with infinite pagination', ->
        beforeEach ->
          collection.count = 10
          expecting.count = 10
          expecting.range = '1-10'
          expecting.pages = 2
          view.infinitePagination = true
          view.renderControls()

        afterEach ->
          expecting.pages = 11
          collection.count = 101
          expecting.count = 101
          expecting.range = '1-10 of 101'
          view.infinitePagination = false

        it 'should correctly return _getPageInfo', ->
          expect(view._getPageInfo()).to.eql expecting

        it 'should show the correct string', ->
          expecting = '1-10'
          expect(view.$('.pagination-controls strong').text()).to.eql expecting

      context 'without I18n', ->
        oldI18n = null
        beforeEach ->
          oldI18n = I18n
          I18n = null
        afterEach ->
          I18n = oldI18n
          oldI18n = null

        context 'with normal pagination', ->
          it 'should correctly return page info', ->
            expect(view._getPageInfo()).to.eql expecting

        context 'with infinite pagination', ->
          beforeEach ->
            view.infinitePagination = true
            collection.count = 10
            expecting.pages = 2
            expecting.count = 10
            expecting.range = '1-10'
          afterEach ->
            view.infinitePagination = false
            expecting.pages = 11
            expecting.range = '1-10 of 101'
            expecting.count = 101
            collection.count = 101
          it 'should correctly return _getPageInfo', ->
            expect(view._getPageInfo()).to.eql expecting

    it 'should set the convenience className', ->
      expect(view.className).to.equal 'paginated-table-test'

    context 'loading indicator start syncing', ->
      beforeEach ->
        collection.beginSync()

      it 'should show loading', ->
        expect(view.$loading).to.have.css 'display', 'table-row'

      it 'should hide all items', ->
        expect(view.$('.test-item.col-md-4')).to.have.css 'display', 'none'

      context 'and then finished', ->
        beforeEach ->
          collection.finishSync()

        it 'should hide loading', ->
          expect(view.$loading).to.have.css 'display', 'none'

        it 'should hide all items', ->
          expect(view.$('.test-item.col-md-4')).to
            .have.css 'display', 'table-row'

    context 'moving forward two pages', ->
      beforeEach ->
        collection.setState {page: 3}
        collection.trigger 'sync', collection

      it 'should update the collection', ->
        expecting =
          viewId: view.cid
          count: 101
          page: 3
          perPage: 10
          pages: Math.ceil(101 / 10)
          prev: 2
          next: 4
          range: '21-30 of 101'
          routeName: 'test'
          multiPaged: true
          routeParams: undefined
          nextState:
            page: 4
          prevState:
            page: 2

        expect(view._getPageInfo()).to.eql expecting
