let p = {
    f : function() {
        console.log("ok");
    }
};

if (/* p != null && */ "f" in p /* && typeof p.f == "function" */) {
    p.f();
}
else {
    console.log("error");
}