extends Node3D

@export_group("Configurações da Câmera")
@export var carro: VehicleBody3D # Arraste o nó SU7 para cá no Inspetor
@export var max_yaw : float = 0.15    # Quanto a câmera vira para o lado (em radianos)
@export var max_roll : float = 0.05   # Quanto a câmera inclina (em radianos)
@export var velocidade_suavizacao : float = 4.0 # Quão rápido ela se move

@export_group("Efeito de Velocidade (FOV)")
@export var camera: Camera3D
@export var fov_base : float = 75.0
@export var fov_max : float = 95.0
@export var max_speed_kmh : float = 300.0

func _ready() -> void:
	if not carro:
		carro = get_parent() # Se não arrastar, tenta pegar o pai (SU7)
	if not camera:
		camera = get_node("Camera3D") # Tenta achar a câmera filha

func _process(delta: float) -> void:
	if not carro:
		return

	# 1. Efeito de Curva (Yaw e Roll)
	# Normaliza o steering (-1 a 1) baseado no ângulo máximo do carro
	var steer_ratio = carro.steering / carro.max_steering_angle
	
	# Se estiver virando para a esquerda (positivo), a câmera gira para a esquerda (positivo Y)
	# e inclina levemente para o lado oposto (Roll)
	var target_yaw = steer_ratio * max_yaw
	var target_roll = -steer_ratio * max_roll

	rotation.y = lerp(rotation.y, target_yaw, velocidade_suavizacao * delta)
	rotation.z = lerp(rotation.z, target_roll, velocidade_suavizacao * delta)

	# 2. Efeito de Velocidade (FOV dinâmico) - Dá sensação de velocidade
	if camera:
		var speed_kmh = carro.linear_velocity.length() * 3.6
		var speed_ratio = clamp(speed_kmh / max_speed_kmh, 0.0, 1.0)
		var target_fov = lerp(fov_base, fov_max, speed_ratio)
		camera.fov = lerp(camera.fov, target_fov, velocidade_suavizacao * delta)
