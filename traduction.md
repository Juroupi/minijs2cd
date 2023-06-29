# Traduction JavaScript vers CDuce

## Présentation

Le but de ce stage est d'arriver à traduire un fragment de JavaScript en [CDuce](http://www.cduce.org). On se limite à une syntaxe très basique pour JavaScript qui prend en compte les objets et l'accès à leurs propriétés.

CDuce est un langage fonctionnel qui est adapté pour manipuler des données au format XML.
Les types de données de CDuce sont des ensembles sur lesquels on peut effectuer des unions, des intersections ou des différences. Par exemple, le type $\texttt{Int}$ correspond à l'ensemble $\N$ et le type $\texttt{Int \\ 5}$ correspond à $\{ x \in \N\ |\ x \not = 5\}$.
Le typage de CDuce est partiellement dynamique, c'est à dire que les types sont déterminés pendant l'exécution mais on peut restreindre les types possibles avec des annotations. Par exemple, une variable annotée avec le type $\texttt{Int}\ \texttt{|}\ \texttt{String}$, qui correspond à l'ensemble des entiers et des chaînes de caractères, a une valeur d'un de ces deux types, mais on ne sait pas forcément lequel avant l'exécution. Comme JavaScript est aussi un langage à typage dynamique, il sera plus facile de le traduire en CDuce qu'en un langage à typage statique comme OCaml.

JavaScript est très permissif, on peut faire beaucoup de choses avec et il y a trop de cas particuliers. Traduire l'ensemble de JavaScript en CDuce serait possible en suivant la référence, mais serait trop long et sans grand intérêt pour ce stage. On se limite donc à un fragment de JavaScript qui permet de faire des choses intéressantes, mais qui reste assez simple à traduire.

Comme le typage de JavaScript est dynamique, on peut écrire des programmes qui ne sont pas bien typés, mais qui vont lever une exception à l'exécution. Par exemple, l'expression `"a"()` va lever une exception car on ne peut pas appeler une chaîne de caractères.
Le but de cette traduction pourrait être de déterminer avant l'exécution, si un programme JavaScript va s'exécuter sans erreur dans tous les cas. On pourrait traduire un code JavaScript et ensuite utiliser des outils de CDuce pour vérifier si le code généré est correctement typé.

## Grammaires

### JavaScript

<span style="display:inline-block;width:26em;">$\texttt{e} ::=$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> **Expressions**</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{x}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Identifiant</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{s}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Littéral de chaîne de caractère</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{i}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Littéral de grand nombre entier</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{n}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Littéral de nombre</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{true}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Littéral true</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{false}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Littéral false</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{\{}\ \texttt{x}_1\texttt{:}\texttt{e}_1\texttt{,}{\color{gray}\cdots} \texttt{,}\ \texttt{x}_n\texttt{:}\texttt{e}_n\ \texttt{\}}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Littéral d'objet</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{function} \ \texttt{(}\ \texttt{x}_1\texttt{,}{\color{gray}\cdots}\texttt{,}\ \texttt{x}_n\ \texttt{)}\ \texttt{\{}\ \texttt{s}_1\ {\color{gray}\cdots}\ \texttt{s}_m\ \texttt{\}}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Littéral de fonction</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{e}_f\texttt{(}\ \texttt{e}_1\texttt{,}{\color{gray}\cdots} \texttt{,}\ \texttt{e}_n\ \texttt{)}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Appel de fonction</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{x = e}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Affectation</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{e.x}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Accès à une propriété</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{delete e.x}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Suppression d'une propriété</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{this}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> This</span>

<span style="display:inline-block;width:26em;">$\texttt{s} ::=$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> **Instructions**</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{e;}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Expression</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{let x = e;}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Déclaration de variable</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{if (e) s}_1\texttt{ else s}_2$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Instruction conditionnelle</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{while (e) s}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Boucle</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{return e;}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Retour de fonction</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{\{}\ \texttt{s}_1\ {\color{gray}\cdots}\ \texttt{s}_n\ \texttt{\};}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Bloc d'instructions</span>

<span style="display:inline-block;width:26em;">$\texttt{t} ::=$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> **Types**</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{boolean}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Booléen</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{bigint}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Grand nombre entier</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{number}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Nombre</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{string}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Chaîne de caractères</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{null}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Type nul</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{undefined}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Type pour les valeurs indéfinies</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{object}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Objet</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{function}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Fonction</span>

