// Cloudflare Pages Function: /api/rideshare/[[route]]
// Global in-memory state for Cloudflare Edge Isolate
const globalDrivers = {};
const globalRides = [];
const globalCopays = [];
const globalFoodMatches = [];

const CORS_HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type"
};

export async function onRequestOptions() {
    return new Response(null, { headers: CORS_HEADERS, status: 204 });
}

export async function onRequestGet(context) {
    const url = new URL(context.request.url);
    const pathname = url.pathname;

    if (pathname.includes("/status")) {
        const now = Date.now() / 1000;
        const onlineDrivers = Object.values(globalDrivers).filter(d => d.online && (now - d.last_ping < 900));
        const activeRides = globalRides.filter(r => r.status === "PENDING" || r.status === "ACCEPTED");
        const completedRides = globalRides.filter(r => r.status === "COMPLETED");

        const resp = {
            online_drivers_count: onlineDrivers.length,
            online_drivers: onlineDrivers,
            active_rides: activeRides,
            completed_rides_count: completedRides.length,
            copays_count: globalCopays.length,
            copays: globalCopays,
            food_matches_count: globalFoodMatches.length,
            food_matches: globalFoodMatches,
            total_rnr_disbursed: (completedRides.length * 400) + 
                globalCopays.reduce((sum, c) => sum + (c.rnr_grant || 0), 0) + 
                globalFoodMatches.reduce((sum, f) => sum + (f.rnr_grant || 0), 0),
            timestamp: now
        };
        return new Response(JSON.stringify(resp), { headers: CORS_HEADERS, status: 200 });
    }

    return new Response(JSON.stringify({ error: "Endpoint not found" }), { headers: CORS_HEADERS, status: 404 });
}

