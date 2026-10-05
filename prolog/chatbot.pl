:- encoding(utf8).
% =====================================================================
%  CHATBOT PROLOG: Vinos y cepas de Chile
%
%  Flujo:  texto -> tokens -> entidades + palabras clave -> intención
%          -> consulta a la base de conocimiento -> respuesta en texto
%
%  Uso en consola:   swipl chatbot.pl   y luego   ?- iniciar.
%  Uso desde Python: el backend ejecuta "main" y envía la pregunta
%                    por la entrada estándar (stdin).
% =====================================================================

:- ensure_loaded(base_conocimiento).

% ---------------------------------------------------------------------
% 1. PUNTOS DE ENTRADA
% ---------------------------------------------------------------------

% responder(+Texto, -Respuesta): siempre tiene éxito.
responder(Texto, Respuesta) :-
    tokenizar(Texto, Tokens),
    (   Tokens == []
    ->  Respuesta = 'Escribe una pregunta sobre vinos y cepas de Chile.'
    ;   once(intencion(Tokens, R))
    ->  Respuesta = R
    ;   Respuesta = 'Reconocí tu pregunta, pero me faltan datos en la base de conocimiento para responderla.'
    ).

% Modo consola interactivo.
iniciar :-
    set_stream(user_input, encoding(utf8)),
    set_stream(user_output, encoding(utf8)),
    writeln('Bot: ¡Hola! Pregúntame sobre vinos y cepas de Chile (escribe "salir" para terminar).'),
    bucle.

bucle :-
    write('Tú: '), flush_output,
    read_line_to_string(user_input, Linea),
    (   ( Linea == end_of_file ; Linea == "salir" )
    ->  writeln('Bot: ¡Salud! Hasta pronto.')
    ;   responder(Linea, R),
        format("Bot: ~w~n", [R]),
        bucle
    ).

% Modo usado por Python: lee la pregunta desde stdin e imprime la respuesta.
main :-
    set_stream(user_input, encoding(utf8)),
    set_stream(user_output, encoding(utf8)),
    read_string(user_input, _, Pregunta),
    responder(Pregunta, R),
    format("~w~n", [R]).

% ---------------------------------------------------------------------
% 2. PROCESAMIENTO DEL TEXTO
% ---------------------------------------------------------------------

% tokenizar(+Texto, -Tokens): minúsculas, sin tildes ni puntuación.
tokenizar(Texto, Tokens) :-
    string_lower(Texto, Minus),
    string_chars(Minus, Chars),
    maplist(sin_tilde, Chars, Limpios),
    string_chars(Limpio, Limpios),
    split_string(Limpio, " ,;\t\n", ".?!¿¡:()\"'", Partes),
    exclude(==(""), Partes, Palabras),
    maplist(string_atomo, Palabras, Tokens0),
    desambiguar(Tokens0, Tokens).

string_atomo(S, A) :- atom_string(A, S).

sin_tilde('á', a) :- !.
sin_tilde('é', e) :- !.
sin_tilde('í', i) :- !.
sin_tilde('ó', o) :- !.
sin_tilde('ú', u) :- !.
sin_tilde('à', a) :- !.
sin_tilde('è', e) :- !.
sin_tilde('ì', i) :- !.
sin_tilde('ò', o) :- !.
sin_tilde('ü', u) :- !.
sin_tilde('ñ', n) :- !.
sin_tilde(C, C).

% "país" puede ser la cepa País o la palabra "país" (nación).
% Si va precedida de estas palabras se trata como nación.
desambiguar([], []).
desambiguar([P, pais | R], [P, nacion | R2]) :-
    memberchk(P, [que, cada, mi, nuestro, este, otro, ese]), !,
    desambiguar(R, R2).
desambiguar([T | R], [T | R2]) :- desambiguar(R, R2).

% ---------------------------------------------------------------------
% 3. RECONOCIMIENTO DE ENTIDADES
% ---------------------------------------------------------------------

