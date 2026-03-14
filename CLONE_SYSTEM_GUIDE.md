# Clone/Replay System Documentation

## Overview

The clone/replay system allows players to record their actions and play them back as clones. This system has been refactored for modularity, maintainability, and ease of modification.

---

## Architecture

### Component Overview

```
┌─────────────────────┐
│  CassetteUIController│  ← UI Layer (user input, visual feedback)
└──────────┬──────────┘
           │ (method calls)
           ↓
┌─────────────────────┐
│   CloneManager      │  ← Orchestration Layer (state, lifecycle)
└──────────┬──────────┘
           │ (references)
           ↓
┌─────────────────────┐
│  RecordingSystem    │  ← Data Layer (record/playback)
└──────────┬──────────┘
           │ (owns)
           ↓
┌─────────────────────┐
│      Replay         │  ← Storage (individual recordings)
└─────────────────────┘

┌─────────────────────┐
│  CloneAnimator      │  ← Animation Layer (visual playback)
└─────────────────────┘
```

### Components

#### 1. **CloneState** (`scripts/clone_state.gd`)
- Defines the state machine for the clone system
- States: `IDLE`, `WAITING_INPUT`, `RECORDING`, `PLAYING`
- Validates state transitions

#### 2. **CloneConfig** (`scripts/clone_config.gd`)
- Configuration resource (create in Godot as .tres file)
- Properties:
  - `max_clones` - Number of clone slots (default: 4)
  - `time_limit` - Recording/playback duration (default: 10.0s)
  - `clone_scene_path` - Path to clone scene template

#### 3. **RecordingSystem** (`scripts/recording_system.gd`)
- Records player state every frame
- Manages array of Replay objects
- Provides sampling interface for playback
- **Exports:**
  - `player` - Reference to CharacterBody2D player
  - `max_recordings` - Number of recording slots

#### 4. **CloneManager** (`scripts/clone_manager.gd`)
- Main orchestrator for the system
- Manages clone lifecycle (create, delete, cleanup)
- Handles state transitions
- Controls clone visibility
- **Exports:**
  - `config` - CloneConfig resource
  - `recording_system` - RecordingSystem reference
  - `player_node` - Player Node2D for position reset
  - `start_position` - Starting position for resets

#### 5. **CassetteUIController** (`scripts/cassette_ui_controller.gd`)
- UI layer for cassette interface
- Listens to CloneManager signals
- Updates button states and highlights
- Automatically finds CloneManager in scene tree (no exports needed)

#### 6. **CloneAnimator** (`scripts/clone-animator.gd`)
- Attached to clone instances
- Samples replay data and applies to visuals
- Handles animation state (idle, run, jump, etc.)

#### 7. **Replay** (`scripts/replay.gd`)
- Data class storing recorded frames
- Records: position, time, facing, velocity, animation flags
- Provides interpolation for smooth playback

#### 8. **TimerUpdater** (`scripts/timer-updater.gd`)
- Displays remaining time during recording/playback
- Updates countdown label each frame
- Automatically finds CloneManager in scene tree

---

## Scene Setup

### 1. Create CloneConfig Resource

In Godot:
1. Right-click in FileSystem → **New Resource**
2. Search for **CloneConfig** → Create
3. Set properties:
   - `max_clones`: 4
   - `time_limit`: 10.0
   - `clone_scene_path`: "res://scenes/replay-clone.tscn"
4. Save as `res://resources/clone_config.tres` (create `resources/` folder if needed)

### 2. Update Main Scene

Your main scene should have these nodes:

```
Main Scene
├── Player (CharacterBody2D)
│   └── Skeleton2D
├── RecordingSystem (Node)
│   Script: res://scripts/recording_system.gd
│   Exports:
│     - player: → Player
│     - max_recordings: 4
│
├── CloneManager (Node)
│   Script: res://scripts/clone_manager.gd
│   Exports:
│     - config: → res://resources/clone_config.tres
│     - recording_system: → RecordingSystem
│     - player_node: → Player
│     - start_position: Vector2(100, 100) [your start position]
│
└── CassetteUI (Control)
    Script: res://scripts/cassette_ui_controller.gd
    (No exports needed - finds CloneManager automatically)
```

**Steps:**
1. **Delete** old `PlayerCloning` and `Replayable` nodes (if they exist)
2. **Add** `RecordingSystem` node (Node type)
   - Attach script: `res://scripts/recording_system.gd`
   - Set `player` export to your Player node
   - Set `max_recordings` to 4
