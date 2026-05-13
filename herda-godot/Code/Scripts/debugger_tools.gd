extends Node

class_name Debug_tools
static var frequentie = 600
static var moet_printen : bool

func _process(delta: float) -> void:
	moet_printen = fmod(Engine.get_frames_drawn(), frequentie)


#static func insert_header(header : String) -> void:
	#var framecount = Engine.get_frames_drawn()
	#if (fmod(framecount, frequentie) == 0):
		#var boodschap : String = variabel_naam + str(variabel_waarde)
		#print(boodschap)

static func print_variabele(variabel_naam : String, variabel_waarde) -> void:
	var framecount = Engine.get_frames_drawn()
	if (fmod(framecount, frequentie) == 0):
		var boodschap : String = variabel_naam + str(variabel_waarde)
		print(boodschap)

static func print_object_variabele(object, variabel_naam : String, variabel_waarde) -> void:
	var framecount = Engine.get_frames_drawn()
	if (fmod(framecount, frequentie) == 0):
		var object_string = " [" + str(object) + "]"
		var boodschap : String = variabel_naam + str(variabel_waarde) + object_string
		print(boodschap)
