extends Node
class_name AbstractExternalEventBus

signal event_received(event_type: String, payload)

var _event_handlers := {} 

func _ready():
	pass

func send_event(event_type: String, payload):
	_dispatch_local_event(event_type, payload)

func on_event(event_type: String, handler: Callable):
	if not _event_handlers.has(event_type):
		_event_handlers[event_type] = []
	_event_handlers[event_type].append(handler)

func _dispatch_local_event(event_type: String, payload):
	emit_signal("event_received", event_type, payload)
	if _event_handlers.has(event_type):
		for handler in _event_handlers[event_type]:
			handler.call(payload)
