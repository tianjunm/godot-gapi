extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass





func _on_Chest_area_shape_entered(area_id, area, area_shape, self_shape):
	$ColorRect.color = Color(0.5, 0.25, 0.25, 1)



func _on_Chest_area_shape_exited(area_id, area, area_shape, self_shape):
	$ColorRect.color = Color(1, 1, 1, 1)
