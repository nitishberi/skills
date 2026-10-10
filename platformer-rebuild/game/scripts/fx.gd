class_name Fx
extends RefCounted

static func coin_pop(parent: Node, pos: Vector2) -> void:
	var s := Art.make_sprite("coin", true)
	s.global_position = pos
	parent.add_child(s)
	var tw := parent.create_tween()
	tw.set_parallel(true)
	tw.tween_property(s, "global_position:y", pos.y - 28, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "modulate:a", 0.0, 0.25).set_delay(0.08)
	tw.chain().tween_callback(s.queue_free)

static func brick_shards(parent: Node, pos: Vector2) -> void:
	for i in 4:
		var p := Art.make_sprite("brick", true)
		p.scale = Vector2(0.35, 0.35)
		p.global_position = pos + Vector2(8, 8)
		parent.add_child(p)
		var tw := parent.create_tween()
		var dir := Vector2(randf_range(-1, 1), randf_range(-1.2, -0.2)).normalized()
		tw.tween_property(p, "global_position", p.global_position + dir * randf_range(18, 36), 0.35)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.35)
		tw.tween_callback(p.queue_free)

static func stomp_dust(parent: Node, pos: Vector2) -> void:
	for i in 2:
		var d := ColorRect.new()
		d.size = Vector2(6, 4)
		d.color = Color(0.9, 0.85, 0.7, 0.8)
		d.position = pos + Vector2(-8 + i * 10, -4)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(d)
		var tw := parent.create_tween()
		tw.tween_property(d, "position:x", d.position.x + (-6 if i == 0 else 6), 0.2)
		tw.parallel().tween_property(d, "modulate:a", 0.0, 0.2)
		tw.tween_callback(d.queue_free)
