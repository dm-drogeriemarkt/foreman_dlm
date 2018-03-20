object resource = controller.get_resource

attributes :id

node(:message) { locals[:message] || 'Precondition failed.' }