% Tipos de entidad que el bot reconoce.
es_tipo(cepa, E)  :- cepa(E, _).
es_tipo(valle, E) :- valle(E, _, _, _).
es_tipo(plato, E) :- marida(_, E).
es_tipo(pais, E)  :- origen(_, E).

% Formas de escribir una entidad: su propio nombre (cabernet_sauvignon
% -> [cabernet, sauvignon]) o un sinónimo. Así, un hecho nuevo en la base
% de conocimiento se reconoce automáticamente sin tocar este archivo.
patron(E, Palabras) :-
    es_tipo(_, E),
    atomic_list_concat(Palabras, '_', E).
patron(E, Palabras) :-
    sinonimo(Palabras, E).

sinonimo([cabernet], cabernet_sauvignon).
sinonimo([pinot], pinot_noir).
sinonimo([moscatel], moscatel_de_alejandria).
sinonimo([gewurz], gewurztraminer).
sinonimo([san, antonio], leyda).
sinonimo([choclo], pastel_de_choclo).
sinonimo([machas], machas_a_la_parmesana).
sinonimo([marisco], mariscos).
sinonimo([pasta], pastas).
sinonimo([empanada], empanadas).
sinonimo([postre], postres).
sinonimo([queso], quesos_maduros).
sinonimo([quesos], quesos_maduros).
sinonimo([parrilla], asado).
sinonimo([parrillada], asado).
sinonimo([carnes, rojas], carne_roja).
sinonimo([frances], francia).
sinonimo([francesa], francia).
sinonimo([francesas], francia).
sinonimo([franceses], francia).
sinonimo([espanola], espana).
sinonimo([espanolas], espana).
sinonimo([espanoles], espana).
sinonimo([aleman], alemania).
sinonimo([alemana], alemania).
sinonimo([alemanas], alemania).
sinonimo([italiana], italia).

% menciona(+Tokens, ?Tipo, ?Entidad): la entidad aparece en la pregunta.
menciona(Tokens, Tipo, E) :-
    patron(E, Palabras),
    es_tipo(Tipo, E),
    sublista(Palabras, Tokens).

sublista(Sub, Lista) :-
    append(_, Resto, Lista),
    append(Sub, _, Resto), !.

% entidades(+Tokens, +Tipo, -Lista): entidades distintas de ese tipo.
entidades(Tokens, Tipo, Lista) :-
    findall(E, menciona(Tokens, Tipo, E), L),
    sort(L, Lista).

% alguna(+Tokens, +PalabrasClave): aparece al menos una palabra clave.
alguna(Tokens, Claves) :-
    member(C, Claves), memberchk(C, Tokens), !.

% ---------------------------------------------------------------------
% 4. INTENCIONES (se prueban en orden; la primera que calza responde)
% ---------------------------------------------------------------------

intencion(T, R) :-
    \+ menciona(T, _, _), alguna(T, [hola, buenas, buenos, saludos]), !,
    R = '¡Hola! Soy un sommelier virtual de vinos chilenos. Pregúntame por cepas, valles, maridajes u orígenes.'.
intencion(T, R) :-
    alguna(T, [gracias]), !,
    R = '¡De nada! ¡Salud!'.
intencion(T, R) :-
    \+ menciona(T, _, _), alguna(T, [ayuda, puedes, sabes]), !,
    R = 'Puedo responder sobre: cepas (origen, cuerpo, aromas, temperatura), valles (clima, región, zona, cepas), maridajes y comparaciones entre cepas o valles.'.

% --- Con platos ---
intencion(T, R) :-
    entidades(T, plato, [P | _]), entidades(T, cepa, [C | _]), !,
    resp_cepa_con_plato(C, P, R).
intencion(T, R) :-
    entidades(T, plato, [P | _]), !,
    resp_maridaje_plato(P, R).

