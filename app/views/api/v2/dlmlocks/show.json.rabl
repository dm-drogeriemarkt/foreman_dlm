object @dlmlock

extends 'api/v2/dlmlocks/main'

child :host do
  node(:name) { |host| host.name }
  node(:self) { |host| host == @detected_host } if @detected_host
end
