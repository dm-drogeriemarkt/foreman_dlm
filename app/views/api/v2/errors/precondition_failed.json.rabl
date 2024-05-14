# frozen_string_literal: true

object controller.get_resource

attributes :id

node(:message) { locals[:message] || 'Precondition failed.' }
