object @dlmlock

extends 'api/v2/dlmlocks/base'

attributes :created_at, :updated_at

child(:host) { attributes :name }