export async function onRequestPost(context) {
    const url = new URL(context.request.url);
    const pathname = url.pathname;

    let body = {};
    try {
        body = await context.request.json();
    } catch (e) {
        body = {};
    }

    const now = Date.now() / 1000;

    // 1. DRIVER TOGGLE
    if (pathname.includes("/driver/toggle")) {
        const wallet = (body.wallet || "").trim().toLowerCase();
        if (!wallet) {
            return new Response(JSON.stringify({ error: "Wallet address required" }), { headers: CORS_HEADERS, status: 400 });
        }
        const online = Boolean(body.online !== false);
        globalDrivers[wallet] = {
            wallet: wallet,
            name: body.name || "Utica Community Driver",
            phone: body.phone || "",
            car: body.car || "Vehicle",
            online: online,
            last_ping: now
        };
        return new Response(JSON.stringify({ ok: true, driver: globalDrivers[wallet] }), { headers: CORS_HEADERS, status: 200 });
    }

    // 2. RIDE REQUEST (DISPATCH)
    if (pathname.includes("/ride/request")) {
        const rideId = `RIDE-${Math.floor(Date.now() / 100) % 100000}`;
        const pickup = body.pickup || "Downtown Utica";
        const dropoff = body.dropoff || "Utica";
        const riderName = body.rider_name || "Utica Resident";
        const riderPhone = body.phone || "";

        // Find primary driver or fallback to Utica Pilot Driver
        const onlineDrivers = Object.values(globalDrivers).filter(d => d.online);
        const targetDriver = onlineDrivers.length > 0 ? onlineDrivers[0] : {
            wallet: "0xAce4362d791800c4729bC16A3A6a5d1359EC8926",
            name: "Utica Sovereign Driver Pool",
            phone: "315-797-0000"
        };

        const dispatchMsg = encodeURIComponent(`[WHEELS FOR UTICA DISPATCH] New $13 Trip:\nPickup: ${pickup}\nDropoff: ${dropoff}\nRider: ${riderName} (${riderPhone})\nFare: $5 Cash + 400 $RNR`);
        const blockscanChatUrl = `https://chat.blockscan.com/index?a=${targetDriver.wallet}&m=${dispatchMsg}`;
        const coinbaseMessengerUrl = `https://message.coinbase.com/`;

        const ride = {
            id: rideId,
            rider_name: riderName,
            phone: riderPhone,
            pickup: pickup,
            dropoff: dropoff,
            cash_fare: 5.00,
            rnr_subsidy: 8.00,
            rnr_tokens: 400,
            status: "PENDING",
            driver_wallet: null,
            driver_info: null,
            created_at: now,
            created_str: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
            dispatch_pipeline: {
                target_wallet: targetDriver.wallet,
                target_driver_name: targetDriver.name,
                blockscan_chat_url: blockscanChatUrl,
                coinbase_message_url: coinbaseMessengerUrl,
                dispatch_text: decodeURIComponent(dispatchMsg)
            }
        };

        globalRides.push(ride);
        return new Response(JSON.stringify({ ok: true, ride: ride }), { headers: CORS_HEADERS, status: 200 });
    }

    // 3. RIDE ACCEPT
    if (pathname.includes("/ride/accept")) {
        const rideId = body.ride_id;
        const driverWallet = (body.driver_wallet || "").trim().toLowerCase();
        const found = globalRides.find(r => r.id === rideId);
        if (!found) {
            return new Response(JSON.stringify({ error: "Ride not found" }), { headers: CORS_HEADERS, status: 404 });
        }
        found.status = "ACCEPTED";
        found.driver_wallet = driverWallet;
        found.driver_info = globalDrivers[driverWallet] || { wallet: driverWallet, name: "Community Driver" };
        found.accepted_at = now;
        return new Response(JSON.stringify({ ok: true, ride: found }), { headers: CORS_HEADERS, status: 200 });
    }

    // 4. RIDE COMPLETE
    if (pathname.includes("/ride/complete")) {
        const rideId = body.ride_id;
        const found = globalRides.find(r => r.id === rideId);
        if (!found) {
            return new Response(JSON.stringify({ error: "Ride not found" }), { headers: CORS_HEADERS, status: 404 });
        }
        found.status = "COMPLETED";
        found.completed_at = now;
        found.vault_tx_hash = `0x${Date.now().toString(16)}f4a8b29c91d84e`;
        return new Response(JSON.stringify({ ok: true, ride: found, tx_hash: found.vault_tx_hash }), { headers: CORS_HEADERS, status: 200 });
    }

    // 5. RIDE CANCEL
    if (pathname.includes("/ride/cancel")) {
        const rideId = body.ride_id;
        const found = globalRides.find(r => r.id === rideId);
        if (found) {
            found.status = "CANCELLED";
        }
        return new Response(JSON.stringify({ ok: true }), { headers: CORS_HEADERS, status: 200 });
    }

    // 6. COPAY REQUEST
    if (pathname.includes("/copay/request")) {
        const copayId = `COPAY-${Math.floor(Date.now() / 100) % 100000}`;
        const amount = Math.min(50.0, parseFloat(body.copay_amount || 15.0));
        const rnrGrant = Math.round(amount * 50);
        const record = {
            id: copayId,
            patient_name: body.patient_name || "Utica Resident",
            phone: body.phone || "",
            pharmacy: body.pharmacy || "Local Utica Pharmacy",
            medication: body.medication || "Maintenance Medication",
            copay_amount: amount,
            rnr_grant: rnrGrant,
            delivery_requested: Boolean(body.delivery_requested),
            delivery_address: body.delivery_address || "",
            status: "APPROVED",
            created_at: now,
            created_str: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
            tx_hash: `0x${Date.now().toString(16)}copay7c9b`
        };
        globalCopays.push(record);

        if (record.delivery_requested) {
            const medRide = {
                id: `RIDE-MED-${Math.floor(Date.now() / 100) % 10000}`,
                rider_name: `${record.patient_name} (Rx Delivery)`,
                phone: record.phone,
                pickup: record.pharmacy,
                dropoff: record.delivery_address || "Patient Residence",
                notes: `Pick up Rx: ${record.medication} for ${record.patient_name}`,
                cash_fare: 5.00,
                rnr_subsidy: 8.00,
                rnr_tokens: 400,
                status: "PENDING",
                driver_wallet: null,
                driver_info: null,
                created_at: now,
                created_str: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
            };
            globalRides.push(medRide);
        }

        return new Response(JSON.stringify({ ok: true, copay: record }), { headers: CORS_HEADERS, status: 200 });
    }

    // 7. FOOD MATCH REQUEST
    if (pathname.includes("/food/request")) {
        const foodId = `FOOD-${Math.floor(Date.now() / 100) % 100000}`;
        const cash = Math.max(5.0, Math.min(100.0, parseFloat(body.cash_amount || 25.0)));
        const matchUsd = cash;
        const rnrGrant = Math.round(matchUsd * 50);
        const totalPower = cash + matchUsd;
        const record = {
            id: foodId,
            family_name: body.family_name || "Utica Family",
            phone: body.phone || "",
            grocer: body.grocer || "Chanatry's Hometown Market",
            cash_amount: cash,
            rnr_match_usd: matchUsd,
            rnr_grant: rnrGrant,
            total_grocery_power: totalPower,
            delivery_requested: Boolean(body.delivery_requested),
            delivery_address: body.delivery_address || "",
            status: "APPROVED",
            created_at: now,
            created_str: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
            tx_hash: `0x${Date.now().toString(16)}food50e2`
        };
        globalFoodMatches.push(record);

        if (record.delivery_requested) {
            const grocRide = {
                id: `RIDE-GROCERY-${Math.floor(Date.now() / 100) % 10000}`,
                rider_name: `${record.family_name} (Grocery Box)`,
                phone: record.phone,
                pickup: record.grocer,
                dropoff: record.delivery_address || "Family Residence",
                notes: `Pick up $${totalPower.toFixed(0)} Family Food Box at ${record.grocer} for ${record.family_name}`,
                cash_fare: 5.00,
                rnr_subsidy: 8.00,
                rnr_tokens: 400,
                status: "PENDING",
                driver_wallet: null,
                driver_info: null,
                created_at: now,
                created_str: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
            };
            globalRides.push(grocRide);
        }

        return new Response(JSON.stringify({ ok: true, food_match: record }), { headers: CORS_HEADERS, status: 200 });
    }

    return new Response(JSON.stringify({ error: "Unknown route" }), { headers: CORS_HEADERS, status: 404 });
}
