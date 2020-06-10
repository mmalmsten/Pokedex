:- use_module(library(http/http_client)).
:- use_module(library(http/json)).

:- include('pokemonlist.pl').

start(hello).

% ------------------------------------------------------------------------------
% Find [Pokemon]'s sibling (same Color, Habitat and Move)
% ------------------------------------------------------------------------------
find_sibling(Pokemon, Buddy, {Color, Habitat, Move}) :-
    pokemon(Pokemon, Color, Habitat, Move),
    pokemon(Buddy, Color, Habitat, Move),
    Buddy \= Pokemon.

% ------------------------------------------------------------------------------
% Find two buddies of [Pokemon] that doesn't have the same traits
% ------------------------------------------------------------------------------
find_buddies(Pokemon, {Buddy1, Color1, Habitat1, Move1}, 
    {Buddy2, Color2, Habitat2, Move2}) :-
        pokemon(Pokemon, Color, Habitat, Move),
        pokemon(Buddy1, Color1, Habitat1, Move1),
        Pokemon \= Buddy1, Color \= Color1, Habitat \= Habitat1, Move \= Move1,
        pokemon(Buddy2, Color2, Habitat2, Move2),
        Pokemon \= Buddy2, Color \= Color2, Habitat \= Habitat2, Move \= Move2,
        Buddy1 \= Buddy2, Color1 \= Color2, Habitat1 \= Habitat2, Move1 \= Move2.

% ------------------------------------------------------------------------------
% Find all siblings of [Pokemon]
% ------------------------------------------------------------------------------
find_all_siblings(Pokemon, Bag) :-
    pokemon(Pokemon, Color, Habitat, Move),
    findall(Buddy, pokemon(Buddy, Color, Habitat, Move), Bag).

% ------------------------------------------------------------------------------
% Find all siblings of all pokemons and sort on number of siblings
% ------------------------------------------------------------------------------
find_all_siblings(Sorted) :-
    findall(
        {Len, Pokemon, List}, 
        (find_all_siblings(Pokemon, List), length(List, Len)), 
        Bag
    ),
    sort(0, @>=, Bag, Sorted).

% ------------------------------------------------------------------------------
% Gotta catch 'em all with 200 concurrent requests...
% ------------------------------------------------------------------------------
load_data :-
    http_get('https://pokeapi.co/api/v2/pokemon?offset=0&limit=200', Data, []),
    atom_json_dict(Data, JSONDict, []),
    concurrent_maplist(l_d, JSONDict.results),
    tell('pokemonlist.pl'), listing(pokemon), told.

load_data.

l_d(H) :-
    atom_string(Url, H.url),
    http_get(Url, Data, []),
    atom_json_dict(Data, JSONDict, []),
    [Move|_] = JSONDict.moves,
    http_get(JSONDict.species.url, Species, []),
    atom_json_dict(Species, Species1, []),
    asserta(pokemon(JSONDict.name, Species1.color.name, Species1.habitat.name, 
        Move.move.name)),
    format('~n~p',[JSONDict.name]).