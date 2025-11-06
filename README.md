# 4-Floor Elevator Controller

A simple and robust elevator controller implemented in Verilog for a 4-floor building. This project demonstrates basic FSM (Finite State Machine) design principles with clean, easy-to-understand code suitable for demonstrations and educational purposes.

## Features

- **4 Floors**: Services floors 0 through 3
- **Simple State Machine**: Only 3 states (IDLE, MOVING, DOOR_OPEN)
- **Request Queuing**: Multiple floor requests are queued and serviced in order
- **Direction-Based Logic**: Services requests in current direction before reversing
- **Clean I/O Interface**: Simple clock, reset, and request inputs

## Module Interface

```verilog
module elevator_controller (
    input  wire        clk,              // System clock
    input  wire        reset,            // Active-high reset
    input  wire [3:0]  req,              // Floor requests (req[0]-req[3])
    output reg  [1:0]  current_floor,    // Current floor (0-3)
    output reg         direction,        // 1 = up, 0 = down
    output reg         door,             // 1 = door open, 0 = closed
    output reg         busy              // 1 = moving, 0 = idle
);
```

### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | Input | 1 | System clock |
| `reset` | Input | 1 | Active-high synchronous reset |
| `req` | Input | 4 | Floor request signals (bit 0 = floor 0, bit 3 = floor 3) |
| `current_floor` | Output | 2 | Current floor number (0-3) |
| `direction` | Output | 1 | Movement direction (1 = up, 0 = down) |
| `door` | Output | 1 | Door status (1 = open, 0 = closed) |
| `busy` | Output | 1 | Movement status (1 = moving, 0 = idle) |

## Operation

### State Machine

The elevator operates in three states:

1. **IDLE**: Waiting for requests or determining next destination
2. **MOVING**: Traveling to target floor (one floor per clock cycle)
3. **DOOR_OPEN**: Door open at destination floor (one clock cycle)

### Request Handling

- Floor requests are latched when `req[n]` is asserted
- Requests remain active until serviced (door opens at that floor)
- Multiple simultaneous requests are handled in order based on current direction
- Priority: requests in current direction → reverse direction

### Movement

- Moves **one floor per clock cycle** when in MOVING state
- Automatically determines shortest path to next requested floor
- Changes direction when no requests remain in current direction

## Requirements

- Python 3.11+
- [uv](https://github.com/astral-sh/uv) (package manager)
- Icarus Verilog simulator
- cocotb 2.0+

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd Elevator_Controller
uv sync
```

2. Dependencies are managed by uv and defined in `pyproject.toml`. They will be automatically installed when running tests.

## Running Tests

### Automated Test Suite

Run the complete automated test suite:

```bash
uv run make SIM=icarus
```

This runs 6 tests covering:
- Moving up multiple floors
- Moving down multiple floors
- Direction changes
- Same-floor requests
- Sequential requests

Expected output:
```
=== Test Results ===
Passed: 6/6
Failed: 0/6
✓ All tests passed!
```

### Interactive Console Mode

For interactive testing (requires terminal input):

```bash
# Edit main.py and change @cocotb.test(skip=True) to @cocotb.test()
# for the console_elevator test, then run:
uv run make SIM=icarus
```

In console mode, you can type floor numbers (0-3) to request floors and watch the elevator respond in real-time.

## File Structure

```
.
├── elevator_control.v      # Main Verilog module
├── main.py                  # Cocotb test suite
├── Makefile                 # Simulation makefile
├── pyproject.toml          # Python dependencies
└── README.md               # This file
```

## Design Details

### Timing

- **Movement**: 1 clock cycle per floor
- **Door Open**: 1 clock cycle
- **State Transitions**: Single clock cycle

### Example Sequence

Request floor 3 from floor 0:

```
Cycle 0: IDLE at floor 0, req[3] asserted
Cycle 1: MOVING, floor 0 → 1
Cycle 2: MOVING, floor 1 → 2
Cycle 3: MOVING, floor 2 → 3
Cycle 4: DOOR_OPEN at floor 3
Cycle 5: IDLE at floor 3
```

### Reset Behavior

On reset (`reset = 1`):
- Current floor: 0
- Direction: Up (1)
- Door: Closed (0)
- Busy: Idle (0)
- All pending requests: Cleared

## Testing Details

The test suite in `main.py` includes:

1. **Move up from floor 0 to 2**: Tests upward movement
2. **Move down from floor 2 to 1**: Tests downward movement
3. **Move up from floor 1 to 3**: Tests direction continuation
4. **Move down from floor 3 to 0**: Tests multi-floor descent
5. **Stay at current floor**: Tests same-floor requests
6. **Move to floor 2 again**: Tests repeated requests

Each test verifies:
- Correct floor transitions
- Door opens at destination
- Request is cleared after service
- Movement completes within expected time

## Customization

To modify timing parameters, edit the state machine in `elevator_control.v`:

```verilog
// Example: Make elevator pause longer at each floor
DOOR_OPEN: begin
    door <= 1'b1;
    busy <= 1'b0;
    // Add counter here for multi-cycle door open
    state <= IDLE;
end
```

## Known Limitations

- No safety features (door sensors, emergency stop, etc.)
- No acceleration/deceleration modeling
- Simplified door operation (instant open/close)
- No multiple elevator coordination
- No call button differentiation (up/down buttons)
