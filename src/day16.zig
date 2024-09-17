const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("16", solve);

const Valve = struct {
    tunnels: [5]u8,
    tunnelCount: u8,
    flowRate: u8,
};

const StackItem = struct {
    flowRate: u16,
    open: u16,
    idx: u8,
    minutesLeft: u8,
    pressure: u8,
};

const OpenMap = std.ArrayListUnmanaged(bool);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var valves = std.ArrayListUnmanaged(Valve){};
    defer valves.deinit(alloc);

    var interestingValvesStorage: [16]u8 = undefined;

    const init = parse: {
        const ParsingValve = struct {
            tunnels: []const u8,
            flowRate: u8,
        };

        var map: [26 * 26]u8 = undefined;
        var list: [100]ParsingValve = undefined;
        var listCount: usize = 0;

        var lines = std.mem.splitScalar(u8, input, '\n');
        while (lines.next()) |line| {
            const flowRateStart = "Valve AA has flow rate=".len;

            var i = flowRateStart;
            while (line[i] != ';') i += 1;

            const flowRate = try std.fmt.parseInt(u8, line[flowRateStart..i], 10);

            var tunnelPart = line[i + "; tunnels lead to valve ".len ..]; // valve or valves
            if (tunnelPart[0] == ' ') {
                tunnelPart = tunnelPart[1..];
            }

            const v2 = parseValve(line["Valve ".len..]);
            map[v2] = @intCast(listCount);
            list[listCount] = .{ .tunnels = tunnelPart, .flowRate = flowRate };
            listCount += 1;
        }

        var valveSlice = try valves.addManyAsSlice(alloc, listCount);

        var totalFlowRate: u8 = 0;
        var interestingValves: []u8 = interestingValvesStorage[0..0];
        const start = map[parseValve("AA")];

        for (0..listCount) |i| {
            const v = list[i];
            var valve = Valve{
                .tunnels = undefined,
                .tunnelCount = 0,
                .flowRate = v.flowRate,
            };

            if (v.flowRate > 0 or i == start) {
                interestingValves.len += 1;
                interestingValves[interestingValves.len - 1] = @intCast(i);
            }

            totalFlowRate += v.flowRate;

            var tunnels = std.mem.splitSequence(u8, v.tunnels, ", ");
            while (tunnels.next()) |tunnel| {
                const v2 = map[parseValve(tunnel)];
                valve.tunnels[valve.tunnelCount] = v2;
                valve.tunnelCount += 1;
            }

            valveSlice[i] = valve;
        }

        break :parse .{ start, totalFlowRate, interestingValves };
    };

    const interestingValves: []u8 = init[2];
    const distanceMap = try alloc.alloc(u8, interestingValves.len * interestingValves.len);
    defer alloc.free(distanceMap);
    @memset(distanceMap, 0);

    try fillDistanceMap(alloc, distanceMap, interestingValves, valves.items);
    for (0..interestingValves.len) |i| {
        const row = distanceMap[i * interestingValves.len .. (i + 1) * interestingValves.len];

        for (0..i) |j| {
            row[j] = distanceMap[j * interestingValves.len + i];
        }
    }

    var stack = std.ArrayListUnmanaged(StackItem){};
    defer stack.deinit(alloc);

    var startIdx: u8 = 0;
    for (interestingValves, 0..) |v, i| {
        if (v == init[0]) {
            startIdx = @intCast(i);
            break;
        }
    }

    // not tracking start index
    const states = try alloc.alloc(u16, @as(u32, 1) << @intCast(interestingValves.len - 1));
    defer alloc.free(states);

    for (interestingValves) |*iv| {
        iv.* = valves.items[iv.*].flowRate;
    }

    @memset(states, 0);
    try findOptimalDistance(alloc, &stack, states, interestingValves, distanceMap, startIdx, 30);
    var mostPressure: usize = 0;

    for (states) |state| {
        if (state > mostPressure) {
            mostPressure = state;
        }
    }

    @memset(states, 0);
    try findOptimalDistance(alloc, &stack, states, interestingValves, distanceMap, startIdx, 26);

    var mostPressureWithElephant: usize = 0;
    for (states, 0..) |state, i| {
        if (state == 0) continue;

        for (states[i..], i..) |state2, j| { // n^2 loop takes 75% of time
            if (state2 == 0) continue;

            const total = state + state2;
            if (total > mostPressureWithElephant and (i & j) == 0) {
                mostPressureWithElephant = total;
            }
        }
    }

    return .{ mostPressure, mostPressureWithElephant };
}

