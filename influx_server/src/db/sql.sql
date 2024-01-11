-- Select phrases by start token
CREATE phrase SET orthography_seq = ['s1', 's2', 's3'];
CREATE phrase SET orthography_seq = ['s1', 's2'];
CREATE phrase SET orthography_seq = ['s5', 's6'];
CREATE phrase SET orthography_seq = ['s7', 's8', 's9'];

SELECT * FROM phrase;

SELECT * FROM phrase WHERE array::first(orthography_seq) INSIDE ['s1', 's7'];



-- Object ID
CREATE lang:fr_demo SET code = 'fr';
CREATE lang:en_demo SET code = 'en';

CREATE vocab:{lang: lang:en_demo, orthography: 'en_tkn1'} SET definition='en_tkn1_def';
CREATE vocab:{lang: lang:en_demo, orthography: 'en_tkn2'} SET definition='en_tkn2_def';
CREATE vocab:{lang: lang:en_demo, orthography: 'en_tkn3'} SET definition='en_tkn3_def';

let $tknid = {lang: lang:fr_demo, orthography: 'fr_tkn1'};
CREATE vocab content {definition: 'fr_tkn1_def', id: $tknid};

SELECT * from vocab;

update vocab:{lang: lang:en_demo, orthography: 'en_tkn1'} set definition='en_tkn1_def mod';
