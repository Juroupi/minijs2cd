let p = { x : 6, y : 8 };

let q = { z : 15 };

let f = function() {
    q.x = 3;
    p.y = 5;
};

q.__proto__ = p;

f();

console.log("p:", p.x, p.y, p.z);
console.log("q:", q.x, q.y, q.z);