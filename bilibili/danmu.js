var brotli = require('brotli');
var WebSocket = require('ws');

const args = process.argv.slice(2);
const ws = new WebSocket('wss://broadcastlv.chat.bilibili.com:443/sub');
var certification = {
    "uid":0,
    "roomid":parseInt(args[0]),
    "protover":3,
    "platform":"web",
    "type":2,
    "key":""
}

function pack_certification(certification) {
    const body = Buffer.from(certification);
    const head = Buffer.alloc(16);
    head.writeUInt32BE(16 + body.length, 0);
    head.writeUInt16BE(16, 4);
    head.writeUInt16BE(1, 6);
    head.writeUInt32BE(7, 8);
    head.writeUInt32BE(1, 12);
    return Buffer.concat([head, body]);
}

ws.on('open', function(e) {
    ws.send(pack_certification(JSON.stringify(certification)));
    timer = setInterval(function() {
        let heatbeating = Buffer.alloc(16);
        heatbeating.writeUInt32BE(0, 0);
        heatbeating.writeUInt16BE(16, 4);
        heatbeating.writeUInt16BE(1, 6);
        heatbeating.writeUInt32BE(2, 8);
        heatbeating.writeUInt32BE(1, 12);
        ws.send(heatbeating);
    }, 30000);
});

ws.on('message', function(data) {
    var package_len = data.readInt32BE(0);
    var head_len = data.readInt16BE(4);
    var version = data.readInt16BE(6);
    var operation = data.readInt32BE(8);
    var sequence = data.readInt32BE(12);
    if (operation == 5) {
        if (version == 3) {
            var body = data.slice(16);
            var dec_body = Buffer.from(brotli.decompress(body)).toString();
            const group = dec_body.split(/[\x00-\x1f]+/);

            group.forEach(item => {
                try {
                    let json_obj = JSON.parse(item);
                    if (json_obj.cmd == "DANMU_MSG") {
                        console.log(json_obj.info[1]);
                    }
                } catch(e) {}
            });
        }
    }
});

ws.on ('close', function() {
    if (timer != null)
        clearInterval(timer);
});

ws.on('error', function() {
    console.log("error.")
});
