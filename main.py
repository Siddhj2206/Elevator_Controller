import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer


# @cocotb.test(skip=True)
@cocotb.test()
async def console_elevator(dut):
    """Interactive console simulation for 4-floor elevator."""

    # Start the clock (10ns period = 100 MHz)
    clock = cocotb.start_soon(Clock(dut.clk, 10, "ns").start())

    # Reset logic
    dut.reset.value = 1
    dut.req.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    await RisingEdge(dut.clk)

    print("\n=== Elevator Controller Simulation ===")
    print("Press 0-3 to request a floor. Type 'q' to quit.\n")

    current = int(dut.current_floor.value)

    while True:
        user = input(f"[Current floor: {current}] > ").strip()
        if user.lower() == "q":
            print("Exiting simulation.")
            break
        if not user.isdigit():
            print("Invalid input. Enter 0-3 or 'q'.")
            continue

        floor = int(user)
        if floor < 0 or floor > 3:
            print("Floor out of range (0-3).")
            continue

        # Assert request for one clock cycle
        dut.req.value = 1 << floor
        print(f"Requesting floor {floor}...")
        await RisingEdge(dut.clk)
        dut.req.value = 0

        # Monitor elevator until it services this request
        arrived = False
        timeout = 1000  # Maximum clock cycles to wait
        cycles = 0
        last_busy = 0
        door_opened = False

        while not arrived and cycles < timeout:
            await RisingEdge(dut.clk)
            cycles += 1

            new_floor = int(dut.current_floor.value)
            busy = int(dut.busy.value)
            door = int(dut.door.value)
            direction = "UP" if int(dut.direction.value) else "DOWN"

            # Detect floor changes
            if new_floor != current:
                print(f"  [{direction}] Moved to floor {new_floor}")
                current = new_floor

            # Detect when elevator starts moving
            if busy and not last_busy:
                print(f"  [BUSY] Elevator moving {direction}...")

            # Detect when elevator stops moving
            if not busy and last_busy and not door:
                print(f"  [IDLE] Elevator stopped")

            # Detect door opening
            if door and not door_opened:
                print(f"  [DOOR] Door opened at floor {new_floor}")
                door_opened = True

            # Detect door closing (end of service)
            if not door and door_opened:
                print(f"  [DOOR] Door closed")
                # Check if this was our requested floor
                if new_floor == floor:
                    arrived = True
                else:
                    door_opened = False  # Reset if wrong floor

            last_busy = busy

        if cycles >= timeout:
            print(f"⚠ WARNING: Timeout after {timeout} cycles. Elevator may be stuck.")
        else:
            print(f"✓ Arrived at floor {floor} (took {cycles} cycles)\n")


@cocotb.test()
async def automated_test(dut):
    """Automated test sequence to verify basic functionality."""

    # Start the clock
    clock = cocotb.start_soon(Clock(dut.clk, 10, "ns").start())

    # Reset
    dut.reset.value = 1
    dut.req.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    await RisingEdge(dut.clk)

    print("\n=== Automated Test Sequence ===\n")

    async def request_floor_and_wait(floor, max_cycles=500):
        """Request a floor and wait for service."""
        current_floor = int(dut.current_floor.value)
        print(f"Test: Requesting floor {floor} (currently at {current_floor})")
        dut.req.value = 1 << floor
        await RisingEdge(dut.clk)
        dut.req.value = 0

        door_opened = False
        cycles = 0
        last_floor = current_floor

        while cycles < max_cycles:
            await RisingEdge(dut.clk)
            cycles += 1

            floor_val = int(dut.current_floor.value)
            door = int(dut.door.value)
            busy = int(dut.busy.value)

            # Debug output (commented out for clean demo)
            # if cycles <= 20:
            #     try:
            #         state = int(dut.state.value)
            #         pending = int(dut.pending_req.value)
            #         direction = int(dut.direction.value)
            #         print(f"  [DBG] cycle {cycles}: floor={floor_val}, busy={busy}, door={door}, state={state}, pending={pending:04b}, dir={direction}")
            #     except:
            #         print(f"  [DBG] cycle {cycles}: floor={floor_val}, busy={busy}, door={door}")

            if floor_val != last_floor:
                print(f"  Moved to floor {floor_val}")
                last_floor = floor_val

            if door and floor_val == floor:
                if not door_opened:
                    print(f"  ✓ Door opened at floor {floor} (cycles: {cycles})")
                    door_opened = True
            elif door_opened and not door:
                print(f"  ✓ Door closed, service complete\n")
                return True

        final_floor = int(dut.current_floor.value)
        print(
            f"  ✗ FAILED: Timeout waiting for floor {floor} (stuck at floor {final_floor})\n"
        )
        return False

    # Test sequence
    tests = [
        ("Move up from floor 0 to floor 2", 2),
        ("Move down from floor 2 to floor 1", 1),
        ("Move up from floor 1 to floor 3", 3),
        ("Move down from floor 3 to floor 0", 0),
        ("Stay at current floor", 0),
        ("Move to floor 2 again", 2),
    ]

    passed = 0
    failed = 0

    for desc, floor in tests:
        print(f"--- {desc} ---")
        if await request_floor_and_wait(floor):
            passed += 1
        else:
            failed += 1

        # Small delay between tests
        for _ in range(10):
            await RisingEdge(dut.clk)

    print(f"\n=== Test Results ===")
    print(f"Passed: {passed}/{len(tests)}")
    print(f"Failed: {failed}/{len(tests)}")

    if failed == 0:
        print("✓ All tests passed!")
    else:
        print("✗ Some tests failed")
