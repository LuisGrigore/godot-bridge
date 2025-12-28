class_name ExternalEventBusFactory

enum BusType { WEB }

func create_bus(type:BusType) -> AbstractExternalEventBus:
	var external_event_bus: AbstractExternalEventBus
	match type:
		BusType.WEB:
			external_event_bus = ExternalWebEventBus.new()
	if external_event_bus == null:
		push_error("No se pudo instanciar ExternalEventBus para el tipo: %s" % str(type))
		return null
	external_event_bus.name = "ExternalEventBus"
	return external_event_bus
