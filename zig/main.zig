const std = @import("std");

const SplitResult = struct {
    lower: ?*Node,
    equal: ?*Node,
    greater: ?*Node,
};

const NodePair = struct {
    first: ?*Node,
    second: ?*Node,
};

const Node = struct {
    x: usize,
    y: usize,
    left: ?*Node = null,
    right: ?*Node = null,

    var rng = std.rand.DefaultPrng.init(0x1234);

    fn init(x: usize) Node {
        return .{ .x = x, .y = rng.random.int(usize) };
    }

    fn merge(lower: ?*Node, greater: ?*Node) ?*Node {
        if (lower == null) return greater;
        if (greater == null) return lower;

        const lower_ = lower.?;
        const greater_ = greater.?;
        if (lower_.y < greater_.y) {
            lower_.right = merge(lower_.right, greater);
            return lower;
        } else {
            greater_.left = merge(lower, greater_.left);
            return greater;
        }
    }

    fn splitBinary(orig: ?*Node, value: usize) NodePair {
        if (orig) |orig_| {
            if (orig_.x < value) {
                const split_pair = splitBinary(orig_.right, value);
                orig_.right = split_pair.first;
                return .{ .first = orig, .second = split_pair.second };
            } else {
                const split_pair = splitBinary(orig_.left, value);
                orig_.left = split_pair.second;
                return .{ .first = split_pair.first, .second = orig };
            }
        } else {
            return .{ .first = null, .second = null };
        }
    }

    fn merge3(lower: ?*Node, equal: ?*Node, greater: ?*Node) ?*Node {
        return merge(merge(lower, equal), greater);
    }

    fn split(orig: ?*Node, value: usize) SplitResult {
        const lower_other = splitBinary(orig, value);
        const equal_greater = splitBinary(lower_other.second, value + 1);
        return .{ .lower = lower_other.first, .equal = equal_greater.first, .greater = equal_greater.second };
    }
};

const Tree = struct {
    root: ?*Node = null,
    allocator: *std.mem.Allocator,

    fn init(allocator: *std.mem.Allocator) Tree {
        return .{ .allocator = allocator };
    }

    fn hasValue(self: *Tree, x: usize) bool {
        const splited = Node.split(self.root, x);
        const result = splited.equal != null;
        self.root = Node.merge3(splited.lower, splited.equal, splited.greater);
        return result;
    }

    fn insert(self: *Tree, x: usize) !void {
        var splited = Node.split(self.root, x);
        if (splited.equal == null) {
            const node = try self.allocator.create(Node);
            node.* = Node.init(x);
            splited.equal = node;
        }
        self.root = Node.merge3(splited.lower, splited.equal, splited.greater);
    }

    fn erase(self: *Tree, x: usize) void {
        const splited = Node.split(self.root, x);
        self.root = Node.merge(splited.lower, splited.greater);
    }
};

pub fn main() !void {
    Node.rng.seed(std.time.milliTimestamp());

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var tree = Tree.init(&arena.allocator);
    var cur: usize = 5;
    var res: usize = 0;

    var i: usize = 1;
    while (i < 1000000) : (i += 1) {
        cur = (cur * 57 + 43) % 10007;
        switch (i % 3) {
            0 => try tree.insert(cur),
            1 => tree.erase(cur),
            2 => {
                const hasVal = tree.hasValue(cur);
                if (hasVal)
                    res += 1;
            },
            else => unreachable,
        }
    }
    std.debug.warn("{}\n", .{res});
}