% --- Cepa y valle juntos: ¿se cultiva? ---
intencion(T, R) :-
    entidades(T, cepa, [C | _]), entidades(T, valle, [V | _]), !,
    resp_cultiva(V, C, R).

% --- Comparaciones ---
intencion(T, R) :-
    entidades(T, valle, [V1, V2 | _]), !,
    resp_valles_comunes(V1, V2, R).
intencion(T, R) :-
    entidades(T, cepa, [C1, C2 | _]), !,
    resp_comparar_cepas(C1, C2, R).

% --- País de origen ---
intencion(T, R) :-
    entidades(T, pais, [P | _]), \+ menciona(T, cepa, _), !,
    resp_cepas_de_pais(P, R).

% --- Una cepa ---
intencion(T, R) :-
    entidades(T, cepa, [C]), !,
    intencion_cepa(T, C, R).

% --- Un valle ---
intencion(T, R) :-
    entidades(T, valle, [V]), !,
    intencion_valle(T, V, R).

% --- Preguntas generales (sin entidades) ---
intencion(T, R) :-
    alguna(T, [emblematica, emblematico, emblema, insignia, representativa]), !,
    cepa_emblematica(C), mostrar(C, N),
    format(atom(R), 'La cepa emblemática de Chile es ~w.', [N]).
intencion(T, R) :-
    alguna(T, [plantada, plantadas, cultivada, cultivadas, popular]), !,
    cepa_mas_plantada(C), mostrar(C, N),
    format(atom(R), 'La cepa más plantada de Chile es ~w.', [N]).
intencion(T, R) :-
    alguna(T, [patrimonial, patrimoniales]), !,
    findall(C, cepa_patrimonial(C), Cs),
    lista_texto(Cs, L),
    format(atom(R), 'Las cepas patrimoniales de Chile son: ~w.', [L]).
intencion(T, R) :-
    alguna(T, [colonial, coloniales, colonia, conquistadores]), !,
    findall(C, cepa_colonial(C), Cs),
    lista_texto(Cs, L),
    format(atom(R), 'Las cepas de origen español, llegadas en la época colonial, son: ~w.', [L]).
intencion(T, R) :-
    alguna(T, [frio, fria, frios, frias, fresco, fresca]), !,
    resp_clima_frio(T, R).
intencion(T, R) :-
    palabra_zona(T, Z), !,
    findall(V, zona(V, Z), Vs),
    lista_texto(Vs, L),
    format(atom(R), 'Los valles de la zona ~w son: ~w.', [Z, L]).
intencion(T, R) :-
    palabra_color(T, Color), palabra_cuerpo(T, Cuerpo), !,
    findall(C, (cepa(C, Color), cuerpo(C, Cuerpo)), Cs),
    resp_lista_filtrada(Cs, Color, Cuerpo, R).
intencion(T, R) :-
    palabra_color(T, Color), \+ alguna(T, [temperatura, grados, servir, sirve]), !,
    findall(C, cepa(C, Color), Cs),
    lista_texto(Cs, L),
    format(atom(R), 'Las cepas de vino ~w son: ~w.', [Color, L]).
intencion(T, R) :-
    palabra_cuerpo(T, Cuerpo), !,
    findall(C, cuerpo(C, Cuerpo), Cs),
    lista_texto(Cs, L),
    format(atom(R), 'Las cepas de cuerpo ~w son: ~w.', [Cuerpo, L]).
intencion(T, R) :-
    alguna(T, [temperatura, grados, servir, sirve]), !,
    temperatura_servicio(tinto, Ti, Tx), temperatura_servicio(blanco, Bi, Bx),
    format(atom(R), 'Los tintos se sirven entre ~w y ~w °C y los blancos entre ~w y ~w °C.', [Ti, Tx, Bi, Bx]).
intencion(T, R) :-
    alguna(T, [cepas, cepa, uvas, variedades]), !,
    findall(C, cepa(C, _), Cs),
    lista_texto(Cs, L),
    format(atom(R), 'Conozco estas cepas: ~w.', [L]).
