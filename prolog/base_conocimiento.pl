:- encoding(utf8).
% =====================================================================
%  BASE DE CONOCIMIENTO: Vinos y cepas de Chile
%  Proyecto N°2 - Fundamentos de Inteligencia Artificial
%
%  Este archivo es la ÚNICA fuente de conocimiento del sistema.
%  Lo usan ambos chatbots:
%    - El chatbot Prolog lo consulta con inferencia lógica.
%    - El chatbot LLM lo recibe como contexto en su prompt.
%  Para agregar o cambiar conocimiento basta con editar este archivo.
%
%  Convención: los átomos van en minúscula, sin tildes y con "_"
%  entre palabras (ej: sauvignon_blanc). El nombre "bonito" para
%  mostrar al usuario se define con nombre/2 (es opcional).
% =====================================================================

% Permite agregar hechos en cualquier parte del archivo (ej. al final).
:- discontiguous cepa/2, origen/2, cuerpo/2, nota/2, valle/4, cultiva/2,
                 marida/2, nombre/2, cepa_patrimonial/1, clima_frio/1.

% ---------------------------------------------------------------------
% 1. CEPAS
% cepa(Cepa, Color).            Color: tinto | blanco
% ---------------------------------------------------------------------
cepa(cabernet_sauvignon, tinto).
cepa(carmenere, tinto).
cepa(merlot, tinto).
cepa(syrah, tinto).
cepa(pinot_noir, tinto).
cepa(pais, tinto).
cepa(carignan, tinto).
cepa(cinsault, tinto).
cepa(malbec, tinto).
cepa(sauvignon_blanc, blanco).
cepa(chardonnay, blanco).
cepa(riesling, blanco).
cepa(moscatel_de_alejandria, blanco).
cepa(gewurztraminer, blanco).

% origen(Cepa, PaisDeOrigen).
origen(cabernet_sauvignon, francia).
origen(carmenere, francia).
origen(merlot, francia).
origen(syrah, francia).
origen(pinot_noir, francia).
origen(pais, espana).
origen(carignan, espana).
origen(cinsault, francia).
origen(malbec, francia).
origen(sauvignon_blanc, francia).
origen(chardonnay, francia).
origen(riesling, alemania).
origen(moscatel_de_alejandria, egipto).
origen(gewurztraminer, italia).

% cuerpo(Cepa, Cuerpo).         Cuerpo: ligero | medio | intenso
cuerpo(cabernet_sauvignon, intenso).
cuerpo(carmenere, medio).
cuerpo(merlot, medio).
cuerpo(syrah, intenso).
cuerpo(pinot_noir, ligero).
cuerpo(pais, ligero).
cuerpo(carignan, intenso).
cuerpo(cinsault, ligero).
cuerpo(malbec, intenso).
cuerpo(sauvignon_blanc, ligero).
cuerpo(chardonnay, medio).
cuerpo(riesling, ligero).
cuerpo(moscatel_de_alejandria, ligero).
cuerpo(gewurztraminer, medio).

% nota(Cepa, NotaAromatica).
nota(cabernet_sauvignon, cassis).
nota(cabernet_sauvignon, menta).
nota(cabernet_sauvignon, cedro).
nota(carmenere, pimenton_rojo).
nota(carmenere, especias).
nota(carmenere, frutos_rojos_maduros).
nota(merlot, ciruela).
nota(merlot, cereza).
nota(merlot, chocolate).
nota(syrah, mora).
nota(syrah, pimienta_negra).
nota(syrah, violeta).
nota(pinot_noir, frutilla).
nota(pinot_noir, cereza).
nota(pinot_noir, tierra_humeda).
nota(pais, frutos_rojos_frescos).
nota(pais, notas_terrosas).
nota(carignan, guinda).
nota(carignan, frutos_negros).
nota(carignan, especias).
nota(cinsault, frambuesa).
nota(cinsault, flores).
nota(malbec, ciruela).
nota(malbec, violeta).
nota(malbec, mora).
nota(sauvignon_blanc, citricos).
nota(sauvignon_blanc, pasto_recien_cortado).
nota(sauvignon_blanc, maracuya).
nota(chardonnay, manzana).
nota(chardonnay, pina).
nota(chardonnay, vainilla).
nota(riesling, lima).
nota(riesling, durazno).
nota(riesling, notas_minerales).
nota(moscatel_de_alejandria, flores_blancas).
nota(moscatel_de_alejandria, uva_fresca).
nota(moscatel_de_alejandria, durazno).
nota(gewurztraminer, lichi).
nota(gewurztraminer, petalos_de_rosa).
nota(gewurztraminer, especias).

