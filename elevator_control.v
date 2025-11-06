//============================================================
// Simple 4-Floor Elevator Controller
//============================================================
// Basic elevator that services floor requests one at a time
// Moves one floor per clock cycle, opens door for one cycle
//============================================================

module elevator_controller (
    input  wire        clk,              // system clock
    input  wire        reset,            // active-high reset
    input  wire [3:0]  req,              // floor requests (req[0]-req[3])
    output reg  [1:0]  current_floor,    // current floor (0-3)
    output reg         direction,        // 1 = up, 0 = down
    output reg         door,             // 1 = door open, 0 = closed
    output reg         busy              // 1 = moving, 0 = idle
);

    //----------- STATE ENCODING -----------
    localparam [1:0] IDLE      = 2'b00;
    localparam [1:0] MOVING    = 2'b01;
    localparam [1:0] DOOR_OPEN = 2'b10;

    //----------- INTERNAL REGISTERS -----------
    reg [1:0]  state;
    reg [3:0]  pending_req;      // Latched floor requests
    reg [1:0]  target_floor;     // Target floor to move to

    //----------- LATCH REQUESTS -----------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pending_req <= 4'b0000;
        end else begin
            // Latch new requests
            pending_req <= pending_req | req;
            
            // Clear request when door opens
            if (state == DOOR_OPEN) begin
                pending_req[current_floor] <= 1'b0;
            end
        end
    end

    //----------- MAIN STATE MACHINE -----------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state         <= IDLE;
            current_floor <= 2'd0;
            direction     <= 1'b1;      // Start going up
            door          <= 1'b0;
            busy          <= 1'b0;
            target_floor  <= 2'd0;
        end else begin
            case (state)
                IDLE: begin
                    door <= 1'b0;
                    busy <= 1'b0;
                    
                    // Check if there's a request at current floor
                    if (pending_req[current_floor]) begin
                        state <= DOOR_OPEN;
                    end
                    // Check if there are any pending requests
                    else if (|pending_req) begin
                        // Find next floor to service
                        if (direction) begin
                            // Going UP - find next floor above
                            if (current_floor < 2'd3 && pending_req[current_floor + 2'd1]) begin
                                target_floor <= current_floor + 2'd1;
                                state <= MOVING;
                            end else if (current_floor < 2'd2 && pending_req[current_floor + 2'd2]) begin
                                target_floor <= current_floor + 2'd2;
                                state <= MOVING;
                            end else if (current_floor < 2'd1 && pending_req[current_floor + 2'd3]) begin
                                target_floor <= current_floor + 2'd3;
                                state <= MOVING;
                            end
                            // No requests above, try below
                            else if (pending_req[2'd0] || pending_req[2'd1] || 
                                   pending_req[2'd2] || pending_req[2'd3]) begin
                                direction <= 1'b0;  // Change to DOWN
                                // Find request below
                                if (current_floor > 2'd0 && pending_req[current_floor - 2'd1]) begin
                                    target_floor <= current_floor - 2'd1;
                                    state <= MOVING;
                                end else if (current_floor > 2'd1 && pending_req[current_floor - 2'd2]) begin
                                    target_floor <= current_floor - 2'd2;
                                    state <= MOVING;
                                end else if (current_floor > 2'd2 && pending_req[current_floor - 2'd3]) begin
                                    target_floor <= current_floor - 2'd3;
                                    state <= MOVING;
                                end
                            end
                        end else begin
                            // Going DOWN - find next floor below
                            if (current_floor > 2'd0 && pending_req[current_floor - 2'd1]) begin
                                target_floor <= current_floor - 2'd1;
                                state <= MOVING;
                            end else if (current_floor > 2'd1 && pending_req[current_floor - 2'd2]) begin
                                target_floor <= current_floor - 2'd2;
                                state <= MOVING;
                            end else if (current_floor > 2'd2 && pending_req[current_floor - 2'd3]) begin
                                target_floor <= current_floor - 2'd3;
                                state <= MOVING;
                            end
                            // No requests below, try above
                            else if (pending_req[2'd0] || pending_req[2'd1] || 
                                   pending_req[2'd2] || pending_req[2'd3]) begin
                                direction <= 1'b1;  // Change to UP
                                // Find request above
                                if (current_floor < 2'd3 && pending_req[current_floor + 2'd1]) begin
                                    target_floor <= current_floor + 2'd1;
                                    state <= MOVING;
                                end else if (current_floor < 2'd2 && pending_req[current_floor + 2'd2]) begin
                                    target_floor <= current_floor + 2'd2;
                                    state <= MOVING;
                                end else if (current_floor < 2'd1 && pending_req[current_floor + 2'd3]) begin
                                    target_floor <= current_floor + 2'd3;
                                    state <= MOVING;
                                end
                            end
                        end
                    end
                end

                MOVING: begin
                    busy <= 1'b1;
                    door <= 1'b0;
                    
                    // Move one floor toward target
                    if (current_floor < target_floor) begin
                        current_floor <= current_floor + 2'd1;
                        direction <= 1'b1;  // UP
                    end else if (current_floor > target_floor) begin
                        current_floor <= current_floor - 2'd1;
                        direction <= 1'b0;  // DOWN
                    end
                    
                    // Check if we reached target
                    if (current_floor == target_floor) begin
                        state <= DOOR_OPEN;
                    end
                end

                DOOR_OPEN: begin
                    door <= 1'b1;
                    busy <= 1'b0;
                    state <= IDLE;  // Go back to idle after one cycle
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