3. **Add** `CloneManager` node (Node type)
   - Attach script: `res://scripts/clone_manager.gd`
   - Load `clone_config.tres` in `config` export
   - Drag `RecordingSystem` to `recording_system` export
   - Drag `Player` to `player_node` export
   - Set `start_position` to your player's starting position
4. **Update** CassetteUI node
   - Change script from old `cassette-ui.gd` to `res://scripts/cassette_ui_controller.gd`
   - **That's it!** The script automatically finds CloneManager in the scene tree

### 3. Update Clone Scene (replay-clone.tscn)

The clone scene structure should be:

```
ReplayClone (Node2D) ← Attach: scripts/clone-animator.gd
├── Skeleton2D
│   └── hips (Bone2D)
│       └── AnimationPlayer
└── ReplayCloneScript (Node) ← Attach: scripts/replay-clone.gd
```

**Note:** The scripts are already updated, just ensure scene structure matches above.

---

## Signal Flow

### Recording Flow

```
User selects slot → User presses Record
  ↓
CassetteUIController._on_record_pressed()
  ↓
CloneManager.start_recording(slot_id)
  ├→ CloneManager.create_clone(slot_id)
  ├→ RecordingSystem.start_recording(slot_id)
  ├→ CloneManager.state_changed signal (→ WAITING_INPUT)
  └→ CloneManager.recording_started signal
  ↓
Player makes first move
  ↓
CloneManager._process() detects input
  ↓
CloneManager.state_changed signal (→ RECORDING)
  ↓
RecordingSystem._process() records each frame
  ↓
Time limit reached
  ↓
CloneManager.stop_recording()
  ├→ CloneManager.recording_stopped signal
  └→ CloneManager.state_changed signal (→ IDLE)
  ↓
CassetteUIController.slide_in()
```

### Playback Flow

```
User presses Play
  ↓
CassetteUIController._on_play_pressed()
  ↓
CloneManager.start_playback([clone_ids])
  ├→ RecordingSystem.reset_playback()
  ├→ CloneManager.state_changed signal (→ PLAYING)
  └→ CloneManager.playback_started signal
  ↓
CloneAnimator._process() samples replay data each frame
  ↓
Time limit reached
  ↓
CloneManager.stop_playback()
  ├→ CloneManager._snap_clones_to_final_positions()
  ├→ CloneManager.playback_stopped signal
  └→ CloneManager.state_changed signal (→ IDLE)
  ↓
CassetteUIController.slide_in()
```

---

## State Machine

```
        ┌──────────────┐
        │     IDLE     │ ← Paused, plan mode
        └───┬────────┬─┘
            │        │
    Record  │        │  Play
            ↓        ↓
    ┌───────────┐  ┌──────────┐
    │  WAITING  │  │ PLAYING  │
    │   INPUT   │  └────┬─────┘
    └─────┬─────┘       │
          │             │
    Move  │             │ Time limit
          ↓             │
    ┌──────────┐        │
    │RECORDING │        │
    └────┬─────┘        │
         │              │
         │ Time limit   │
         └──────┬───────┘
                ↓
        ┌──────────────┐
        │     IDLE     │
        └──────────────┘
```

---

## How To...

### Add More Clone Slots

1. Open `res://resources/clone_config.tres` in Godot
2. Change `max_clones` to desired number (e.g., 6)
3. In cassette UI scene, add more slot buttons
4. Update `slot_buttons` array in CassetteUIController to include new buttons

**No code changes needed!**

### Change Recording Duration

1. Open `res://resources/clone_config.tres` in Godot
2. Change `time_limit` to desired seconds (e.g., 15.0)

### Record Additional Player Data

**Example: Recording player health**

1. **Update RecordingSystem** (`scripts/recording_system.gd`):
   ```gdscript
   # In _process():
   replays[current_recording_id].record(
       player.global_position,
       current_time,
       PlayerActions.new([]),
       facing,
       player.velocity.y,
       player.is_sliding,
       player.is_wall_sliding,
       player.has_double_jump,
       player.health  # New parameter
   )
   ```

2. **Update Replay** (`scripts/replay.gd`):
   ```gdscript
   var healthHistory: Array[int] = []  # Add new array

   func record(pos: Vector2, t: float, actions: PlayerActions,
           facing: float, vel_y: float,
           sliding: bool, wall_sliding: bool, double_jump: bool,
           health: int) -> void:  # Add parameter
       # ... existing code ...
       healthHistory.push_back(health)  # Store health

   func sample(t: float) -> Dictionary:
       # ... existing code ...
       return {
           # ... existing fields ...
           "health": healthHistory[ix],  # Add to return dict
       }

   func clear() -> void:
       # ... existing code ...
       healthHistory.clear()
   ```

