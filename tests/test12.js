let p = { x : 1 };
let q = { y : 2, __proto__ : p };

console.log("q:", q.x, q.y);

p.x = 3;

console.log("q:", q.x, q.y);