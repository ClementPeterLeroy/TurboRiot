class_name CompetitorState
extends RefCounted
## One independent race model and sweep/recovery cursor per physical kart.
var id := 0
var display_name := "Player"
var is_player := false
var kart: KartController
var session := RaceSession.new()
var grid := Transform3D.IDENTITY
var previous_position := Vector3.ZERO
var interval_travel := 0.0
var projection_hint := -1
var offset := 0.0
var segment_progress := 0.0
var finish_order := 0
var finish_timestamp := 0.0
var crossing_fraction := 1.0
var dnf := false
var recoveries := 0

func progress_units(gate_count: int) -> float:
	return session.lap_times.size() * gate_count + session.next_checkpoint - 1 + segment_progress
