# Lever & Door Integration Guide

## Overview

The lever system is fully integrated with the clone recording/replay system. When you record a clone interacting with a lever, the toggle is recorded and replayed for that clone. Multiple clones and the player can toggle the same lever, and the system tracks all interactions correctly.

## How It Works

### Lever Mechanics
- **During Recording**: When the player presses the interact key (E) near a lever, it toggles on/off
- **During Replay**: The lever replays all previous clone interactions in chronological order
- **Player Override**: If the player interacts with the lever during recording, it overrides the replay state from that point forward

### State Management
- Each clone slot has its own toggle history with timestamps
- When recording a new clone, the lever replays all OTHER clone interactions
- When playing back all clones, the lever merges all interactions in chronological order
- The lever correctly handles scenarios like: Clone A turns it on → Clone B turns it off → Player turns it on

## Using Levers in Your Scene

### 1. Add a Lever

Simply instance the lever scene:
```
scenes/level-elements/lever.tscn
```

The lever is already configured with:
- Automatic system detection (finds RecordingSystem and CloneManager)
- Player interaction area
- Toggle animations
- Recording/replay integration

### 2. Configure the Lever (Optional)

The lever has these export variables:
- `action_key`: The input action for toggling (default: "interact")
- `default_state`: Whether the lever starts on or off (default: false/off)

### 3. Connect to a Door

To make a lever control a door:

1. Add a door to your scene (create a StaticBody2D with a sprite and collision shape)
2. Attach the `door.gd` script to it
3. In the Godot editor, select the lever node
4. Go to the "Node" tab (next to Inspector)
5. Find the "switched" signal
6. Connect it to your door's `on_switch_toggled` method

That's it! The door will now open when the lever is on and close when it's off.

### Door Configuration

The door script (`scripts/door.gd`) has these export variables:
- `open_position_offset`: How far the door moves when opening (default: Vector2(0, -200))
- `animation_duration`: How long the open/close animation takes (default: 0.5s)
- `start_open`: Whether the door starts open (default: false)

## Example Puzzle Scenario

Here's a common puzzle setup:

1. Player needs to get through a door
2. Lever starts in OFF position (door closed)
3. Player toggles lever to ON (door opens)
4. Player walks through door
5. But now they need to record a clone to toggle the lever again for another puzzle!
6. Clone 1 replays → toggles lever OFF → door closes
7. Player can now use this to solve the next part of the puzzle

## Advanced: Multiple Levers

You can have multiple levers in a scene, each controlling different doors or even the same door:

- Connect multiple levers to one door → door opens only when ALL levers are on (requires custom logic)
- Connect one lever to multiple doors → all doors open/close together
- Chain reactions: Lever 1 → Door 1 opens, revealing Lever 2 → Door 2, etc.

## Technical Details

### Signal
The lever emits this signal:
```gdscript
signal switched(is_on: bool)
```

Connect to this signal to make anything respond to the lever state.

### Methods
If you need to control the lever from code:
```gdscript
lever.toggle()  # Toggle the lever
lever.resetToDefault()  # Reset to default state
```

### Groups
The lever is in the "lever" group, so you can find all levers with:
```gdscript
get_tree().get_nodes_in_group("lever")
```
