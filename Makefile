.PRECIOUS: %.cd

minijs2cd.byte: src/*
	ocamlbuild src/minijs2cd.byte -r -use-menhir -menhir "menhir --explain --unused-tokens"

clean:
	rm -rf _build/*

clean_tests:
	rm -rf tests/*.cd

%.cd: %.js minijs2cd.byte
	./minijs2cd.byte $< $@

%.exec: tests/%.cd
	cduce $<