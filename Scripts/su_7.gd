extends VehicleBody3D

@export_group("Motor e freio")
@export var max_engine_force : float = 50000.0  # por roda de tração (2 rodas traseiras)
@export var max_speed_kmh : float = 5000.0       # a força só cai de verdade perto dessa velocidade
@export var throttle_speed : float = 30.0        # quão rápido o acelerador "sobe" (0 -> 1 em ~0,3 s)
@export var max_brake_force : float = 50.0      # para massa 1800, 45-55 é freada forte
@export var reverse_force_multiplier : float = 0.1 # Força da ré (0.6 = 60% da força do motor)
@export var max_reverse_speed_kmh : float = 2500.0   # Velocidade máxima da ré

@export_group("Direção")
@export var max_steering_angle : float = 0.55   # ângulo máximo parado (rad)
@export var wheelbase : float = 5.5             # distância entre eixos (rodas em z = 2.935 e -2.541)
@export var max_lateral_accel : float = 30.0    # m/s² que a direção pode pedir dos pneus (~1 g)
@export var steering_speed : float = 10.0        # velocidade de resposta do volante (rad/s)

@export_group("Estabilidade")
@export var downforce : float = 2.0             # força para baixo = velocidade² * downforce
@export var surface_index_luz_freio: int = 3    # Superfície 3 é a luz de freio

@onready var aceleracao: AudioStreamPlayer3D = $Aceleracao
@onready var aceleracao_loop: AudioStreamPlayer3D = $AceleracaoLoop
@onready var frenagem: AudioStreamPlayer3D = $Frenagem
@onready var mesh_luz_freio: MeshInstance3D = $CollisionShape3D/Carroceria

var throttle : float = 0.0
var material_freio: Material

func _ready() -> void:
	aceleracao_loop.play()
	if mesh_luz_freio:
		material_freio = mesh_luz_freio.get_active_material(surface_index_luz_freio) 
		if material_freio:
			material_freio = material_freio.duplicate()
			mesh_luz_freio.set_surface_override_material(surface_index_luz_freio, material_freio)
			if material_freio is StandardMaterial3D:
				material_freio.emission_energy_multiplier = 0.0

func _physics_process(delta: float) -> void:
	var speed_ms := linear_velocity.length()
	var speed_kmh := speed_ms * 3.6
	var forward_speed := -global_transform.basis.z.dot(linear_velocity)

	# 1. Aceleração, ré e freio
	var speed_ratio : float = clamp(speed_kmh / max_speed_kmh, 0.0, 1.0)
	var power_curve : float = 1.0 - speed_ratio * speed_ratio

	var throttle_target := 1.0 if Input.is_action_pressed("ui_up") else 0.0
	throttle = move_toward(throttle, throttle_target, throttle_speed * delta)

	if Input.is_action_pressed("ui_up"):
		engine_force = max_engine_force * throttle * power_curve
		brake = 0.0
	elif Input.is_action_pressed("ui_down"):
		# Se estiver andando para frente, freia. O limite de 0.5 m/s (1.8 km/h) garante que ele pare.
		if forward_speed > 0.5:
			engine_force = 0.0
			brake = max_brake_force
		else:
			# Se já estiver quase parado, engata a ré.
			brake = 0.0
			# Curva de potência para a ré (fica mais fraca conforme a velocidade de ré sobe)
			var reverse_speed_ratio = clamp(abs(forward_speed) * 3.6 / max_reverse_speed_kmh, 0.0, 1.0)
			var reverse_power_curve = 1.0 - reverse_speed_ratio * reverse_speed_ratio
			engine_force = -max_engine_force * reverse_force_multiplier * reverse_power_curve
	else:
		engine_force = 0.0
		brake = 0.0

	if Input.is_action_pressed("ui_select"):
		brake = max_brake_force * 2.0

	# 2. Direção limitada pela física
	var grip_limit_angle := atan(wheelbase * max_lateral_accel / max(speed_ms * speed_ms, 1.0))
	var dynamic_max_angle : float = min(max_steering_angle, grip_limit_angle)

	var steering_input := Input.get_axis("ui_right", "ui_left")
	var steering_target := steering_input * dynamic_max_angle
	steering = move_toward(steering, steering_target, steering_speed * delta)

	# 3. Downforce
	apply_central_force(-global_transform.basis.y * speed_ms * speed_ms * downforce)

	# --- SISTEMA DE ÁUDIO ---
	_atualizar_audio(speed_kmh, forward_speed, delta)
	# --- Atualiza as luzes de freio ---
	_atualizar_luzes_freio(forward_speed)

func _atualizar_audio(speed_kmh: float, forward_speed: float, delta: float) -> void:
	if Input.is_action_just_pressed("ui_up"):
		aceleracao.play()

	var target_pitch : float = 0.8
	if throttle > 0.1:
		target_pitch = 1.0 + (speed_kmh / max_speed_kmh) * 1.2
	else:
		target_pitch = 0.7 + (speed_kmh / max_speed_kmh) * 0.6

	aceleracao_loop.pitch_scale = lerp(aceleracao_loop.pitch_scale, target_pitch, 5.0 * delta)

	var target_volume_db : float = linear_to_db(0.4 + (throttle * 0.6))
	aceleracao_loop.volume_db = lerp(aceleracao_loop.volume_db, target_volume_db, 5.0 * delta)

	# 3. Som de Frenagem (Só toca se estiver freando de verdade, não dando ré)
	var freio_ativo = Input.is_action_pressed("ui_select") or (Input.is_action_pressed("ui_down") and forward_speed > 0.5)
	if freio_ativo:
		if not frenagem.playing:
			frenagem.play()
	else:
		if frenagem.playing:
			frenagem.stop()

func _atualizar_luzes_freio(forward_speed: float) -> void:
	if not material_freio:
		return
		
	# Só acende a luz se estiver freando de verdade
	var freio_ativo = Input.is_action_pressed("ui_select") or (Input.is_action_pressed("ui_down") and forward_speed > 0.5)
	
	if material_freio is StandardMaterial3D:
		if freio_ativo:
			material_freio.emission_energy_multiplier = 20.0 
		else:
			material_freio.emission_energy_multiplier = 0.0