fn findOptimalDistance(alloc: std.mem.Allocator, stack: *std.ArrayListUnmanaged(StackItem), states: []u16, flowRates: []const u8, distanceMap: []const u8, startIdx: u8, minutesLeft: u8) !void {
    try stack.append(alloc, .{
        .idx = startIdx,
        .minutesLeft = minutesLeft,
        .open = 0,
        .pressure = 0,
        .flowRate = 0,
    });

    while (stack.popOrNull()) |item| {
        const totalFlowRate = item.flowRate + @as(u16, item.pressure) * item.minutesLeft;

        if (totalFlowRate > states[item.open]) {
            states[item.open] = totalFlowRate;
        }

        for (flowRates, 0..) |fr, i| {
            if (i == startIdx) continue;

            const j = if (i > startIdx) i - 1 else i;
            const bitset = item.open | (@as(u16, 1) << @intCast(j));
            if (bitset == item.open) continue;

            const distance = distanceMap[item.idx * flowRates.len + i];
            if (distance == 0) continue;

            const duration = distance + 1; // opening valve takes a minute
            if (item.minutesLeft < duration) continue;

            const newFlowRate = item.flowRate + @as(u16, item.pressure) * duration;

            try stack.append(alloc, .{
                .idx = @intCast(i),
                .minutesLeft = item.minutesLeft - duration,
                .open = bitset,
                .pressure = item.pressure + fr,
                .flowRate = newFlowRate,
            });
        }
    }
}

fn fillDistanceMap(alloc: std.mem.Allocator, map: []u8, interestingValves: []const u8, valves: []const Valve) !void {
    const Item = struct {
        valveIndex: u8,
        distance: u8,
    };

    var queue = std.ArrayListUnmanaged(Item){};
    defer queue.deinit(alloc);

    var interestingLookup: [256]u8 = .{255} ** 256;
    for (interestingValves, 0..) |valve, i| {
        interestingLookup[valve] = @intCast(i);
    }

    var initMap: [16]bool = .{false} ** 16;

    for (interestingValves, 0..) |startValve, i| {
        initMap[i] = true;

        try queue.append(alloc, .{
            .valveIndex = startValve,
            .distance = 0,
        });
        var seenMap = initMap;
        var beenMap: [100]bool = .{false} ** 100;

        var queueIdx: usize = 0;
        while (queueIdx < queue.items.len) {
            var item = queue.items[queueIdx];
            queueIdx += 1;
            beenMap[item.valveIndex] = true;

            const inte = interestingLookup[item.valveIndex];
            if (inte < seenMap.len and !seenMap[inte]) {
                seenMap[inte] = true;
                map[i * interestingValves.len + inte] = item.distance;

                var count: usize = 0;
                for (seenMap) |seen| {
                    if (seen) count += 1;
                }
                if (count == interestingValves.len) {
                    break;
                }
            }

            item.distance += 1;

            const valve = valves[item.valveIndex];
            for (valve.tunnels[0..valve.tunnelCount]) |tunnel| {
                if (beenMap[tunnel]) continue;
                (try queue.addOne(alloc)).* = .{
                    .valveIndex = tunnel,
                    .distance = item.distance,
                };
            }
        }

        queue.items.len = 0;
    }
}

fn parseValve(txt: []const u8) u16 {
    var b: u16 = @intCast(txt[1] - 'A');
    b *= 26;
    return b + @as(u16, @intCast(txt[0] - 'A'));
}

test {
    const input =
        \\Valve AA has flow rate=0; tunnels lead to valves DD, II, BB
        \\Valve BB has flow rate=13; tunnels lead to valves CC, AA
        \\Valve CC has flow rate=2; tunnels lead to valves DD, BB
        \\Valve DD has flow rate=20; tunnels lead to valves CC, AA, EE
        \\Valve EE has flow rate=3; tunnels lead to valves FF, DD
        \\Valve FF has flow rate=0; tunnels lead to valves EE, GG
        \\Valve GG has flow rate=0; tunnels lead to valves FF, HH
        \\Valve HH has flow rate=22; tunnel leads to valve GG
        \\Valve II has flow rate=0; tunnels lead to valves AA, JJ
        \\Valve JJ has flow rate=21; tunnel leads to valve II
    ;
    const results = try solve(std.testing.allocator, input);
    try std.testing.expectEqual(1651, results[0]);
    try std.testing.expectEqual(1707, results[1]);
}
