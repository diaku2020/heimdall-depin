export async function onRequestGet() {
    return new Response(JSON.stringify({
        status: "closed",
        message: "Telemetry stream available via local bridge on COM10/USB-C"
    }), {
        headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
        },
        status: 200
    });
}
