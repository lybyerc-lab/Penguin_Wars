extends BossActor
## Test-only boss. It proves the director's boss-phase contract without this
## branch owning any boss content: no attacks, no telegraphs, no art. It
## records what the director did to it so the seam can be asserted.

var configured_party_size: int = -1
var configure_calls: int = 0
## Health as it stood when configure() returned, before the director's scaling.
var health_after_configure: float = 0.0

func configure(definition: BossDefinition, party_size: int) -> void:
	super.configure(definition, party_size)
	configure_calls += 1
	configured_party_size = party_size
	health_after_configure = get_node("Health").maximum
	# A real boss sets its own body here; the stub only proves it can.
	hit_radius = 40.0
	contact_radius = 58.0
	knockback_multiplier = 0.1
