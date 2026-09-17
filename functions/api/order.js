export async function onRequestPost(context) {
    try {
        const body = await context.request.json();
        console.log("Heimdall Order Logged:", JSON.stringify(body));
        return new Response(JSON.stringify({
            success: true,
            message: "Order received on Base",
            order_id: body.tx_hash || String(Date.now())
        }), {
            headers: {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "POST, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type"
            },
            status: 200
        });
    } catch (err) {
        return new Response(JSON.stringify({ error: "Invalid order data" }), {
            headers: { "Content-Type": "application/json" },
            status: 400
        });
    }
}

export async function onRequestOptions() {
    return new Response(null, {
        headers: {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type"
        },
        status: 204
    });
}
