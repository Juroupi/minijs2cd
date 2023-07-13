# minijs2cd

## Compilation

```bash
make
```

## Utilisation

```bash
./minijs2cd <fichier javascript> <fichier cduce>
```

## Tests

On peut traduire un fichier dans `tests/` et exécuter le fichier généré avec la commande :

```bash
make test<n>.exec
```

Exemple : `make test3.exec` va traduire `tests/test3.js` en `tests/test3.cd` et l'exécuter.

Il faut installer `cduce` ([https://www.cduce.org](https://www.cduce.org)) pour pouvoir exécuter les fichiers `.cd`.