% Hechos destacados
cepa_emblematica(carmenere).
cepa_mas_plantada(cabernet_sauvignon).
cepa_patrimonial(pais).
cepa_patrimonial(cinsault).
cepa_patrimonial(moscatel_de_alejandria).

% ---------------------------------------------------------------------
% 2. VALLES
% valle(Valle, Zona, RegionAdministrativa, Clima).
%   Zona:  norte | aconcagua | central | sur
%   Clima: semiarido | costero_fresco | mediterraneo | mediterraneo_calido |
%          mediterraneo_humedo | frio_lluvioso
% ---------------------------------------------------------------------
valle(elqui, norte, coquimbo, semiarido).
valle(limari, norte, coquimbo, semiarido).
valle(aconcagua, aconcagua, valparaiso, mediterraneo_calido).
valle(casablanca, aconcagua, valparaiso, costero_fresco).
valle(leyda, aconcagua, valparaiso, costero_fresco).
valle(maipo, central, metropolitana, mediterraneo).
valle(cachapoal, central, ohiggins, mediterraneo).
valle(colchagua, central, ohiggins, mediterraneo_calido).
valle(curico, central, maule, mediterraneo).
valle(maule, central, maule, mediterraneo).
valle(itata, sur, nuble, mediterraneo_humedo).
valle(biobio, sur, biobio, mediterraneo_humedo).
valle(malleco, sur, araucania, frio_lluvioso).

% Climas considerados fríos o frescos (favorables a cepas de clima frío)
clima_frio(costero_fresco).
clima_frio(frio_lluvioso).
clima_frio(mediterraneo_humedo).

% cultiva(Valle, Cepa).
cultiva(elqui, syrah).
cultiva(elqui, sauvignon_blanc).
cultiva(limari, chardonnay).
cultiva(limari, syrah).
cultiva(limari, sauvignon_blanc).
cultiva(aconcagua, cabernet_sauvignon).
cultiva(aconcagua, syrah).
cultiva(aconcagua, carmenere).
cultiva(casablanca, sauvignon_blanc).
cultiva(casablanca, chardonnay).
cultiva(casablanca, pinot_noir).
cultiva(leyda, sauvignon_blanc).
cultiva(leyda, pinot_noir).
cultiva(maipo, cabernet_sauvignon).
cultiva(maipo, carmenere).
cultiva(maipo, merlot).
cultiva(cachapoal, carmenere).
cultiva(cachapoal, cabernet_sauvignon).
cultiva(cachapoal, syrah).
cultiva(colchagua, carmenere).
cultiva(colchagua, cabernet_sauvignon).
cultiva(colchagua, syrah).
cultiva(colchagua, malbec).
cultiva(curico, sauvignon_blanc).
cultiva(curico, cabernet_sauvignon).
cultiva(curico, merlot).
cultiva(maule, carignan).
cultiva(maule, pais).
cultiva(maule, cabernet_sauvignon).
cultiva(itata, cinsault).
cultiva(itata, pais).
cultiva(itata, moscatel_de_alejandria).
cultiva(biobio, pinot_noir).
cultiva(biobio, riesling).
cultiva(biobio, gewurztraminer).
cultiva(biobio, pais).
cultiva(malleco, chardonnay).
cultiva(malleco, pinot_noir).

% ---------------------------------------------------------------------
% 3. MARIDAJE Y SERVICIO
% marida(Cepa, Plato).
% ---------------------------------------------------------------------
marida(cabernet_sauvignon, carne_roja).
marida(cabernet_sauvignon, quesos_maduros).
marida(carmenere, pastel_de_choclo).
marida(carmenere, carnes_con_especias).
marida(merlot, pastas).
marida(merlot, cerdo).
marida(syrah, cordero).
marida(syrah, carne_de_caza).
marida(pinot_noir, salmon).
marida(pinot_noir, champinones).
marida(pais, empanadas).
marida(pais, embutidos).
marida(carignan, estofados).
marida(carignan, cazuela).
marida(cinsault, embutidos).
marida(cinsault, pizza).
marida(malbec, asado).
marida(sauvignon_blanc, ceviche).
marida(sauvignon_blanc, mariscos).
marida(chardonnay, pescado).
marida(chardonnay, pollo).
marida(chardonnay, machas_a_la_parmesana).
marida(riesling, sushi).
marida(riesling, comida_asiatica).
marida(moscatel_de_alejandria, postres).
marida(gewurztraminer, comida_asiatica).
marida(gewurztraminer, quesos_intensos).

