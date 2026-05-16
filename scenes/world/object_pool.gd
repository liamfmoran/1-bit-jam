extends Node
class_name ObjectPool

var _scene: PackedScene
var _free_list: Array[Node] = []

func init(scene: PackedScene) -> void:
	_scene = scene

func acquire() -> Node:
	if _free_list.size() > 0:
		var node: Node = _free_list.pop_back()
		remove_child(node)
		return node
	return _scene.instantiate()

func release(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node.get_parent():
		node.get_parent().remove_child(node)
	node.visible = false
	add_child(node)
	_free_list.push_back(node)
