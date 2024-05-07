# frozen_string_literal: true

object @dlmlock

extends 'api/v2/dlmlocks/main'

child :host do
  node(:name, &:name)
  node(:self) { |host| host == @detected_host } if @detected_host
end