intencion(T, R) :-
    alguna(T, [valles, valle]), !,
    findall(V, valle(V, _, _, _), Vs),
    lista_texto(Vs, L),
    format(atom(R), 'Conozco estos valles vitivinícolas: ~w.', [L]).

% --- Respuesta por defecto ---
intencion(_, 'Lo siento, no tengo información sobre eso en mi base de conocimiento. Prueba preguntando por una cepa, un valle o un plato.').

% Sub-intenciones cuando se menciona una sola cepa.
intencion_cepa(T, C, R) :-
    alguna(T, [origen, proviene, viene, procede, originaria, nacion]), !,
    origen(C, P), mostrar(C, N), mostrar(P, NP),
    format(atom(R), '~w proviene de ~w.', [N, NP]).
intencion_cepa(T, C, R) :-
    alguna(T, [donde, valle, valles, cultiva, cultivan, produce, producen,
               region, regiones, zona, zonas, encuentra, da, dan]), !,
    findall(V, cultiva(V, C), Vs), mostrar(C, N), lista_texto(Vs, L),
    format(atom(R), '~w se cultiva en los valles de: ~w.', [N, L]).
intencion_cepa(T, C, R) :-
    alguna(T, [aroma, aromas, nota, notas, sabor, sabores, sabe, huele, aromatica, aromaticas]), !,
    findall(X, nota(C, X), Xs), mostrar(C, N), lista_texto(Xs, L),
    format(atom(R), 'Las notas aromáticas de ~w son: ~w.', [N, L]).
intencion_cepa(T, C, R) :-
    alguna(T, [cuerpo]), !,
    cuerpo(C, K), mostrar(C, N),
    format(atom(R), '~w es un vino de cuerpo ~w.', [N, K]).
intencion_cepa(T, C, R) :-
    alguna(T, [temperatura, servir, sirve, grados]), !,
    temperatura(C, Min, Max), mostrar(C, N),
    format(atom(R), '~w se sirve entre ~w y ~w °C.', [N, Min, Max]).
intencion_cepa(T, C, R) :-
    alguna(T, [comer, comida, maridaje, marida, maridar, acompanar, acompana, combina, plato, platos]), !,
    findall(P, marida(C, P), Ps), mostrar(C, N), lista_texto(Ps, L),
    format(atom(R), '~w marida bien con: ~w.', [N, L]).
intencion_cepa(T, C, R) :-
    alguna(T, [color, tinto, tinta, blanco, blanca]), !,
    cepa(C, Color), mostrar(C, N),
    format(atom(R), '~w es una cepa de vino ~w.', [N, Color]).
intencion_cepa(_, C, R) :-
    ficha_cepa(C, R).

% Sub-intenciones cuando se menciona un solo valle.
intencion_valle(T, V, R) :-
    alguna(T, [clima]), !,
    clima(V, K), mostrar(V, N), mostrar(K, NK),
    format(atom(R), 'El valle de ~w tiene un clima ~w.', [N, NK]).
intencion_valle(T, V, R) :-
    alguna(T, [region]), !,
    region(V, Reg), mostrar(V, N), texto_region(Reg, TR),
    format(atom(R), 'El valle de ~w está en ~w.', [N, TR]).
intencion_valle(T, V, R) :-
    alguna(T, [zona]), !,
    zona(V, Z), mostrar(V, N),
    format(atom(R), 'El valle de ~w pertenece a la zona ~w.', [N, Z]).
intencion_valle(T, V, R) :-
    alguna(T, [cepa, cepas, uvas, cultiva, cultivan, produce, producen]), !,
    findall(C, cultiva(V, C), Cs), mostrar(V, N), lista_texto(Cs, L),
    format(atom(R), 'En el valle de ~w se cultivan: ~w.', [N, L]).
intencion_valle(_, V, R) :-
    ficha_valle(V, R).

