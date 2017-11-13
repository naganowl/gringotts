Chaplin = require 'chaplin'
specHelper = require 'lib/spec-helper'
ModalView = require 'views/base/modal-view'
NotificationsView = require 'views/notifications-view'

class MockModal extends ModalView
  template: require './modal.spec.hbs'

describe 'ModalView', ->
  sandbox = null
  view = null
  transition = null

  beforeEach ->
    sandbox = sinon.sandbox.create()
    specHelper.stubModal sandbox, -> {transition}
    MockModal::autoAttach = no
    view = new MockModal()

  afterEach ->
    view.dispose()
    MockModal::autoAttach = yes
    sandbox.restore()

  context 'after modal is attached', ->
    shownSpy = null

    beforeEach ->
      view.on 'shown', shownSpy = sinon.spy()
      view.attach()

    it 'should add scroll classes', ->
      expect($ 'body').to.have.class 'no-scroll'

    it 'should have modal class set', ->
      expect(view.$el).to.have.attr 'class', 'modal fade in'

    it 'should trigger shown event', ->
      expect(shownSpy).to.have.been.calledOnce

    context 'and then hiding modal', ->
      hiddenSpy = null

      beforeEach ->
        view.on 'hidden', hiddenSpy = sinon.spy()
        view.hide()

      it 'should remove scroll classes', ->
        expect($ 'body').not.to.have.class 'no-scroll'

      it 'should trigger hidden event', ->
        expect(hiddenSpy).to.have.been.calledOnce

      context 'notifying errors with modal hidden', ->
        notifications = null

        beforeEach ->
          sinon.spy view, 'publishEvent'
          view.notifyError('error message')
          notifications = view.subview('notifications')

        afterEach ->
          view.publishEvent.restore()

        it 'should not set notifications subview', ->
          expect(notifications).not.to.exist

        it 'should add notification through publishing notify event', ->
          expect(view.publishEvent).to.been
            .calledWith 'notify', 'error message',
              classes: 'alert-danger'
              navigateDismiss: yes

      context 'and then show again', ->
        beforeEach ->
          view.show()

        it 'should trigger shown event', ->
          expect(shownSpy).to.have.been.calledTwice

        context 'notifying errors', ->
          notifications = null

          beforeEach ->
            view.notifyError('error message')
            notifications = view.subview('notifications')

          it 'should set notifications subview', ->
            expect(notifications).to.be.instanceOf NotificationsView

          it 'should add error message to notifications', ->
            expect(notifications.collection).to.have.length 1

          it 'should have correct message', ->
            message = notifications.collection.models[0].get 'message'
            expect(message).to.eql 'error message'

    context 'on disposing', ->
      beforeEach ->
        transition = true
        view.dispose()

      afterEach ->
        transition = null

      it 'should hide modal after disposed', ->
        expect($.fn.modal).to.have.been.calledWith 'hide'

      it 'should not be disposed before modal is hidden', ->
        expect(view.disposed).to.be.false

      context 'and modal was hidden', ->
        beforeEach ->
          view.$el.trigger 'hidden.bs.modal'

        it 'should dispose modal view', ->
          expect(view.disposed).to.be.true

  context 'on disposing', ->
    beforeEach ->
      view.dispose()

    it 'should be disposed', ->
      expect(view.disposed).to.be.true
