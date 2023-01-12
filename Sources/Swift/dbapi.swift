func seek(_ pos: UInt32) {
    _ = deadbeef.sendmessage(UInt32(DB_EV_SEEK), 0, 10000, 0)
}

func sendmessage(id: UInt32, ctx: UInt, p1: UInt32, p2: UInt32) -> Int32 {
    deadbeef.sendmessage(id, ctx, p1, p2)
}