% ---------------------------------------------------------------------
% 5. CONSTRUCCIÓN DE RESPUESTAS
% ---------------------------------------------------------------------

ficha_cepa(C, R) :-
    cepa(C, Color), origen(C, P), cuerpo(C, K),
    findall(X, nota(C, X), Notas),
    findall(V, cultiva(V, C), Valles),
    findall(Pl, marida(C, Pl), Platos),
    temperatura(C, Min, Max),
    color_femenino(Color, ColorF),
    maplist(mostrar, [C, P], [N, NP]),
    maplist(lista_texto, [Notas, Valles, Platos], [LN, LV, LP]),
    extra_cepa(C, Extra),
    format(atom(R),
        '~w: cepa ~w de origen ~w, cuerpo ~w. Notas: ~w. Valles: ~w. Marida con: ~w. Se sirve entre ~w y ~w °C.~w',
        [N, ColorF, NP, K, LN, LV, LP, Min, Max, Extra]).

extra_cepa(C, ' Es la cepa emblemática de Chile.') :- cepa_emblematica(C), !.
extra_cepa(C, ' Es la cepa más plantada de Chile.') :- cepa_mas_plantada(C), !.
extra_cepa(C, ' Es una cepa patrimonial de Chile.') :- cepa_patrimonial(C), !.
extra_cepa(_, '').

ficha_valle(V, R) :-
    valle(V, Z, Reg, K),
    findall(C, cultiva(V, C), Cs),
    maplist(mostrar, [V, K], [N, NK]),
    texto_region(Reg, NR),
    lista_texto(Cs, L),
    format(atom(R),
        'Valle de ~w: zona ~w, ubicado en ~w, clima ~w. Cepas principales: ~w.',
        [N, Z, NR, NK, L]).

resp_maridaje_plato(P, R) :-
    findall(C, recomendar(P, C), Cs),
    mostrar(P, NP), lista_texto(Cs, L),
    format(atom(R), 'Para acompañar ~w te recomiendo: ~w.', [NP, L]).

resp_cepa_con_plato(C, P, R) :-
    mostrar(C, N), mostrar(P, NP),
    (   marida(C, P)
    ->  format(atom(R), 'Sí, ~w marida bien con ~w.', [N, NP])
    ;   findall(X, recomendar(P, X), Xs), lista_texto(Xs, L),
        format(atom(R), 'No tengo registrado que ~w marida con ~w. Para ese plato recomiendo: ~w.', [N, NP, L])
    ).

resp_cultiva(V, C, R) :-
    mostrar(C, N), mostrar(V, NV),
    (   cultiva(V, C)
    ->  format(atom(R), 'Sí, ~w se cultiva en el valle de ~w.', [N, NV])
    ;   findall(X, cultiva(X, C), Xs), lista_texto(Xs, L),
        format(atom(R), 'No, ~w no aparece cultivada en ~w. Se cultiva en: ~w.', [N, NV, L])
    ).

resp_valles_comunes(V1, V2, R) :-
    findall(C, cepa_comun(V1, V2, C), Cs),
    maplist(mostrar, [V1, V2], [N1, N2]),
    (   Cs == []
    ->  format(atom(R), '~w y ~w no tienen cepas en común en mi base.', [N1, N2])
    ;   lista_texto(Cs, L),
        format(atom(R), 'Las cepas que comparten ~w y ~w son: ~w.', [N1, N2, L])
    ).

resp_comparar_cepas(C1, C2, R) :-
    resumen_cepa(C1, R1), resumen_cepa(C2, R2),
    format(atom(R), 'Comparación: ~w ~w', [R1, R2]).

resumen_cepa(C, R) :-
    cepa(C, Color), cuerpo(C, K), origen(C, P),
    findall(X, nota(C, X), Ns),
    maplist(mostrar, [C, P], [N, NP]), lista_texto(Ns, L),
    format(atom(R), '~w es ~w, de cuerpo ~w, origen ~w y notas de ~w.', [N, Color, K, NP, L]).

