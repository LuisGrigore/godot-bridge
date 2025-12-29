extends AbstractExternalEventBus
class_name ExternalWebEventBus

var _js_to_godot_callback_ref

func _ready():
	super._ready()
	if OS.has_feature("web"):
		_register_js_bridge()

# =====================================================
# ========== REGISTRO DEL PUENTE JS ⇄ GODOT ===========
# =====================================================
func _register_js_bridge():
	var window = JavaScriptBridge.get_interface("window")

	_js_to_godot_callback_ref = JavaScriptBridge.create_callback(_handle_event_from_js)
	window.sendEventToGodot = _js_to_godot_callback_ref

	JavaScriptBridge.eval("""
		window.sendEventToJS = window.sendEventToJS || function(event) {
			console.warn("sendEventToJS no registrado", event);
		};
	""", true)
# =====================================================
# =============== API PÚBLICA GODOT ===================
# =====================================================
func send_event(event_type: String, payload):
	super.send_event(event_type,payload)
	_dispatch_event_to_js(event_type, payload)


func _dispatch_event_to_js(event_type: String, payload):
	var window = JavaScriptBridge.get_interface("window")
	var event = {
		"type": event_type,
		"payload": payload
	}
	window.sendEventToJS(JSON.stringify(event))


# =====================================================
# ========== CALLBACK DE EVENTOS DESDE JS ==============
# =====================================================
func _handle_event_from_js(args):
	if args.is_empty():
		push_warning("Received empty handle js event call.")
		return
	
	var raw_event = args[0]
	var event: Dictionary

	if typeof(raw_event) == TYPE_STRING:
		var parse_result = JSON.parse_string(raw_event)
		event = parse_result
	elif typeof(raw_event) == TYPE_DICTIONARY:
		event = raw_event
	else:
		push_warning("Invalid event type, expected String (JSON) or Dictionary, got: %s" % str(typeof(raw_event)))
		return

	# Validaciones
	if not event.has("type"):
		push_warning("Event missing \"type\" property.")
		return
	if not event.has("payload"):
		push_warning("Event missing \"payload\" property.")
		return

	var event_type = event["type"]
	var payload = event["payload"]

	if typeof(event_type) != TYPE_STRING:
		push_warning("The \"type\" property is not a String: %s" % str(event_type))
		return

	super._dispatch_local_event(event_type, payload)
