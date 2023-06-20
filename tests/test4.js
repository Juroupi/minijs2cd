let print_bool = function(e) {
    if (e) {
        console.log("true");
    } else {
        console.log("false");
    }
};

print_bool(false);
print_bool(0);
print_bool(0n);
print_bool(null);
print_bool(undefined);
print_bool("");

console.log();

print_bool(true);
print_bool(1);
print_bool(function(){});
print_bool({});