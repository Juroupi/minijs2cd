let p = {
    x : 5,
    f : function(x) {
        this.x = x;
    }
};

console.log("p.x :", p.x);

p.f(10);

console.log("p.x :", p.x);

let f = p.f;

f(20);

console.log("p.x :", p.x);
console.log("globalThis.x :", globalThis.x);