let p = {
    f : function() {
        console.log("ok");
    }
};

if (p != null) {

    if ("f" in p) {

        if (typeof p.f === "function") {
            p.f();
        }

        else {
            console.log("f is not a function");
        }
    }

    else {
        console.log("f is not in p");
    }
}

else {
    console.log("p is null");
}