% temperatura_servicio(Color, MinimoC, MaximoC).
temperatura_servicio(tinto, 16, 18).
temperatura_servicio(blanco, 8, 12).

% ---------------------------------------------------------------------
% 4. NOMBRES PARA MOSTRAR (opcional; si falta se usa el átomo)
% ---------------------------------------------------------------------
nombre(cabernet_sauvignon, 'Cabernet Sauvignon').
nombre(carmenere, 'Carménère').
nombre(merlot, 'Merlot').
nombre(syrah, 'Syrah').
nombre(pinot_noir, 'Pinot Noir').
nombre(pais, 'País').
nombre(carignan, 'Carignan').
nombre(cinsault, 'Cinsault').
nombre(malbec, 'Malbec').
nombre(sauvignon_blanc, 'Sauvignon Blanc').
nombre(chardonnay, 'Chardonnay').
nombre(riesling, 'Riesling').
nombre(moscatel_de_alejandria, 'Moscatel de Alejandría').
nombre(gewurztraminer, 'Gewürztraminer').
nombre(limari, 'Limarí').
nombre(curico, 'Curicó').
nombre(biobio, 'Biobío').
nombre(ohiggins, 'O''Higgins').
nombre(nuble, 'Ñuble').
nombre(araucania, 'La Araucanía').
nombre(valparaiso, 'Valparaíso').
nombre(espana, 'España').
nombre(semiarido, 'semiárido').
nombre(mediterraneo, 'mediterráneo').
nombre(mediterraneo_calido, 'mediterráneo cálido').
nombre(mediterraneo_humedo, 'mediterráneo húmedo').
nombre(frio_lluvioso, 'frío y lluvioso').
nombre(citricos, 'cítricos').
nombre(pimenton_rojo, 'pimentón rojo').
nombre(pasto_recien_cortado, 'pasto recién cortado').
nombre(maracuya, 'maracuyá').
nombre(pina, 'piña').
nombre(tierra_humeda, 'tierra húmeda').
nombre(lichi, 'lichi').
nombre(petalos_de_rosa, 'pétalos de rosa').
nombre(salmon, 'salmón').
nombre(champinones, 'champiñones').
nombre(comida_asiatica, 'comida asiática').

% ---------------------------------------------------------------------
% 5. REGLAS (conocimiento inferido)
% ---------------------------------------------------------------------

% Una cepa es tinta/blanca según su color.
es_tinta(C)  :- cepa(C, tinto).
es_blanca(C) :- cepa(C, blanco).

% Datos derivados de un valle.
zona(V, Z)   :- valle(V, Z, _, _).
region(V, R) :- valle(V, _, R, _).
clima(V, K)  :- valle(V, _, _, K).

% Un valle es frío si su clima pertenece a los climas fríos.
valle_frio(V) :- clima(V, K), clima_frio(K).

% Una cepa es de clima frío si se cultiva en algún valle frío.
cepa_clima_frio(C) :- cultiva(V, C), valle_frio(V).

% Una cepa se produce en una región si algún valle de esa región la cultiva.
cepa_en_region(C, R) :- cultiva(V, C), region(V, R).

% Cepas que dos valles distintos tienen en común.
cepa_comun(V1, V2, C) :- cultiva(V1, C), cultiva(V2, C), V1 \= V2.

% Recomendación de vino para un plato.
recomendar(Plato, C) :- marida(C, Plato).

% Temperatura de servicio de una cepa (heredada de su color).
temperatura(C, Min, Max) :- cepa(C, Color), temperatura_servicio(Color, Min, Max).

% Cepa traída a Chile en la época colonial (origen español).
cepa_colonial(C) :- origen(C, espana).