3. **Use in CloneAnimator** (`scripts/clone-animator.gd`):
   ```gdscript
   func _handle_playback_state(replay: Replay) -> void:
       var state_data = recording_system.sample(clone_id, clone_manager.time_elapsed)
       var clone_health = state_data.get("health", 100)
       # Do something with clone_health...
   ```

### Debug the System

#### Enable Debug Signals

Connect to `RecordingSystem.recording_frame_captured` signal:

```gdscript
# In your debug script
func _ready():
    var recording_system = get_node("/path/to/RecordingSystem")
    recording_system.recording_frame_captured.connect(_on_frame_captured)

func _on_frame_captured(clone_id: int, frame_data: Dictionary):
    print("Recording clone %d: pos=%s, time=%.2f" % [
        clone_id,
        frame_data["position"],
        frame_data["time"]
    ])
```

#### Check Current State

```gdscript
var clone_manager = get_node("/path/to/CloneManager")
print("Current state: ", CloneState.get_state_name(clone_manager.current_state))
print("Selected clone: ", clone_manager.selected_clone_id)
print("Time elapsed: ", clone_manager.time_elapsed)
```

#### Check Recordings

```gdscript
var recording_system = get_node("/path/to/RecordingSystem")
for i in range(4):
    if recording_system.has_recording(i):
        var duration = recording_system.get_recording_duration(i)
        print("Clone %d: %.2f seconds recorded" % [i, duration])
```

---

## Troubleshooting

### Clones don't appear

**Check:**
1. CloneManager `config` export is set to `clone_config.tres`
2. `clone_scene_path` in config is correct
3. Clone scene exists at specified path
4. RecordingSystem has a recording for that slot

**Debug:**
```gdscript
# Check if clone was created
print(clone_manager.clones)  # Should show array with Node instances
```

### Recording doesn't work

**Check:**
1. RecordingSystem `player` export is set
2. Player has `Skeleton2D` child node
3. Player has properties: `is_sliding`, `is_wall_sliding`, `has_double_jump`

**Debug:**
```gdscript
print(recording_system.is_recording)  # Should be true during recording
print(recording_system.current_recording_id)  # Should match slot ID
```

### UI doesn't respond

**Check:**
1. CloneManager node exists in the scene and is named "CloneManager"
2. CassetteUIController successfully found CloneManager (check console for errors)
3. Signals are connected (check in _ready())
4. Button node paths are correct

**Debug:**
```gdscript
# Check if signals are connected
print(clone_manager.state_changed.get_connections())
```

### Animations don't play correctly

**Check:**
1. Clone scene has `Skeleton2D/hips/AnimationPlayer` structure
2. AnimationPlayer has animations: idle, run, jump, double_jump, fall, slide, wall_slide
3. CloneAnimator can find CloneManager

**Debug:**
```gdscript
# In CloneAnimator
print(clone_manager)  # Should not be null
print(recording_system)  # Should not be null
print(clone_id)  # Should be 0-3
```

---

## Performance Notes

### Memory Management
- Clones are properly freed when overwritten (via `queue_free()`)
- Replay data is cleared before new recordings
- No memory leaks in refactored system

### Frame-by-Frame Recording
- Recording happens in `_process()`, so frame rate affects data density
- Higher frame rate = smoother playback but more memory
- Consider using `_physics_process()` for consistent recording at fixed intervals

### Optimization Tips
1. **Reduce max_clones** if you don't need 4 slots
2. **Shorten time_limit** for shorter recordings
3. **Reduce recorded data** by removing unnecessary fields from Replay

---

## Migration from Old System

If you're upgrading from the old system:

### What Changed

| Old System | New System | Notes |
|------------|------------|-------|
| `PlayerCloning` | `CloneManager` | Renamed, refactored with signals |
| `Replayable` | `RecordingSystem` | Decoupled from cloning logic |
| `cassette-ui.gd` | `cassette_ui_controller.gd` | Signal-based, no direct property access |
| `paused` flag | `CloneState.State.IDLE` | Proper state machine |
| `get_tree().root.find_child()` | Export variables | Direct references |

### Breaking Changes

- **Node structure changed** - Must update main scene
- **Export variables renamed** - Update scene connections
- **State flags removed** - Use `CloneManager.current_state` instead
- **Keyboard input moved** - Now in CloneManager `_process()`

---

## Credits

Refactored system designed for:
- Modularity and separation of concerns
- Signal-based decoupling
- Easy configuration and extension
- Proper memory management
- Clear documentation

Original concept: Clone/replay mechanic for puzzle-platformer gameplay.
