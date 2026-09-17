export async function onRequestGet() {
    return new Response(JSON.stringify({
        status: "simulator",
        source: "virtual_mode",
        message: "Heimdall Cloudflare Pages demo active"
    }), {
        headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
        },
        status: 200
    });
}