resp_cepas_de_pais(P, R) :-
    findall(C, origen(C, P), Cs),
    mostrar(P, NP), lista_texto(Cs, L),
    format(atom(R), 'Las cepas originarias de ~w son: ~w.', [NP, L]).

resp_clima_frio(T, R) :-
    alguna(T, [cepa, cepas, uva, uvas, vino, vinos]), !,
    setof(C, cepa_clima_frio(C), Cs), lista_texto(Cs, L),
    format(atom(R), 'Las cepas que se cultivan en valles de clima frío o fresco son: ~w.', [L]).
resp_clima_frio(_, R) :-
    findall(V, valle_frio(V), Vs), lista_texto(Vs, L),
    format(atom(R), 'Los valles de clima frío o fresco son: ~w.', [L]).

resp_lista_filtrada([], Color, Cuerpo, R) :- !,
    format(atom(R), 'No tengo cepas de vino ~w con cuerpo ~w.', [Color, Cuerpo]).
resp_lista_filtrada(Cs, Color, Cuerpo, R) :-
    lista_texto(Cs, L),
    format(atom(R), 'Cepas de vino ~w con cuerpo ~w: ~w.', [Color, Cuerpo, L]).

% Palabras que indican color, cuerpo o zona.
palabra_color(T, tinto)  :- alguna(T, [tinto, tinta, tintos, tintas]), !.
palabra_color(T, blanco) :- alguna(T, [blanco, blanca, blancos, blancas]).

palabra_cuerpo(T, ligero)  :- alguna(T, [ligero, ligera, ligeros, ligeras, liviano, liviana, suave]), !.
palabra_cuerpo(T, intenso) :- alguna(T, [intenso, intensa, intensos, intensas, robusto, potente]), !.
palabra_cuerpo(T, medio)   :- alguna(T, [medio, media]).

palabra_zona(T, norte)   :- alguna(T, [norte]), !.
palabra_zona(T, sur)     :- alguna(T, [sur]), !.
palabra_zona(T, central) :- alguna(T, [central, centro]).

% ---------------------------------------------------------------------
% 6. UTILIDADES DE FORMATO
% ---------------------------------------------------------------------

% mostrar(+Atomo, -Texto): nombre legible de un átomo.
mostrar(A, Texto) :- nombre(A, Texto), !.
mostrar(A, Texto) :-
    atomic_list_concat(Partes, '_', A),
    atomic_list_concat(Partes, ' ', T0),
    (   nombre_propio(A) -> capitalizar(T0, Texto) ; Texto = T0 ).

nombre_propio(A) :- cepa(A, _), !.
nombre_propio(A) :- valle(A, _, _, _), !.
nombre_propio(A) :- valle(_, _, A, _), !.
nombre_propio(A) :- origen(_, A).

texto_region(metropolitana, 'la Región Metropolitana') :- !.
texto_region(Reg, Texto) :-
    mostrar(Reg, N), format(atom(Texto), 'la región de ~w', [N]).

color_femenino(tinto, tinta).
color_femenino(blanco, blanca).

capitalizar(A, Cap) :-
    sub_atom(A, 0, 1, _, Primera), sub_atom(A, 1, _, 0, Resto),
    upcase_atom(Primera, May), atom_concat(May, Resto, Cap).

% lista_texto(+Atomos, -Texto): [a,b,c] -> 'A, B y C'.
lista_texto([], 'ninguna').
lista_texto(Lista, Texto) :-
    Lista \== [],
    maplist(mostrar, Lista, Nombres),
    unir(Nombres, Texto).

unir([X], X) :- !.
unir([X, Y], T) :- !, format(atom(T), '~w y ~w', [X, Y]).
unir([X | Xs], T) :- unir(Xs, T0), format(atom(T), '~w, ~w', [X, T0]).