### CDuce

<span style="display:inline-block;width:26em;">$\texttt{e} ::=$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> **Expressions**</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{x}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Identifiant</span><span style="display:inline-block;width:26em;">$\quad|\quad \texttt{l}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Littéral</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \unicode{96}\texttt{x}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Atome</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{[}\ \texttt{x}_1\ {\color{gray}\cdots}\ \texttt{x}_n\ \texttt{]}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Littéral de séquence</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{\{}\ \texttt{x}_1\texttt{=}\ \texttt{e}_1\ {\color{gray}\cdots}\ \texttt{x}_n\texttt{=}\ \texttt{e}_n\ \texttt{\}}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Littéral d'enregistrement</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{e}_1\ \texttt{+ e}_2$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Concaténation d'enregistrements (priorité à $\texttt{e}_2$)</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{e}_1\ \texttt{\\ x}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Suppression d'un champ</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{fun x}\ \texttt{(}\ \texttt{x}_1\texttt{:}\texttt{t}_1\ \texttt{)}\ {\color{gray}\cdots}\ \texttt{(}\ \texttt{x}_n\texttt{:}\texttt{t}_n\ \texttt{)}\ \texttt{:}\ \texttt{t}_r\ \texttt{=}\ \ \texttt{e}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Littéral de fonction</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{e}_f\texttt{(}\ \texttt{e}_1\texttt{,}\ {\color{gray}\cdots}\ \texttt{,}\ \texttt{e}_n\ \texttt{)}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Appel de fonction</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \textbf{\texttt{ref}}\ \texttt{t}\ \texttt{e}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Construction de référence</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{e}_1\ \texttt{:= }\texttt{e}_2$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Affectation</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{!}\texttt{e}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Déréférencement</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{match e}_p\texttt{ with p}_1\ \texttt{->}\ \texttt{e}_1\ \texttt{|}\ {\color{gray}\cdots}\  \texttt{|}\ \texttt{p}_n\ \texttt{->}\ \texttt{e}_n$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Pattern matching</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{let x = e}_1\texttt{ in e}_2$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Définition locale</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{raise e}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Lever une exception</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{try e with p}_1\ \texttt{->}\ \texttt{e}_1\ \texttt{|}\ {\color{gray}\cdots}\  \texttt{|}\ \texttt{p}_n\ \texttt{->}\ \texttt{e}_n$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Capturer une exception</span>

<span style="display:inline-block;width:26em;">$\texttt{t} ::=$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> **Types**</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{Int}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Ensemble de tous les entiers</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{Float}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Nombre flottant</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{Char}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Ensemble de tous les caractères unicode</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \unicode{96}\texttt{x}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Atome</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{Bool}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Booléen (équivalent à $\unicode{96}\texttt{true}\ \texttt{|}\ \unicode{96}\texttt{false}$)</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{[t*]}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Séquence de taille quelconque</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{String}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Chaîne de caractères (équivalent à $\texttt{[Char*]}$)</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{ref t}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Référence</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{\{}\ \texttt{x}_1\texttt{=}\ \texttt{t}_1\ {\color{gray}\cdots}\ \ \texttt{x}_n\texttt{=}\ \texttt{t}_n\ \texttt{..\}}$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Enregistrement</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{t}_1\texttt{ -> t}_2$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Fonction</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{t}_1\texttt{ | t}_2$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Union</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{t}_1\texttt{ \unicode{38} t}_2$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> Intersection</span>

<span style="display:inline-block;width:26em;">$\texttt{p} ::=$</span><span style="display:inline-block;white-space: nowrap;width: 0em;"> **Patterns**</span>
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{x \unicode{38} t}$</span>Assure que $\texttt{x}$ est de type $\texttt{t}$
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{x \unicode{38} \{}\ \texttt{x}_1\ {\color{gray}\cdots}\ \ \texttt{x}_n\ \texttt{..\}}$</span>Extraction des champs d'un enregistrement
<span style="display:inline-block;width:26em;">$\quad|\quad \texttt{x \unicode{38} [}\ \texttt{x}_1\ {\color{gray}\cdots} \ \ \texttt{x}_n\ \texttt{]}$</span>Extraction des éléments du séquence

