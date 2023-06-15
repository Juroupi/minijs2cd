let n = function(x) {
    return x;
};

let f = function(a, b, c) {
    console.log(a, b, c);
};

f();
f(n(1));
f(1, n(2));
f(1, n(2), 3);
f(1, n(2), 3, n(4));