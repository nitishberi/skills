extends SceneTree
## Headless: instantiate Phase A classes after autoloads boot.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var art: Node = root.get_node_or_null("Art")
	if art == null:
		push_error("Art autoload missing")
		quit(1)
		return
	var nodes: Array = [
		Shellbug.new(), Needler.new(), NeedlerEgg.new(), IronSnout.new(),
		PipeShot.new(), Swimfin.new(), Inkjet.new(), EmberBlob.new(),
		TossTwin.new(), TossHammer.new()
	]
	for n in nodes:
		if n == null:
			ok = false
		else:
			(n as Node).free()
	for key in [
		"cliffbug", "ashbug", "ashbug_shell", "needler", "needler_egg",
		"cannon", "pipe_shot", "swimfin", "inkjet", "ember_blob", "toss_twin", "hammer"
	]:
		if art.call("texture", key) == null:
			push_error("Missing art: %s" % key)
			ok = false
	var Catalog = load("res://scripts/level_catalog.gd")
	for w in range(1, 9):
		for s in range(1, 5):
			var k: String = Catalog.stage_kind(w, s)
			if k.is_empty():
				ok = false
	if ok:
		print("PHASE_A_SMOKE_OK")
		quit(0)
	else:
		print("PHASE_A_SMOKE_FAIL")
		quit(1)