Les types CDuces peuvent être récursifs, par exemple un type de liste d'entiers peut s'écrire : $\texttt{type t = }\unicode{96}\texttt{nil | (Int, t)}$.

## Traduction

Les fonctions en <span style="color:rgb(145,80,110)">violet</span> sont des fonctions CDuce qui implémentent des fonctions détaillées dans la [référence JavaScript](https://262.ecma-international.org/13.0/). Leur code peut être complexe et n'est pas donnée ici.

### Types

#### Types de base

<span style="display:inline-block;width:7.5em;">	$[\![{\texttt{boolean}}]\!]_{\texttt t}$</span>$=\ \texttt{Bool}$
<span style="display:inline-block;width:7.5em;">	$[\![{\texttt{bigint}}]\!]_{\texttt t}$</span>$=\ \texttt{Int}$
<span style="display:inline-block;width:7.5em;">	$[\![{\texttt{number}}]\!]_{\texttt t}$</span>$=\ \texttt{Float}$
<span style="display:inline-block;width:7.5em;">	$[\![{\texttt{string}}]\!]_{\texttt t}$</span>$=\ \texttt{String}$

Les types de base correspondent exactement aux types de base de CDuce.

<span style="display:inline-block;width:8.8em;">	$[\![{\texttt{null}}]\!]_{\texttt t}$</span>$=\ \unicode{96}\texttt{null}$
<span style="display:inline-block;width:8.8em;">	$[\![{\texttt{undefined}}]\!]_{\texttt t}$</span>$=\ \unicode{96}\texttt{undefined}$

On représente les types $\texttt{null}$ et $\texttt{undefined}$ par les atomes du même nom.

#### Types objet

​	$[\![{\texttt{object}}]\!]_{\texttt t} = \texttt{Object} = \texttt{\{}$
​	$\quad\texttt{properties = ref \{..\}}$
​	$\quad\texttt{prototype = ref (Object | }\unicode{96}\texttt{null)}$
​	$\quad\texttt{..}$
​	$\ \texttt{\}}$

Le champ $\texttt{properties}$ est un enregistrement qui permet de stocker les propriétés de l'objet. Les propriétés peuvent avoir des noms calculés dynamiquement en JavaScript mais pas en CDuce : on ne peut accéder à un champ d'un enregistrement qu'avec le pattern matching et son nom, qui doit être connu à la compilation. On va donc se limiter aux noms de propriétés connus à la compilation.
Le champ $\texttt{prototype}$ permet de gérer l'héritage des propriétés : si un objet a un prototype, il va avoir accès aux propriétés de son prototype.

​	$[\![{\texttt{function}}]\!]_{\texttt t} = \texttt{FunctionObject} = \texttt{\{}$
​	$\quad\texttt{properties = ref \{..\}}$
​	$\quad\texttt{prototype = ref (Object | }\unicode{96}\texttt{null)}$
​	$\quad\texttt{call = Value -> [Value*] -> Value}$
​	$\quad\texttt{..}$
​	$\ \texttt{\}}$

Une fonction JavaScript est aussi un objet mais a un champ supplémentaire $\texttt{call}$, qui est une fonction CDuce qui contient son code réel. Elle prend en paramètre une valeur qui va être associée à $\texttt{this}$ et une séquence de valeurs qui seront les arguments réels de la fonction.

#### Type des valeurs

Une valeur JavaScript aura le type suivant en CDuce, qu'on va appeler $\texttt{Value}$ : $\texttt{Bool}\ \texttt{|}\ \texttt{Int}\ \texttt{|}\ \texttt{Float}\ \texttt{|}\ \texttt{String}\ \texttt{|}\ \unicode{96}\texttt{null}\ \texttt{|}\ \unicode{96}\texttt{undefined}\ \texttt{|}\ \texttt{Object}\ \texttt{|}\ \texttt{FunctionObject}$.

### Expressions

​	$[\![{\color{teal}\texttt{x}}]\!]_{\texttt e} = \texttt{!{\color{teal}x}}$

Comme les variables traduites par des références, il faut utiliser les opérateurs sur les références pour récupérer ou modifier leur valeur.

​	$[\![{\color{teal}\texttt{x}\ }\texttt{=}{\color{teal}\ \texttt{e}}]\!]_{\texttt e} =$
​		$\texttt{let tmp = }[\![{\color{teal}\texttt{e}}]\!]_{\texttt e}\texttt{ in}$
​		$\texttt{let \_ = }{\color{teal}\texttt{x}}\ \texttt{:= tmp in}$
​		$\texttt{tmp}$

Une expression d'affectation a la valeur de l'expression de droite, la modification de la référence ne suffit pas.

​	$[\![{\texttt{this}}]\!]_{\texttt e} = \texttt{this}$

On ne peut pas affecter une nouvelle valeur à $\texttt{this}$, donc on ne le représente pas comme une référence.

​	$[\![{\color{teal}\texttt{s}}]\!]_{\texttt e} = \texttt{{\color{teal}s}}$
​	$[\![{\color{teal}\texttt{i}}]\!]_{\texttt e} = \texttt{{\color{teal}i}}$

Les littéraux de grands entiers et de chaines de caractères sont laissés tels quels.

​	$[\![{\color{teal}\texttt{n}}]\!]_{\texttt e} = \texttt{float\_of "{\color{teal}n}"}$

Il n'y a pas de littéraux pour les nombres flottants en CDuce, on doit utiliser la fonction $\texttt{float\_of}$ pour les créer.

​	$[\![{\texttt{true}}]\!]_{\texttt e} = \unicode{96}\texttt{\texttt{true}}$
​	$[\![{\texttt{false}}]\!]_{\texttt e} = \unicode{96}\texttt{false}$

Les constantes booléennes sont traduites par les atomes correspondants.

​	$[\![{\color{teal}\texttt{e}}\texttt{.}{\color{teal}\texttt{x}}]\!]_{\texttt e} = \texttt{{\color{rgb(145,80,110)}get\_property} }[\![{\color{teal}\texttt{e}}]\!]_{\texttt e}\ [\![{\color{teal}\texttt{x}}]\!]_{\texttt p}$

Pour accéder à une propriété en JavaScript, il faut d'abord chercher la propriété dans les propriétés de l'objet. Si la propriété n'est pas trouvée, il faut chercher dans les propriétés du prototype de l'objet et ainsi de suite jusqu'à la trouver ou arriver à un objet dont le prototype est $\texttt{null}$. Si la propriété est trouvée, on retourne la valeur qui lui est associée, sinon on retourne $\texttt{undefined}$. La fonction $\texttt{{\color{rgb(145,80,110)}get\_property}}$ implémente ce comportement ([10.1.8](https://262.ecma-international.org/13.0/#sec-ordinary-object-internal-methods-and-internal-slots-get-p-receiver)).
Toutes les fonctions qui manipulent les propriétés d'un objet doivent s'assurer qu'on leur passe bien un objet. Pour cela, elles utilisent la fonction $\texttt{\color{rgb(145,80,110)}to\_object}$ ([7.1.18](https://262.ecma-international.org/13.0/#sec-toobject)) qui va convertir une valeur en objet. Seules les valeurs $\texttt{null}$ et $\texttt{undefined}$ ne peuvent pas être converties en objet, une exception $\texttt{TypeError}$ est levée dans ce cas. Les valeurs de type $\texttt{boolean}$, $\texttt{bigint}$, $\texttt{number}$ et $\texttt{string}$ sont converties respectivement en objet $\texttt{BooleanObject}$, $\texttt{BigIntObject}$, $\texttt{NumberObject}$ et $\texttt{StringObject}$, qui sont des objets avec un champ supplémentaire $\texttt{data}$ qui contient leur valeur primitive. Les objets sont laissés tels quels.

​	$[\![{\texttt{delete {\color{teal}e}.{\color{teal}x}}}]\!]_{\texttt e} = \texttt{{\color{rgb(145,80,110)}delete\_property} }[\![{\color{teal}\texttt{e}}]\!]_{\texttt e}\ [\![{\color{teal}\texttt{x}}]\!]_{\texttt p}$

La fonction $\texttt{{\color{rgb(145,80,110)}delete\_property}}$ ([10.1.10](https://262.ecma-international.org/13.0/#sec-ordinary-object-internal-methods-and-internal-slots-delete-p)) supprime la propriété si elle existe dans l'objet et ne fait rien sinon.

​	$[\![{{\color{teal}\texttt{e}_1}\texttt{.\color{teal}x}\ \texttt{=}\ {\color{teal}\texttt{e}_2}}]\!]_{\texttt e} = \texttt{{\color{rgb(145,80,110)}set\_property} }[\![{\color{teal}\texttt{e}_1}]\!]_{\texttt e}\ \ [\![{\color{teal}\texttt{x}}]\!]_{\texttt p}\ \ [\![{\color{teal}\texttt{e}_2}]\!]_{\texttt e}$

Si la propriété existe dans l'objet, on modifie sa valeur. Sinon, on la crée. C'est la fonction $\texttt{{\color{rgb(145,80,110)}set\_property}}$ qui implémente ce comportement ([10.1.9](https://262.ecma-international.org/13.0/#sec-ordinary-object-internal-methods-and-internal-slots-set-p-v-receiver)).

​	$[\![{{\color{teal}\texttt{e}_f}\texttt{(}\ {\color{teal}\texttt{e}_1}\texttt{,}\ {\color{gray}\cdots}\ \texttt{,}\ {\color{teal}\texttt{e}_n}\ \texttt{)}}]\!]_{\texttt e} = \ \texttt{{\color{rgb(145,80,110)}call} }[\![{\color{teal}\texttt{e}_f}]\!]_{\texttt e}\texttt{ {\color{rgb(145,80,110)}global\_this} [}\ [\![{\color{teal}\texttt{e}_1}]\!]_{\texttt e}\ {\color{gray}\cdots}\ [\![{\color{teal}\texttt{e}_n}]\!]_{\texttt e}\ \texttt{]}$

La fonction $\texttt{{\color{rgb(145,80,110)}call}}$ appelle la fonction $\texttt{call}$ de l'objet fonction avec le $\texttt{this}$ et la séquence de paramètres. Si ce n'est pas un objet fonction et qu'on ne peut donc pas l'appeler, une exception $\texttt{TypeError}$ est levée. On associe l'objet $\texttt{{\color{rgb(145,80,110)}global\_this}}$ ([19](https://262.ecma-international.org/13.0/#sec-global-object)) au $\texttt{this}$ de la fonction. Cet objet est l'objet global de l'environnement d'exécution.

​	$[\![{\texttt{{\color{teal}e}.{\color{teal}x}}\texttt{(}\ {\color{teal}\texttt{e}_1}\texttt{,}\ {\color{gray}\cdots}\ \texttt{,}\ {\color{teal}\texttt{e}_n}\ \texttt{)}}]\!]_{\texttt e} =\ \texttt{let o = }[\![{\color{teal}\texttt{e}}]\!]_{\texttt e}\texttt{ in {\color{rgb(145,80,110)}call} (}\texttt{{\color{rgb(145,80,110)}get\_property} o }[\![{\color{teal}\texttt{x}}]\!]_{\texttt p}\texttt{) o [}\ [\![{\color{teal}\texttt{e}_1}]\!]_{\texttt e}\ {\color{gray}\cdots}\ [\![{\color{teal}\texttt{e}_n}]\!]_{\texttt e}\ \texttt{]}$

L'appel d'une méthode est similaire à l'appel de fonction sur une propriété mais on associe l'objet sur lequel on a accédé à la propriété au $\texttt{this}$ de la fonction.

​	$[\![{\texttt{\{}\ {\color{teal}\texttt{x}_1}\texttt{:}{\color{teal}\texttt{e}_1}\texttt{,}\ {\color{gray}\cdots}\ \texttt{,}\ {\color{teal}\texttt{x}_n}\texttt{:}{\color{teal}\texttt{e}_n}\ \texttt{\}}}]\!]_{\texttt e} = \texttt{\{}$
​	$\quad \texttt{properties = ref \{..\} } \texttt{\{}\ {\color{teal}\texttt{x}_1}\texttt{=}\ [\![{\color{teal}\texttt{e}_1}]\!]_{\texttt e}\ {\color{gray}\cdots}\ {\color{teal}\texttt{x}_n}\texttt{=}\ [\![{\color{teal}\texttt{e}_n}]\!]_{\texttt e}\ \texttt{\}}$
​	$\quad \texttt{prototype = ref (Object | }\unicode{96}\texttt{null) {\color{rgb(145,80,110)}object\_prototype})} $
​	$\texttt{\}}$

$\texttt{{\color{rgb(145,80,110)}object\_prototype}}$ ([20.1.3](https://262.ecma-international.org/13.0/#sec-properties-of-the-object-prototype-object)) est le prototype donné par défaut aux objets. Les objets de base héritent donc des propriétés de cet objet. Cet objet a notamment une propriété $\texttt{\_\_proto\_\_}$ ([20.1.3.8](https://262.ecma-international.org/13.0/#sec-object.prototype.__proto__)) qui a un comportement spécial qui permet de modifier le champ $\texttt{prototype}$ en même temps qu'on la modifie. C'est comme ça qu'on peut modifier le prototype d'un objet.

​	$[\![{\texttt{function} \ \texttt{(}\ {\color{teal}\texttt{x}_1}\texttt{,}\ {\color{gray}\cdots}\ \texttt{,}\ {\color{teal}\texttt{x}_n}\ \texttt{)}\ \texttt{\{}\ {\color{teal}\texttt{s}_1}\ {\color{gray}\cdots}\ {\color{teal}\texttt{s}_m}\ \texttt{\}}}]\!]_{\texttt e} = \texttt{\{}$
​	$\quad \texttt{properties = ref \{..\} \{\};}$
​	$\quad \texttt{prototype = ref (Object | }\unicode{96}\texttt{null) {\color{rgb(145,80,110)}function\_prototype});} $
​	$\quad \texttt{call = fun (this : Value) (params : [Value*]) : Value =}$
​	$\quad\quad\texttt{let f = fun (}\ {\color{teal}\texttt{x}_1}\texttt{:}\ \texttt{ref Value}\ \texttt{)}\ {\color{gray}\cdots}\ \texttt{(}\ {\color{teal}\texttt{x}_n}\texttt{:}\ \texttt{ref Value}\ \texttt{) : Value =}$
​	$\quad\quad\quad\texttt{try }[\![{\color{teal} \texttt{s}_1\ {\color{gray}\cdots}\ \texttt{s}_m }]\!]_{\texttt s}\texttt{ with (}\unicode{96}\texttt{return, r \& Value) -> r}$
​	$\quad\quad\texttt{in}$
​	$\quad\quad\texttt{match params with}$
​	$\quad\quad\texttt{| [] -> f (ref Value }\unicode{96}\texttt{undefined}{\color{teal}_1}\texttt{)}\ {\color{gray}\cdots}\ \texttt{(ref Value }\unicode{96}\texttt{undefined}{\color{teal}_n}\texttt{)}$
​	$\quad\quad\texttt{| [ {\color{teal}x}}{\color{teal}_1}\texttt{ ] -> f (ref Value {\color{teal}x}}{\color{teal}_1}\texttt{)}\ {\color{gray}\cdots}\ \texttt{(ref Value }\unicode{96}\texttt{undefined}{\color{teal}_n}\texttt{)}$
​	$\quad\quad\texttt{| [ {\color{teal}x}}{\color{teal}_1}\texttt{\color{teal} x}{\color{teal}_2} \texttt{ ] -> f (ref Value {\color{teal}x}}{\color{teal}_1}\texttt{)} \texttt{ (ref Value {\color{teal}x}}{\color{teal}_2}\texttt{)}\ {\color{gray}\cdots}\ \texttt{(ref Value }\unicode{96}\texttt{undefined}{\color{teal}_n}\texttt{)}$
​	$\quad\quad\texttt{| }{\color{gray}\cdots}$
​	$\quad\quad\texttt{| [ {\color{teal}x}}{\color{teal}_1}\ {\color{gray}\cdots}\ \ \texttt{{\color{teal}x}}{\color{teal}_n}\texttt{ \_* ] -> f (ref Value {\color{teal}x}}{\color{teal}_1}\texttt{)}\ {\color{gray}\cdots}\ \texttt{(ref Value {\color{teal}x}}{\color{teal}_n}\texttt{)}$
​	$\texttt{\}}$

Une fonction est un objet mais son prototype par défaut est $\texttt{{\color{rgb(145,80,110)}function\_prototype}}$ ([20.2.3](https://262.ecma-international.org/13.0/#sec-properties-of-the-function-prototype-object)).
En JavaScript, on peut passer autant de paramètres que l'on veut à une fonction, peu importe le nombre de paramètres attendus. Les paramètres non fournis sont alors initialisés à $\texttt{undefined}$ et les paramètres en trop sont ignorés. La fonction $\texttt{call}$ reçoit la séquence de paramètres passés lors de l'appel et utilise un pattern matching sur cette séquence pour appeler la vraie fonction avec les bonnes valeurs en paramètres. Le pattern matching est généré en fonction du nombre de paramètres réellement attendus.
Les instructions $\texttt{return}$ sont traduites par une levée d'exception avec la valeur à retourner. La fonction $\texttt{call}$ capture cette exception et retourne la valeur.

### Opérateurs sur une propriété

​	$[\![{\color{teal}\texttt{x}}]\!]_{\texttt p} = \texttt{\{}$
​	$\quad\texttt{get =}$
​	$\quad\quad\texttt{fun (obj : Object) : (Value | }\unicode{96}\texttt{nil) =}$
​	$\quad\quad\quad\texttt{match !(obj.properties) with}$
​	$\quad\quad\quad\texttt{| \{ {\color{teal}\texttt{x}} = {\color{teal}\texttt{x}} \& Property ..\} -> {\color{teal}\texttt{x}}}$
​	$\quad\quad\quad\texttt{| \_ -> }\unicode{96}\texttt{nil}$
​	$\quad\texttt{set =}$
​	$\quad\quad\texttt{fun (obj : Object) (property : Value) : [] =}$
​	$\quad\quad\quad\texttt{obj.properties := !(obj.properties) + \{ {\color{teal}\texttt{x}} = property \}}$
​	$\quad\texttt{delete =}$
​	$\quad\quad\texttt{fun (obj : Object) : [] =}$
​	$\quad\quad\quad\texttt{obj.properties := !(obj.properties) \\ {\color{teal}\texttt{x}}}$
​	$\ \texttt{\}}$

Il faudrait pouvoir passer en paramètre un pattern aux fonctions comme $\texttt{{\color{rgb(145,80,110)}get\_property}}$ ou $\texttt{{\color{rgb(145,80,110)}set\_property}}$ pour qu'elles puissent manipuler des propriétés. Pour cela, pour chaque nom de propriété utilisé, on va générer des primitives de manipulation du champ associé, qui vont pouvoir être passées en paramètre aux fonctions plus complexes :

- $\texttt{get}$ : récupère la valeur de la propriété.
- $\texttt{set}$ : modifie la valeur de la propriété et l'ajoute si elle n'existe pas.
- $\texttt{delete}$ : supprime la propriété.

On utilise ici $\texttt{[]}$ pour désigner le type vide, qui n'a pas de valeur, comme $\texttt{unit}$ en OCaml.

### Instructions

​	$[\![\ ]\!]_{\texttt s} = \unicode{96}\texttt{undefined}$

Une fonction JavaScript renvoie $\texttt{undefined}$ par défaut, donc la traduction d'une liste d'instructions vaut $\unicode{96}\texttt{undefined}$.

​	$[\![{\texttt{{\color{teal}e};}\ {\color{gray}\cdots}\ }]\!]_{\texttt s} = \texttt{let \_ = } [\![{\color{teal}\texttt{e}}]\!]_{\texttt e} \texttt{ in } [\![{\color{gray}\cdots}]\!]_{\texttt s}$

On utilise le "$\texttt{\_}$" pour ignorer la valeur de l'expression.

​	$[\![{\texttt{let {\color{teal}x} = {\color{teal}e};}}\ {\color{gray}\cdots}\ ]\!]_{\texttt s} =$
<span style="display:inline-block;width:24em;">		$\texttt{let {\color{teal}x} = ref Value }\unicode{96}\texttt{undefined in}$</span>$\rightarrow\ $ Déclaration, déplacée au début du bloc
<span style="display:inline-block;width:24em;">		$\texttt{let \_ = {\color{teal}x} := } [\![{\color{teal}\texttt{e}}]\!]_{\texttt e} \texttt{ in } [\![{\color{gray}\cdots}]\!]_{\texttt s}$</span>$\rightarrow\ $ Initialisation

En JavaScript, les déclarations de variables avec $\texttt{let}$ sont remontées au début de leur bloc. Si on essaye de récupérer la valeur d'une variable avant son initialisation, une exception $\texttt{ReferenceError}$ est levée. Deux déclarations ne peuvent pas avoir le même nom dans une même bloc.

​	$[\![{\texttt{if ({\color{teal}e}) {\color{teal}s}}{\color{teal}_1}\texttt{ else {\color{teal}s}}{\color{teal}_2}}\texttt{ }{\color{gray}\cdots}]\!]_{\texttt s} =$
​	$\quad\texttt{let \_ = }$
​	$\quad\quad\texttt{match } [\![{\color{teal}\texttt{e}}]\!]_{\texttt e} \texttt{ with}$
​	$\quad\quad\texttt{| \_ \& (}\unicode{96}\texttt{false | }\unicode{96}\texttt{undefined | }\unicode{96}\texttt{null | "" | 0) -> } [\![{\color{teal}\texttt{s}_2}]\!]_{\texttt s}$
​	$\quad\quad\texttt{| \_ -> } [\![{\color{teal}\texttt{s}_1}]\!]_{\texttt s}$
​	$\quad\texttt{in } [\![{\color{gray}\cdots}]\!]_{\texttt s}$

En JavaScript, les valeurs $\unicode{96}\texttt{false}$, $\unicode{96}\texttt{undefined}$, $\unicode{96}\texttt{null}$, $\texttt{""}$ (chaîne de caractères vide) et $\texttt{0}$ (entier) sont considérées comme fausses. Les valeurs $\texttt{NaN}$ et $\texttt{0}$ (flottant) doivent aussi être considérées comme fausses mais ne sont pas prises en compte ici. Les autres valeurs sont considérées comme vraies ([7.1.2](https://262.ecma-international.org/13.0/#sec-toboolean)). On va utiliser la fonction $\texttt{\color{rgb(145,80,110)}to\_boolean}$ pour convertir une valeur en booléen de cette façon.

​	$[\![{\texttt{while ({\color{teal}e}) {\color{teal}s }}}{\color{gray}\cdots}]\!]_{\texttt s} =$
​	$\quad\texttt{let \_ = (}$
​	$\quad\quad\texttt{(fun loop (\_ : []) : [] =}$
​	$\quad\quad\quad\texttt{match \color{rgb(145,80,110)}to\_boolean } [\![{\color{teal}\texttt{e}}]\!]_{\texttt e} \texttt{ with}$
​	$\quad\quad\quad\texttt{| }\unicode{96}\texttt{true -> let \_ = } [\![{\color{teal}\texttt{s}}]\!]_{\texttt s}\texttt{ in loop []}$
​	$\quad\quad\quad\texttt{| }\unicode{96}\texttt{false -> []}$
​	$\quad\quad\texttt{) []}$
​	$\quad\texttt{) in } [\![{\color{gray}\cdots}]\!]_{\texttt s}$

On transforme une boucle en fonction récursive qui s'appelle elle-même tant que la condition est vraie. On utilise le type vide $\texttt{[]}$ comme valeur de retour et comme paramètre de la fonction récursive.

​	$[\![{\texttt{return {\color{teal}e};}}\ {\color{gray}\cdots}\ ]\!]_{\texttt s} = \texttt{raise (}\unicode{96}\texttt{return, }[\![{\color{teal}\texttt{e}}]\!]_{\texttt e}\texttt{)}$

On lève une exception avec l'atome $\unicode{96}\texttt{return}$ pour simuler une instruction $\texttt{return}$ sans gêner les autres exceptions.

​	$[\![{\texttt{\{}\ {\color{teal}\texttt{s}_1}\ {\color{gray}\cdots}\ {\color{teal}\texttt{s}_n}\ \texttt{\};}\ {\color{gray}\cdots}}]\!]_\texttt{s} = \texttt{let \_ = (} [\![{\color{teal}\texttt{s}_1\ {\color{gray}\cdots}\ \texttt{s}_n}]\!]_\texttt{s} \texttt{) in } [\![{\color{gray}\cdots}]\!]_{\texttt s}$

Toutes les déclarations du bloc sont remontées au début de celui-ci et on utilise des parenthèses pour limiter leur portée.
