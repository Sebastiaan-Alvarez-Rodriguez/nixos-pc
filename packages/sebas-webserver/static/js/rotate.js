function shift(str_raw, amount) {
    var output = ''
    for (var i = 0; i < str_raw.length; i++) {
        output += String.fromCharCode(str_raw.charCodeAt(i) + amount);
    }
    return output;
};