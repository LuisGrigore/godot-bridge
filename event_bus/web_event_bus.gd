extends Node
class_name WebEventBus

signal event_received(event_type: String, payload)

var _event_handlers := {} # String -> Array[Callable]
var _js_to_godot_callback_ref

func _ready():
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
func send_event_to_js(event_type: String, payload):
	_dispatch_local_event(event_type, payload)
	_dispatch_event_to_js(event_type, payload)

func on_event(event_type: String, handler: Callable):
	if not _event_handlers.has(event_type):
		_event_handlers[event_type] = []
	_event_handlers[event_type].append(handler)

# =====================================================
# =============== INTERNO GODOT =======================
# =====================================================
func _dispatch_local_event(event_type: String, payload):
	emit_signal("event_received", event_type, payload)
	if _event_handlers.has(event_type):
		for handler in _event_handlers[event_type]:
			handler.call(payload)

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
		push_warning("Recieved empty handle js event call.")
		return
		
	var event = args[0]
	
	if typeof(event) != TYPE_OBJECT:
		push_warning("%s: Invalid event type, event should be: { type: String, payload: any }" % str(event))
		return
		
	if !event.hasOwnProperty("type"):
		push_warning("Event missing \"type\" property.")
		return
		
	if !event.hasOwnProperty("payload"):
		push_warning("Event missing \"payload\" property")
		return
		
	var event_type = event["type"]
	var payload = event["payload"]
	
	if typeof(event_type) != TYPE_STRING:
		push_warning("The \"type\" property in not a String: %s" % str(event_type))
		return
		
	_dispatch_local_event(event_type, payload)
