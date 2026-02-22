# Time and Weather Sync Review & Improvement Plan

## Current Method Review

The current synchronization mechanism in `weathersync` uses a **Server-Push** model with fixed intervals.

### How it Works:
1.  **Server Loop**: A thread runs every 5 seconds (`Config.syncDelay`).
2.  **Time Calculation**: The server increments its internal `currentTime` based on the `currentTimescale`.
3.  **Broadcast**: Every 5 seconds, the server triggers `weathersync:changeTime` for **all** clients.
4.  **Weather Sync**: Every 25 seconds (5 ticks), the server updates regional weather for each player individually.
5.  **Client Application**:
    - **RDR2**: Uses `ADVANCE_CLOCK_TIME_TO` to smooth the transition over the next 5 seconds.
    - **GTA V**: Overrides the network clock if the drift exceeds 5 minutes.

### Identified Issues:
- **Network Overhead**: Broadcasting to every player every 5 seconds creates unnecessary traffic, especially with high player counts.
- **Latency Blindness**: The system does not account for network transit time. A player with 200ms ping will always be behind the server and other players.
- **"Jumping" Time**: If a sync packet is dropped or delayed, the next update causes a visible jump in time as the client tries to catch up.
- **Regional Weather Delay**: The 25-second interval for weather updates can result in players seeing incorrect weather for nearly half a minute after entering a new region.
- **Clock Drift**: Clients and servers calculate time passage independently between syncs, leading to inevitable divergence.
- **Unintended Sync Disabling**: Commands like `/mytime`, `/myweather`, or `/weathersync` toggle the `syncEnabled` flag. If this is disabled (accidentally or by another script), the client stops processing server time updates entirely, leading to drastic hour differences.
- **Event Blocking**: If a client-side script or another event handler blocks the main thread or the network event queue, `weathersync:changeTime` packets may not be processed in a timely manner.
- **Stateless Sync**: Because the server only sends the "current time" every 5 seconds, missing these packets (due to network issues) results in the client's clock standing still until the next successful packet.

---

## Improved Sync Method: Epoch-Based Synchronization

The proposed method shifts from "Constant Overriding" to a **Deterministic Interpolation** model.

### 1. Epoch Data Structure
Instead of sending the current time, the server sends a "Sync Epoch" packet:
```lua
{
    baseTime = 123456,       -- In-game seconds since start of week
    serverTimer = 9876543,   -- Result of GetGameTimer() on server
    timescale = 30,          -- Current timescale
    isFrozen = false         -- Whether time is frozen
}
```

### 2. Client-Side Interpolation
Clients calculate the current time locally every frame (or at a high frequency):
- `elapsedRealTime = GetGameTimer() - serverTimer`
- `currentTime = baseTime + (elapsedRealTime * timescale / 1000)`

### 3. Benefits:
- **Resilience to Packet Loss**: Once a client receives the "Epoch", they can calculate the correct time indefinitely without further updates, even if they miss subsequent sync packets.
- **Zero Jumps**: Time flows smoothly because it's calculated based on the client's own high-precision timer.
- **Consistency**: Even if the sync event is delayed by network lag, the `serverTimer` allows the client to calculate exactly where the time *should* be at the moment of receipt.
- **Reduced Traffic**: Sync packets only need to be sent when state changes or on a long interval (e.g., 60s) to correct for CPU clock drift.

### 4. Handling Player Join/Leave:
The current broadcast-to-all (`-1`) approach for time is efficient and unaffected by players joining or leaving. The epoch-based method continues this efficiency while providing better stability for individual clients who might have transient connection issues.

### 4. Weather Sync Improvements:
- **Predictive Weather**: Instead of the server polling every 25 seconds, the server can provide the client with the current weather, the next weather, and the timestamp of the next transition.
- **Instant Region Updates**: Ensure the `playerRegionChanged` event triggers an immediate response from the server (this is mostly implemented but can be optimized).
- **State-Based Transitions**: Use a shared "Weather Start Time" so clients can calculate exactly where they should be in a transition curve (e.g., 40% through a transition from Sunny to Rainy).

### 5. Validation & Self-Correction (Client-Side)
To prevent the client from staying in a desynced state (even if `syncEnabled` is true), a background thread will periodically validate the game state:
- **Time Validation**: Every 10-15 seconds, compare `GetClockHours()` and `GetClockMinutes()` with the server-derived `currentTime`. If the drift is significant (e.g., > 15 minutes) or if the hour is completely wrong, re-trigger the `setTime` logic.
- **Weather Validation**: Every 30 seconds, verify if the current game weather hash matches the last received server weather. This corrects instances where internal game logic or other scripts might have overridden the weather.
- **Sync Heartbeat**: If no "Epoch" or sync packet has been received for over 2 minutes, the client should proactively request a fresh sync from the server.

## Implementation Steps (Plan)

1.  **Modify Server Tick**: Change the server loop to only broadcast the "Epoch" packet when state changes or on a long interval (60s).
2.  **Update Client Logic**: Implement the interpolation formula in a `Citizen.CreateThread` loop.
3.  **Ping Estimation**: Implement a simple heart-beat or use the built-in latency metrics to refine the time calculation.
4.  **Weather Packet Update**: Include `startTime` and `duration` in the `updateRegionalWeather` packet to allow clients to sync transitions perfectly.
