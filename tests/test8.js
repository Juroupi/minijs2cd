let p = { x : 5, y : undefined };
let q = { z : 9 };

q.__proto__ = p;

console.log("w:", "w" in q);
console.log("x:", "x" in q);
console.log("y:", "y" in q);
console.log("z:", "z" in q);