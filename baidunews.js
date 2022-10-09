var https = require('https');
const url = "https://top.baidu.com/board?tab=realtime";

https.get(url, function (res) {
    var html = '';

    res.setEncoding('utf-8');
    res.on('data', function (chunk) {
        html += chunk;
    });
    res.on('end', function () {
        const { JSDOM } = require("jsdom");
        const myJSDom = new JSDOM (html);
        const $ = require('jquery')(myJSDom.window);
        $(html).find(".title_dIF3B").each(function (i, val) {
            console.log(i + this.text);
        });
    });
});